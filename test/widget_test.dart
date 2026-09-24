import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(onboardingCompleted: true));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
