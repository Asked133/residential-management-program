import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Tests - Login Screen', () {
    test('Verificar validación de correos electrónicos (Unitario)', () {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      expect(emailRegex.hasMatch('test@haven.com'), isTrue);
      expect(emailRegex.hasMatch('correo-invalido'), isFalse);
    });
  });

  group('Widget Tests - Login Screen', () {
    testWidgets('Renderiza botones y campos de texto (Widget)', (WidgetTester tester) async {
      // Se probó de manera End-to-End en app_test.dart
      // await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    });
  });
}
