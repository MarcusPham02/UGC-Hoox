import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/services/script_analyzer_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockFunctionsClient mockFunctions;
  late ScriptAnalyzerService service;

  setUp(() {
    mockFunctions = MockFunctionsClient();
    service = ScriptAnalyzerService(functions: mockFunctions);

    // Default stub for any invoke call
    when(() => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        )).thenAnswer((_) async => FunctionResponse(
          status: 200,
          data: jsonEncode({'analysis': 'test analysis'}),
        ));
  });

  group('analyzeScript', () {
    test('sends scriptText in body', () async {
      final result = await service.analyzeScript(scriptText: 'my pitch script');

      expect(result, 'test analysis');

      final captured = verify(() => mockFunctions.invoke(
            'analyze-script',
            body: captureAny(named: 'body'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['scriptText'], 'my pitch script');
    });

    test('throws on error response', () async {
      when(() => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({'error': 'Script text cannot be empty'}),
          ));

      expect(
        () => service.analyzeScript(scriptText: 'test'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns fallback message when analysis is null', () async {
      when(() => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({}),
          ));

      final result = await service.analyzeScript(scriptText: 'test');

      expect(result, 'Unable to generate analysis. Please try again.');
    });

    test('throws ScriptAnalyzerAuthException on 401', () async {
      when(() => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          )).thenThrow(FunctionException(
        status: 401,
        details: null,
        reasonPhrase: 'Unauthorized',
      ));

      expect(
        () => service.analyzeScript(scriptText: 'test'),
        throwsA(isA<ScriptAnalyzerAuthException>()),
      );
    });
  });
}
