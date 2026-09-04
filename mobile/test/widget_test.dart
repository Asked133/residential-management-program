import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven/Widgets/loading_screen.dart';

void main() {
  group('Pruebas de Widgets - LoadingScreen', () {
    testWidgets('Debe mostrar el indicador de progreso y el texto de carga', (
      WidgetTester tester,
    ) async {
      // Build the widget inside a MaterialApp wrapper
      await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));

      // Assert: Verify CircularProgressIndicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Assert: Verify text 'Cargando...' is present
      expect(find.text('Cargando...'), findsOneWidget);
    });
  });
}
