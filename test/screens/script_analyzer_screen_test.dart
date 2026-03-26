import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/script_analyzer_screen.dart';
import 'package:hooks_app/services/script_analyzer_service.dart';
import 'package:mocktail/mocktail.dart';

class MockScriptAnalyzerService extends Mock
    implements ScriptAnalyzerService {}

void main() {
  late MockScriptAnalyzerService mockService;

  setUp(() {
    mockService = MockScriptAnalyzerService();
  });

  Widget buildApp() {
    return MaterialApp(
      home: ScriptAnalyzerScreen(service: mockService),
    );
  }

  group('ScriptAnalyzerScreen', () {
    testWidgets('renders text field and Analyze Script button',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Paste your UGC pitch script'),
        findsOneWidget,
      );
      expect(find.text('Analyze Script'), findsOneWidget);
    });

    testWidgets('shows result and Start Over button after submit',
        (tester) async {
      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenAnswer((_) async => '## Opening Hook\nGreat start!');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Paste your UGC pitch script'),
        'Stop scrolling. This product changed my skin.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analyze Script'));
      await tester.pumpAndSettle();

      expect(find.text('Start Over'), findsOneWidget);
    });

    testWidgets('Start Over resets back to form', (tester) async {
      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenAnswer((_) async => '## Analysis');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Paste your UGC pitch script'),
        'My pitch script',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analyze Script'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Paste your UGC pitch script'),
        findsOneWidget,
      );
    });
  });
}
