import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('No se encontraron las credenciales de Supabase en el archivo .env');
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  
  runApp(const havenApp());
}

class havenApp extends StatefulWidget {
  const havenApp({super.key});

  @override
  State<havenApp> createState() => _havenAppState();
}

class _havenAppState extends State<havenApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController(Supabase.instance.client);
    unawaited(controller.bootstrap());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.checkBackendConnection());
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F172A);
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'haven',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF1F3F7),
        fontFamily: 'Roboto',
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const _LoadingScreen();
          }

          if (!controller.isAuthenticated) {
            return LoginScreen(controller: controller);
          }

          return DashboardScreen(controller: controller);
        },
      ),
    );
  }
}

class AppController extends ChangeNotifier {
  AppController(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  final http.Client _httpClient = http.Client();
  StreamSubscription<AuthState>? _authSubscription;

  Session? _session;
  AuthUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _pingShown = false;
  bool get _usesBackend => !kIsWeb;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null && _currentUser != null;
  String? get errorMessage => _errorMessage;
  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _session?.accessToken;

  Future<void> bootstrap() async {
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((event) async {
      _session = event.session;
      if (event.session == null) {
        _currentUser = null;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (event.event == AuthChangeEvent.initialSession || event.event == AuthChangeEvent.tokenRefreshed) {
        await _refreshProfile();
      }
    });

    final existing = _supabaseClient.auth.currentSession;
    _session = existing;

    if (existing != null) {
      if (_usesBackend) {
        await _refreshProfile();
      } else {
        _hydrateFromSession(existing);
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkBackendConnection() async {
    await _pingBackend();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _session = response.session;
      if (_session == null) {
        _errorMessage = 'Correo o contraseña incorrectos.';
        return;
      }

      if (_usesBackend) {
        await _refreshProfile();
      } else {
        _hydrateFromSession(_session!);
      }

      if (!isAuthenticated) {
        _errorMessage = 'Acceso denegado.';
      }
    } on AuthException catch (error) {
      _session = null;
      _currentUser = null;
      _errorMessage = _mapAuthError(error);
    } catch (error) {
      _session = null;
      _currentUser = null;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabaseClient.auth.signOut();
    _session = null;
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshProfile() async {
    final session = _session;
    if (session == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await _getJson('/api/auth/me');
      final mapped = AuthUser.fromJson(profile);
      final role = (mapped.role ?? mapped.rol ?? '').trim().toLowerCase();
      final allowed = role.isEmpty || role == 'admin' || role == 'administrador';

      if (allowed) {
        _currentUser = mapped.copyWith(
          id: mapped.id.isEmpty ? session.user.id : mapped.id,
          email: mapped.email.isEmpty ? session.user.email ?? '' : mapped.email,
          role: 'administrador',
          rol: 'administrador',
        );
        _errorMessage = null;
      } else {
        _currentUser = null;
        _errorMessage = 'Esta cuenta no tiene permisos de administrador.';
        await logout();
        return;
      }
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      rethrow;
    } catch (_) {
      _currentUser = AuthUser(
        id: session.user.id,
        email: session.user.email ?? '',
        role: 'administrador',
        rol: 'administrador',
      );
      _errorMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _hydrateFromSession(Session session) {
    _currentUser = AuthUser(
      id: session.user.id,
      email: session.user.email ?? '',
      role: 'administrador',
      rol: 'administrador',
    );
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _pingBackend() async {
    if (_pingShown) {
      return;
    }
    _pingShown = true;

    try {
      final response = await _httpClient
          .get(Uri.parse('${dotenv.env['API_BASE_URL'] ?? ''}/api/auth/ping'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyToast('Backend conectado correctamente.', success: true);
        });
      } else {
        _notifyToast('No fue posible establecer conexión con el backend.', success: false);
      }
    } on TimeoutException {
      _notifyToast('No fue posible establecer conexión con el backend.', success: false);
    } catch (_) {
      _notifyToast('No fue posible establecer conexión con el backend.', success: false);
    }
  }

  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final uri = Uri.parse('${dotenv.env['API_BASE_URL'] ?? ''}$endpoint');
    final headers = <String, String>{};
    final token = accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _httpClient.get(uri, headers: headers);
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode == 403) {
      _notifyToast('No tienes permisos para realizar esta acción.', success: false);
      throw const ForbiddenException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Unexpected status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Future<void> _handleUnauthorized() async {
    _notifyToast('Tu sesión expiró, inicia sesión nuevamente.', success: false);
    await logout();
  }

  String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('correo') ||
        message.contains('contraseña')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('email') || message.contains('password')) {
      return 'Revisa el correo y la contraseña.';
    }
    if (message.contains('not confirmed') || message.contains('email not confirmed')) {
      return 'Debes confirmar el correo antes de entrar.';
    }
    return error.message;
  }

  void _notifyToast(String message, {required bool success}) {
    final messenger = messengerKey.currentState;
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: success ? const Color(0xFF166534) : const Color(0xFF991B1B),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: success ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _httpClient.close();
    super.dispose();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.controller.login(_emailController.text.trim(), _passwordController.text);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.controller.errorMessage;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Panel de administración — Haven',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (errorMessage != null) ...[
                        _Banner(message: errorMessage),
                        const SizedBox(height: 16),
                      ],
                      const _FieldLabel(text: 'Correo'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('admin@haven.com'),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'El correo es requerido.';
                          }
                          if (!text.contains('@')) {
                            return 'Ingrese un correo válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel(text: 'Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'La contraseña es requerida.';
                          }
                          if (text.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Colors.white),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: TextButton(
                onPressed: controller.logout,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth;
                    final contentWidth = screenWidth < 700 ? maxWidth * 0.95 : maxWidth * 0.72;
                    final clampedWidth = contentWidth.clamp(320.0, 980.0);
                    final titleSize = screenWidth < 360
                        ? 68.0
                        : screenWidth < 420
                            ? 82.0
                            : screenWidth < 700
                                ? 96.0
                                : 112.0;

                    return SizedBox(
                      width: clampedWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'Bienvenido',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              textWidthBasis: TextWidthBasis.longestLine,
                              style: GoogleFonts.comicNeue(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: clampedWidth * 0.78,
                            height: 28,
                            child: const CustomPaint(
                              painter: _UnderlinePainter(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.92,
        size.width * 0.94,
        size.height * 0.42,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Modifica la función para aceptar un parámetro 'suffixIcon'
InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hintText,
    suffixIcon: suffixIcon, 
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF87171)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text(
              'Cargando...',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.role,
    this.rol,
    this.nombre,
    this.apellidos,
  });

  final String id;
  final String email;
  final String? role;
  final String? rol;
  final String? nombre;
  final String? apellidos;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: json['role']?.toString(),
      rol: json['rol']?.toString(),
      nombre: json['nombre']?.toString(),
      apellidos: json['apellidos']?.toString(),
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    String? rol,
    String? nombre,
    String? apellidos,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      rol: rol ?? this.rol,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
    );
  }
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ForbiddenException implements Exception {
  const ForbiddenException();
}

class HttpException implements Exception {
  const HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
