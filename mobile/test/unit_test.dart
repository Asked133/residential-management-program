import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haven/Services/app_controller.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    // Mockear streams y session inicial para que AppController no falle en bootstrap
    when(() => mockAuth.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.currentSession).thenReturn(null);
  });

  group('AppController - Pruebas Unitarias', () {
    test('Estado inicial es correcto', () {
      final controller = AppController(mockSupabaseClient);

      expect(controller.isLoading, true);
      expect(controller.isInitializing, true);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(controller.isProfileIncomplete, false);
    });

    test('bootstrap finaliza correctamente sin sesión', () async {
      final controller = AppController(mockSupabaseClient);

      await controller.bootstrap();

      expect(controller.isLoading, false);
      expect(controller.isInitializing, false);
      expect(controller.isAuthenticated, false);
    });
  });
}
