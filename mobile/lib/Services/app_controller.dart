import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Models/auth_user.dart';
import '../Models/api_exceptions.dart';
import '../Widgets/banner_widget.dart';
import '../main.dart';

class AppController extends ChangeNotifier {
  AppController(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  final http.Client httpClient = http.Client();
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
      final response = await httpClient
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

        notifyToast(
          titleMsg,
          success: true,
          subtitle: 'Versión BD: $dbVersionText',
        );
      } else {
        notifyToast(
          'No fue posible establecer conexión con el backend.',
          success: false,
        );
      }
    } on TimeoutException {
      notifyToast(
        'No fue posible establecer conexión con el backend.',
        success: false,
      );
    } catch (_) {
      notifyToast(
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

    final response = await httpClient.get(uri, headers: headers);
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode == 403) {
      notifyToast(
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
    notifyToast('Tu sesión expiró, inicia sesión nuevamente.', success: false);
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

  void notifyToast(String message, {required bool success, String? subtitle}) {
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
    httpClient.close();
    super.dispose();
  }
}

