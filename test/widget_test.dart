// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:volunred_app/app_module.dart';
import 'package:volunred_app/app_widget.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );

    // Verify that our counter starts at 0 (HomePage shows 'Counter: 0').
    expect(find.textContaining('Counter:'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented (now shows 'Counter: 1').
    expect(find.textContaining('Counter: 1'), findsOneWidget);
  });
}
