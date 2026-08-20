import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'No se encontraron las credenciales de Supabase en el archivo .env',
    );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
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

          final role = controller.currentUser?.rol;
          if (role == 'administrador')
            return AdminDashboardScreen(controller: controller);
          if (role == 'vigilante')
            return VigilanteDashboardScreen(controller: controller);
          return ResidenteDashboardScreen(controller: controller);
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


  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null && _currentUser != null;
  String? get errorMessage => _errorMessage;
  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _session?.accessToken;

  Future<void> bootstrap() async {
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((
      event,
    ) async {
      _session = event.session;
      if (event.session == null) {
        _currentUser = null;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.initialSession ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        await _refreshProfile();
      }
    });

    final existing = _supabaseClient.auth.currentSession;
    _session = existing;

    if (existing != null) {
      await _refreshProfile();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkBackendConnection() async {
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    await _pingBackend();
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
        String titleMsg = 'Backend conectado correctamente.';
        String dbVersionText = 'No disponible';

        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            titleMsg = body['message'] ?? titleMsg;
            dbVersionText = body['dbVersion'] ?? 'No disponible';
          }
        } catch (_) {}

        _notifyToast(
          titleMsg,
          success: true,
          subtitle: 'Versión BD: $dbVersionText',
        );
      } else {
        _notifyToast(
          'No fue posible establecer conexión con el backend.',
          success: false,
        );
      }
    } on TimeoutException {
      _notifyToast(
        'No fue posible establecer conexión con el backend.',
        success: false,
      );
    } catch (_) {
      _notifyToast(
        'No fue posible establecer conexión con el backend.',
        success: false,
      );
    }
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

      await _refreshProfile();

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

  String normalizeRole(String? role) {
    final raw = (role ?? '').toString().trim().toLowerCase();
    if (raw == 'administrador' ||
        raw == 'admin' ||
        raw == 'administrator' ||
        raw == '1')
      return 'administrador';
    if (raw == 'vigilante' || raw == 'guardia' || raw == 'guard' || raw == '3')
      return 'vigilante';
    if (raw == 'residente' || raw == 'resident' || raw == '2')
      return 'residente';
    return 'residente';
  }

  Future<void>? _refreshProfilePromise;

  Future<void> _refreshProfile() {
    if (_refreshProfilePromise != null) return _refreshProfilePromise!;
    _refreshProfilePromise = _doRefreshProfile();
    return _refreshProfilePromise!.whenComplete(() {
      _refreshProfilePromise = null;
    });
  }

  /// Returns null if [s] is null, empty, or whitespace-only.
  static String? _nb(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _doRefreshProfile() async {
    final session = _session;
    if (session == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final um = session.user.userMetadata ?? {};
    debugPrint('=== DEBUG _doRefreshProfile ===');
    debugPrint('userMetadata keys: ${um.keys.toList()}');
    debugPrint('userMetadata: $um');
    debugPrint('appMetadata: ${session.user.appMetadata}');

    try {
      final profile = await _getJson('/api/auth/me');
      debugPrint('RAW /api/auth/me response: $profile');
      // Unwrap {data: {...}} if the backend wraps it
      final Map<String, dynamic> p =
          (profile['data'] is Map<String, dynamic>)
              ? profile['data'] as Map<String, dynamic>
              : profile;
      debugPrint('Unwrapped profile: $p');

      final mapped = AuthUser.fromJson(p);
      debugPrint('mapped.nombre: "${mapped.nombre}"');
      debugPrint('mapped.apellidos: "${mapped.apellidos}"');
      
      final rawRole =
          (_nb(p['rol']) ??
                  _nb(p['role']) ??
                  _nb(session.user.appMetadata['rol']) ??
                  _nb(session.user.appMetadata['role']) ??
                  'residente');
      final normalized = normalizeRole(rawRole);

      final resolvedNombre = _nb(mapped.nombre) ??
          _nb(um['nombre']) ??
          _nb(um['name']) ??
          _nb(um['full_name']) ??
          session.user.email?.split('@').first;

      final resolvedApellidos = _nb(mapped.apellidos) ??
          _nb(um['apellidos']) ??
          _nb(um['last_name']);

      debugPrint('resolvedNombre: "$resolvedNombre"');
      debugPrint('resolvedApellidos: "$resolvedApellidos"');

      _currentUser = mapped.copyWith(
        id: mapped.id.isEmpty ? session.user.id : mapped.id,
        email: mapped.email.isEmpty ? session.user.email ?? '' : mapped.email,
        role: normalized,
        rol: normalized,
        nombre: resolvedNombre,
        apellidos: resolvedApellidos,
      );
      _errorMessage = null;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('ERROR in _doRefreshProfile: $e');
      _hydrateFromSession(session);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _hydrateFromSession(Session session) {
    final um = session.user.userMetadata ?? {};
    final rawRole =
        (_nb(session.user.appMetadata['rol']) ??
                _nb(session.user.appMetadata['role']) ??
                'residente');
    final normalized = normalizeRole(rawRole);
    _currentUser = AuthUser(
      id: session.user.id,
      email: session.user.email ?? '',
      role: normalized,
      rol: normalized,
      nombre: _nb(um['nombre']) ??
          _nb(um['name']) ??
          _nb(um['full_name']) ??
          session.user.email?.split('@').first,
      apellidos: _nb(um['apellidos']) ??
          _nb(um['last_name']),
    );
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
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
      _notifyToast(
        'No tienes permisos para realizar esta acción.',
        success: false,
      );
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
    if (message.contains('not confirmed') ||
        message.contains('email not confirmed')) {
      return 'Debes confirmar el correo antes de entrar.';
    }
    return error.message;
  }

  void _notifyToast(String message, {required bool success, String? subtitle}) {
    final messenger = messengerKey.currentState;
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        duration: const Duration(
          seconds: 8,
        ), // Aumentado a 8 segundos igual que el web (timer: 8000)
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: success
                    ? const Color(0xFF166534)
                    : const Color(0xFF991B1B),
                fontWeight: subtitle != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: success
                      ? const Color(0xFF166534)
                      : const Color(0xFF991B1B),
                  fontSize:
                      12, // Tamaño más pequeño simulando el 0.85rem del web
                  fontWeight: FontWeight.w500, // Simulando el strong
                ),
              ),
            ],
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: success
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
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
      await widget.controller.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
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
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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

// ==========================================
// SHARED COMPONENTS
// ==========================================

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.avatarColor,
  });

  final AppController controller;
  final String title;
  final String subtitle;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Haven',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.1),
                      border: Border.all(color: avatarColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user?.nombre ?? title} ${user?.apellidos ?? ''}'
                              .trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: controller.logout,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        if (MediaQuery.sizeOf(context).width > 400) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ADMIN SCREENS
// ==========================================

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              controller: controller,
              title: 'Administrador',
              subtitle: 'Administración',
              avatarColor: const Color(0xFF0F172A),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel de Administración',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bienvenido al centro de control del condominio.',
                                style: TextStyle(color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResidentesListScreen(
                                      controller: controller,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 300,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x05000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '👥',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'GESTIÓN',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          'Registrar Residentes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResidentesListScreen extends StatefulWidget {
  const ResidentesListScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ResidentesListScreen> createState() => _ResidentesListScreenState();
}

class _ResidentesListScreenState extends State<ResidentesListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _residentes = [];

  @override
  void initState() {
    super.initState();
    _fetchResidentes();
  }

  Future<void> _fetchResidentes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await widget.controller._httpClient.get(
        Uri.parse('${dotenv.env['API_BASE_URL'] ?? ''}/api/auth/residentes'),
        headers: {'Authorization': 'Bearer ${widget.controller.accessToken}'},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          _residentes = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          _residentes = decoded['data'];
        }
      } else {
        _errorMessage = 'Error de conexión';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Volver al Panel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      const Text(
                                        'Directorio de Residentes',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${_residentes.length} residentes',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Administra las cuentas y datos de contacto de todos los habitantes de la comunidad.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _fetchResidentes,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF475569),
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final bool? added = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ResidentesFormScreen(
                                            controller: widget.controller,
                                          ),
                                        ),
                                      );
                                      if (added == true) _fetchResidentes();
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      color: Color(0xFF34D399),
                                      size: 18,
                                    ),
                                    label: const Text('Agregar residente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isLoading && _residentes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          )
                        else if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Error de conexión',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7F1D1D),
                                        ),
                                      ),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _fetchResidentes,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEE2E2),
                                    foregroundColor: const Color(0xFF7F1D1D),
                                    elevation: 0,
                                  ),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        else if (_residentes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE0E7FF),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.people_outline,
                                    color: Color(0xFF4F46E5),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay residentes registrados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Comienza a construir la comunidad de Haven dando de alta al primer residente.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final bool? added = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResidentesFormScreen(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    );
                                    if (added == true) _fetchResidentes();
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Color(0xFF34D399),
                                    size: 18,
                                  ),
                                  label: const Text('Agregar primer residente'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  const Color(0xFFF8FAFC),
                                ),
                                dividerThickness: 1,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'RESIDENTE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'CONTACTO',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'TELÉFONO',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _residentes.map((r) {
                                  final n = (r['nombre'] ?? '').toString();
                                  final a = (r['apellidos'] ?? '').toString();
                                  final initial =
                                      '${n.isNotEmpty ? n[0] : ''}${a.isNotEmpty ? a[0] : ''}'
                                          .toUpperCase();
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0F172A),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                initial.isEmpty ? 'R' : initial,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$n $a',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const Text(
                                                  'Residente Haven',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.email_outlined,
                                              size: 16,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              r['email'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone_outlined,
                                              size: 16,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              r['telefono'] ?? '—',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResidentesFormScreen extends StatefulWidget {
  const ResidentesFormScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ResidentesFormScreen> createState() => _ResidentesFormScreenState();
}

class _ResidentesFormScreenState extends State<ResidentesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showPassword = false;

  void _generatePassword() {
    _passwordCtrl.text =
        'Hav${DateTime.now().millisecondsSinceEpoch % 10000}!a';
    setState(() => _showPassword = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'nombre': _nombreCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'telefono': _telefonoCtrl.text,
        'email': _emailCtrl.text,
        'password': _passwordCtrl.text,
        'rol': 'residente',
      };

      final response = await widget.controller._httpClient.post(
        Uri.parse('${dotenv.env['API_BASE_URL'] ?? ''}/api/auth/register'),
        headers: {
          'Authorization': 'Bearer ${widget.controller.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        widget.controller._notifyToast(
          'Residente registrado correctamente',
          success: true,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        _errorMessage = 'Error al guardar (Status: ${response.statusCode})';
        try {
          final err = jsonDecode(response.body);
          if (err['message'] != null) _errorMessage = err['message'];
        } catch (_) {}
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Registrar Residente',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_errorMessage != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        border: Border.all(
                                          color: const Color(0xFFFECACA),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  const _FieldLabel(text: 'Nombre'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nombreCtrl,
                                    decoration: _inputDecoration(
                                      'Ej. Juan Carlos',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel(text: 'Apellidos'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _apellidosCtrl,
                                    decoration: _inputDecoration('Ej. Pérez'),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel(text: 'Teléfono'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _telefonoCtrl,
                                    decoration: _inputDecoration(
                                      'Ej. 4421234567',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel(text: 'Correo Electrónico'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: _inputDecoration(
                                      'residente@haven.com',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const _FieldLabel(text: 'Contraseña'),
                                      TextButton.icon(
                                        onPressed: _generatePassword,
                                        icon: const Icon(
                                          Icons.password,
                                          size: 16,
                                        ),
                                        label: const Text('Generar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF4F46E5,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFEEF2FF,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: !_showPassword,
                                    decoration: _inputDecoration(
                                      'Mínimo 8 caracteres',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0F172A,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Text('Guardar Residente'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// RESIDENTE SCREEN
// ==========================================

class ResidenteDashboardScreen extends StatelessWidget {
  const ResidenteDashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              controller: controller,
              title: 'Residente',
              subtitle: 'Portal Residente',
              avatarColor: const Color(0xFF059669),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${controller.currentUser?.nombre ?? 'Residente'}!',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bienvenido a tu portal condominal.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// VIGILANTE SCREEN
// ==========================================

class VigilanteDashboardScreen extends StatelessWidget {
  const VigilanteDashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              controller: controller,
              title: 'Vigilante',
              subtitle: 'Control de Caseta / Vigilancia',
              avatarColor: const Color(0xFFD97706),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Control de Caseta y Accesos',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bienvenido al portal de vigilancia y control de accesos.',
                            style: TextStyle(color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
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
    // Unwrap {data: {...}} if present
    final Map<String, dynamic> j =
        (json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : json;
    String? _nb(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }
    return AuthUser(
      id: (j['id'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      role: _nb(j['role']),
      rol: _nb(j['rol']),
      nombre: _nb(j['nombre']),
      apellidos: _nb(j['apellidos']),
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
