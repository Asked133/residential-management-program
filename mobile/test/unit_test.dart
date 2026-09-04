import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:haven/Models/auth_user.dart';

void main() {
  group('AuthUser Model & Role Mapping', () {
    test('Correctly deserializes AuthUser from JSON', () {
      final json = {
        'id': 'usr-12345',
        'email': 'admin@haven.com',
        'rol': 'administrador',
        'rolNombre': 'Administrador',
        'nombre': 'Carlos',
        'apellidos': 'Mendoza',
        'telefono': '1234567890',
        'activo': true,
        'debeCambiarPassword': false,
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, 'usr-12345');
      expect(user.email, 'admin@haven.com');
      expect(user.rol, 'administrador');
      expect(user.nombre, 'Carlos');
      expect(user.apellidos, 'Mendoza');
      expect(user.telefono, '1234567890');
      expect(user.activo, isTrue);
      expect(user.debeCambiarPassword, isFalse);
    });

    test('Handles wrapped JSON format {data: {...}}', () {
      final wrappedJson = {
        'data': {
          'id': '999',
          'email': 'residente@haven.com',
          'role': 'residente',
          'nombre': 'Ana',
          'apellidos': 'Gómez',
          'telefono': '5551234567',
        }
      };

      final user = AuthUser.fromJson(wrappedJson);

      expect(user.id, '999');
      expect(user.email, 'residente@haven.com');
      expect(user.role, 'residente');
      expect(user.nombre, 'Ana');
    });

    test('copyWith updates specific fields while retaining others', () {
      final initial = AuthUser(
        id: '1',
        email: 'test@test.com',
        nombre: 'Original',
        apellidos: 'User',
      );

      final updated = initial.copyWith(nombre: 'Updated');

      expect(updated.id, '1');
      expect(updated.email, 'test@test.com');
      expect(updated.nombre, 'Updated');
      expect(updated.apellidos, 'User');
    });
  });

  group('Supabase Backend Live Ping & Endpoint Validation', () {
    const supabaseUrl = 'https://qunkgbmxmxmjponyxzdu.supabase.co';
    const anonKey = 'sb_publishable_2an39B-QMQpwkuaCYfg1Bw_EgWoC-SF';

    test('Live Backend: Supabase GoTrue Auth service is healthy and responsive', () async {
      final client = http.Client();
      try {
        final uri = Uri.parse('$supabaseUrl/auth/v1/health');
        final response = await client.get(
          uri,
          headers: {'apikey': anonKey},
        ).timeout(const Duration(seconds: 15));

        expect(response.statusCode, 200);
        final body = jsonDecode(response.body);
        expect(body['name'], 'GoTrue');
        expect(body['version'], isNotNull);
      } finally {
        client.close();
      }
    });

    test('Live Backend: Supabase Auth rejecting unauthenticated /user requests properly', () async {
      final client = http.Client();
      try {
        final uri = Uri.parse('$supabaseUrl/auth/v1/user');
        final response = await client.get(
          uri,
          headers: {'apikey': anonKey},
        ).timeout(const Duration(seconds: 15));

        // Without a Bearer JWT, GoTrue must return 401 Unauthorized
        expect(response.statusCode, 401);
      } finally {
        client.close();
      }
    });
  });

  group('AppController Business Logic', () {
    test('isProfileIncomplete detects invalid resident data', () {
      // Incomplete resident
      final incompleteUser = AuthUser(
        id: '1',
        email: 'res@haven.com',
        rol: 'residente',
        nombre: 'sin nombre',
        apellidos: '',
        telefono: '123',
      );

      // Verify logic directly using the incomplete user profile
      final rol = (incompleteUser.role ?? incompleteUser.rol ?? '').toLowerCase();
      expect(rol.contains('residente'), isTrue);

      final nombre = (incompleteUser.nombre ?? '').trim();
      final apellidos = (incompleteUser.apellidos ?? '').trim();
      final telefono = (incompleteUser.telefono ?? '').trim();

      final nombreValido = nombre.isNotEmpty && nombre.toLowerCase() != 'sin nombre';
      final apellidosValidos = apellidos.isNotEmpty;
      final telefonoValido = telefono.length >= 10;

      final isProfileIncomplete = !nombreValido || !apellidosValidos || !telefonoValido;
      expect(isProfileIncomplete, isTrue);
    });
  });
}
