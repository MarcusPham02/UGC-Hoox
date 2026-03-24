import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/services/feedback_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockFunctionsClient mockFunctions;
  late FeedbackService service;

  setUp(() {
    mockFunctions = MockFunctionsClient();
    service = FeedbackService(functions: mockFunctions);

    // Default stub for any invoke call
    when(() => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        )).thenAnswer((_) async => FunctionResponse(
          status: 200,
          data: jsonEncode({'feedback': 'test feedback'}),
        ));
  });

  group('getFeedback', () {
    test('sends all fields when provided', () async {
      final result = await service.getFeedback(
        userPrompt: 'my hook',
        category: 'social_media',
        audience: 'developers',
        tones: ['casual', 'humorous'],
      );

      expect(result, 'test feedback');

      final captured = verify(() => mockFunctions.invoke(
            'get-feedback',
            body: captureAny(named: 'body'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['userPrompt'], 'my hook');
      expect(captured['category'], 'social_media');
      expect(captured['audience'], 'developers');
      expect(captured['tones'], ['casual', 'humorous']);
    });

    test('omits optional fields when null or empty', () async {
      final result = await service.getFeedback(userPrompt: 'my hook');

      expect(result, 'test feedback');

      final captured = verify(() => mockFunctions.invoke(
            'get-feedback',
            body: captureAny(named: 'body'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['userPrompt'], 'my hook');
      expect(captured.containsKey('category'), false);
      expect(captured.containsKey('audience'), false);
      expect(captured.containsKey('tones'), false);
    });

    test('throws on error response', () async {
      when(() => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({'error': 'Prompt cannot be empty'}),
          ));

      expect(
        () => service.getFeedback(userPrompt: 'my hook'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns fallback message when feedback is null', () async {
      when(() => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({}),
          ));

      final result = await service.getFeedback(userPrompt: 'my hook');

      expect(result, 'Unable to generate feedback. Please try again.');
    });
  });
}
