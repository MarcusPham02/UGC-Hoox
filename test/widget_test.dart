import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders welcome text and get started button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Welcome to Hooks'), findsOneWidget);
    expect(find.text('Your app is connected and ready to go.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
