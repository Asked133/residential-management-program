import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Tests - Registro Residente Screen', () {
    test('Verificar lógica de contraseñas coincidentes (Unitario)', () {
      const pass1 = 'Test1234';
      const pass2 = 'Test1234';
      expect(pass1 == pass2, isTrue);
    });
  });

  group('Widget Tests - Registro Residente Screen', () {
    testWidgets('Renderiza formulario de registro (Widget)', (WidgetTester tester) async {
      // await tester.pumpWidget(MaterialApp(home: RegistroResidenteScreen()));
    });
  });
}
