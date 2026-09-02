import 'package:flutter/foundation.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.role,
    this.rol,
    this.rolId,
    this.rolNombre,
    this.nombre,
    this.apellidos,
    this.telefono,
    this.activo,
    this.debeCambiarPassword,
  });

  final String id;
  final String email;
  final String? role;
  final String? rol;
  final int? rolId;
  final String? rolNombre;
  final String? nombre;
  final String? apellidos;
  final String? telefono;
  final bool? activo;
  final bool? debeCambiarPassword;

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
      rolId: j['rolId'] as int?,
      rolNombre: _nb(j['rolNombre']),
      nombre: _nb(j['nombre']),
      apellidos: _nb(j['apellidos']),
      telefono: _nb(j['telefono']),
      activo: j['activo'] as bool?,
      debeCambiarPassword: j['debeCambiarPassword'] as bool?,
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    String? rol,
    int? rolId,
    String? rolNombre,
    String? nombre,
    String? apellidos,
    String? telefono,
    bool? activo,
    bool? debeCambiarPassword,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      rol: rol ?? this.rol,
      rolId: rolId ?? this.rolId,
      rolNombre: rolNombre ?? this.rolNombre,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      debeCambiarPassword: debeCambiarPassword ?? this.debeCambiarPassword,
    );
  }
}

