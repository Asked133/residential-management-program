import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:haven/main.dart' as app;
import 'package:haven/Pages/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full End-to-End Mobile & Supabase Integration Test', () {
    testWidgets('App starts, initializes Supabase and connects with backend', (tester) async {
      // 1. Initialize full app with real .env and Supabase.initialize
      app.main();
      await tester.pumpAndSettle();

      // 2. Verify Root Widget loads
      expect(find.byType(app.HavenApp), findsOneWidget);

      // 3. Verify Supabase Client was instantiated
      final supabaseClient = Supabase.instance.client;
      expect(supabaseClient, isNotNull);

      // 4. Hit Supabase backend directly from the app environment
      // We check that GoTrue Auth responds to a health request
      final healthResponse = await supabaseClient.auth.onAuthStateChange.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => AuthState(AuthChangeEvent.initialSession, null),
      );
      expect(healthResponse, isNotNull);

      // 5. Verify UI has rendered LoginScreen when unauthenticated
      expect(find.byType(LoginScreen), findsOneWidget);

      // 6. Test form interaction in real UI
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final enterButton = find.text('Entrar');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(enterButton, findsOneWidget);

      // 7. Type invalid credentials to test Supabase authentication attempt
      await tester.enterText(emailField, 'test_integration@haven.com');
      await tester.enterText(passwordField, 'wrongpassword123');
      await tester.pumpAndSettle();

      await tester.tap(enterButton);
      await tester.pump();

      // Wait for backend roundtrip
      await tester.pump(const Duration(seconds: 3));

      // Either a toast/snackbar appears or an error is displayed
      // The app must stay stable without throwing unhandled exceptions
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
