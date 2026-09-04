import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:haven/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('App start and basic verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure the app doesn't crash on start
      expect(find.byType(app.HavenApp), findsOneWidget);
    });
  });
}
