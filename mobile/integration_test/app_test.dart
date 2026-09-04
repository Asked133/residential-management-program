import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haven/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('Flujo de Login como Administrador', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Esperar a que la pantalla de carga (SplashScreen) termine (2 segs)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Verificar que estamos en la pantalla de Login
      expect(find.text('Entrar'), findsOneWidget);

      // 2. Cambiar a modo Administrador
      await tester.tap(find.text('Administrador · Vigilancia'));
      await tester.pumpAndSettle();

      // 3. Obtener credenciales del .env
      final email = dotenv.env['ADMIN_USER_EMAIL'] ?? 'admin@haven.com';
      final password = dotenv.env['ADMIN_USER_PASSWORD'] ?? 'AdminPassword1';

      // 4. Llenar los campos de texto
      // Encontrar los TextFormFields (asumiendo que el primero es correo y el segundo password)
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), email);
      await tester.enterText(textFields.at(1), password);
      await tester.pumpAndSettle();

      // 5. Presionar el botón Entrar
      await tester.tap(find.text('Entrar'));
      
      // 6. Esperar la navegación (puede tardar un poco por la red)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 7. Verificar que el login fue exitoso buscando elementos del Admin Dashboard o Perfil
      // Si el inicio es correcto, la pantalla de login debería desaparecer
      expect(find.text('Entrar'), findsNothing);
    });
  });
}
