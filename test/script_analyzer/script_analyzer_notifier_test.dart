import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/script_analyzer/script_analyzer_notifier.dart';
import 'package:hooks_app/services/script_analyzer_service.dart';
import 'package:mocktail/mocktail.dart';

class MockScriptAnalyzerService extends Mock
    implements ScriptAnalyzerService {}

void main() {
  late MockScriptAnalyzerService mockService;
  late ScriptAnalyzerNotifier notifier;

  setUp(() {
    mockService = MockScriptAnalyzerService();
    notifier = ScriptAnalyzerNotifier(service: mockService);
  });

  group('analyzeScript', () {
    test('sets analysis on success', () async {
      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenAnswer((_) async => '## Great pitch!');

      await notifier.analyzeScript('my pitch script');

      expect(notifier.analysis, '## Great pitch!');
      expect(notifier.error, isNull);
      expect(notifier.isLoading, false);

      verify(() => mockService.analyzeScript(
            scriptText: 'my pitch script',
          )).called(1);
    });

    test('sets error on failure', () async {
      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenThrow(Exception('network error'));

      await notifier.analyzeScript('my pitch script');

      expect(notifier.analysis, isNull);
      expect(notifier.error, contains('Failed to analyze script'));
      expect(notifier.isLoading, false);
    });

    test('notifies listeners during loading and completion', () async {
      final states = <bool>[];
      notifier.addListener(() => states.add(notifier.isLoading));

      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenAnswer((_) async => 'feedback');

      await notifier.analyzeScript('test');

      // First notification: isLoading = true, second: isLoading = false
      expect(states, [true, false]);
    });
  });

  group('reset', () {
    test('clears analysis and error', () async {
      when(() => mockService.analyzeScript(
            scriptText: any(named: 'scriptText'),
          )).thenAnswer((_) async => 'analysis result');

      await notifier.analyzeScript('test');
      expect(notifier.analysis, isNotNull);

      notifier.reset();

      expect(notifier.analysis, isNull);
      expect(notifier.error, isNull);
    });

    test('notifies listeners', () {
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.reset();
      expect(notified, true);
    });
  });
}
