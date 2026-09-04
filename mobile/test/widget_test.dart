import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dummy widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hello World'))),
    );

    expect(find.text('Hello World'), findsOneWidget);
  });
}
