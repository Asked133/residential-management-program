import 'package:flutter/foundation.dart';

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

