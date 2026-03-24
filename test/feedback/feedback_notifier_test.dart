import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/feedback/feedback_notifier.dart';
import 'package:hooks_app/services/feedback_service.dart';
import 'package:hooks_app/services/hooks_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHooksService extends Mock implements HooksService {}

class MockFeedbackService extends Mock implements FeedbackService {}

void main() {
  late MockHooksService mockHooksService;
  late MockFeedbackService mockFeedbackService;
  late FeedbackNotifier notifier;

  setUp(() {
    mockHooksService = MockHooksService();
    mockFeedbackService = MockFeedbackService();
    notifier = FeedbackNotifier(
      hooksService: mockHooksService,
      feedbackService: mockFeedbackService,
    );
  });

  group('wizard navigation', () {
    test('starts at step 0', () {
      expect(notifier.currentStep, 0);
    });

    test('nextStep increments currentStep', () {
      notifier.nextStep();
      expect(notifier.currentStep, 1);
    });

    test('nextStep does not go past 3', () {
      notifier.goToStep(3);
      notifier.nextStep();
      expect(notifier.currentStep, 3);
    });

    test('previousStep decrements currentStep', () {
      notifier.goToStep(2);
      notifier.previousStep();
      expect(notifier.currentStep, 1);
    });

    test('previousStep does not go below 0', () {
      notifier.previousStep();
      expect(notifier.currentStep, 0);
    });

    test('goToStep sets step within bounds', () {
      notifier.goToStep(3);
      expect(notifier.currentStep, 3);

      notifier.goToStep(0);
      expect(notifier.currentStep, 0);
    });

    test('goToStep ignores out-of-bounds values', () {
      notifier.goToStep(-1);
      expect(notifier.currentStep, 0);

      notifier.goToStep(4);
      expect(notifier.currentStep, 0);
    });

    test('nextStep notifies listeners', () {
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.nextStep();
      expect(notified, true);
    });
  });

  group('category selection', () {
    test('selectCategory updates selectedCategory', () {
      notifier.selectCategory('video_hook');
      expect(notifier.selectedCategory, 'video_hook');
    });

    test('selectCategory with null clears selection', () {
      notifier.selectCategory('video_hook');
      notifier.selectCategory(null);
      expect(notifier.selectedCategory, isNull);
    });
  });

  group('audience', () {
    test('setAudience stores trimmed value', () {
      notifier.setAudience('  startup founders  ');
      expect(notifier.audience, 'startup founders');
    });

    test('setAudience with null clears value', () {
      notifier.setAudience('test');
      notifier.setAudience(null);
      expect(notifier.audience, isNull);
    });
  });

  group('tone toggling', () {
    test('toggleTone adds a tone', () {
      notifier.toggleTone('casual');
      expect(notifier.selectedTones, ['casual']);
    });

    test('toggleTone removes an already selected tone', () {
      notifier.toggleTone('casual');
      notifier.toggleTone('casual');
      expect(notifier.selectedTones, isEmpty);
    });

    test('toggleTone caps at 2 tones', () {
      notifier.toggleTone('casual');
      notifier.toggleTone('professional');
      notifier.toggleTone('humorous');
      expect(notifier.selectedTones, ['casual', 'professional']);
    });

    test('toggleTone notifies listeners', () {
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.toggleTone('urgent');
      expect(notified, true);
    });
  });

  group('resetWizard', () {
    test('clears all wizard state', () {
      notifier.goToStep(2);
      notifier.selectCategory('blog_intro');
      notifier.setAudience('developers');
      notifier.toggleTone('casual');

      notifier.resetWizard();

      expect(notifier.currentStep, 0);
      expect(notifier.selectedCategory, isNull);
      expect(notifier.audience, isNull);
      expect(notifier.selectedTones, isEmpty);
      expect(notifier.feedback, isNull);
      expect(notifier.error, isNull);
    });
  });

  group('loadCategories', () {
    test('populates categories list on success', () async {
      when(() => mockHooksService.getCategories())
          .thenAnswer((_) async => ['social_media', 'video_hook']);

      await notifier.loadCategories();

      expect(notifier.categories, ['social_media', 'video_hook']);
    });

    test('silently handles errors', () async {
      when(() => mockHooksService.getCategories())
          .thenThrow(Exception('table not found'));

      await notifier.loadCategories();

      expect(notifier.categories, isEmpty);
    });
  });

  group('submitPrompt', () {
    test('passes all fields to FeedbackService on success', () async {
      notifier.selectCategory('social_media');
      notifier.setAudience('marketers');
      notifier.toggleTone('casual');
      notifier.toggleTone('humorous');

      when(() => mockFeedbackService.getFeedback(
            userPrompt: any(named: 'userPrompt'),
            category: any(named: 'category'),
            audience: any(named: 'audience'),
            tones: any(named: 'tones'),
          )).thenAnswer((_) async => '## Great hook!');

      await notifier.submitPrompt('test hook');

      expect(notifier.feedback, '## Great hook!');
      expect(notifier.error, isNull);
      expect(notifier.isLoading, false);

      verify(() => mockFeedbackService.getFeedback(
            userPrompt: 'test hook',
            category: 'social_media',
            audience: 'marketers',
            tones: ['casual', 'humorous'],
          )).called(1);
    });

    test('sets error on failure', () async {
      when(() => mockFeedbackService.getFeedback(
            userPrompt: any(named: 'userPrompt'),
            category: any(named: 'category'),
            audience: any(named: 'audience'),
            tones: any(named: 'tones'),
          )).thenThrow(Exception('network error'));

      await notifier.submitPrompt('test hook');

      expect(notifier.feedback, isNull);
      expect(notifier.error, 'Failed to get feedback. Please try again.');
      expect(notifier.isLoading, false);
    });

    test('omits audience and tones when not set', () async {
      when(() => mockFeedbackService.getFeedback(
            userPrompt: any(named: 'userPrompt'),
            category: any(named: 'category'),
            audience: any(named: 'audience'),
            tones: any(named: 'tones'),
          )).thenAnswer((_) async => 'feedback');

      await notifier.submitPrompt('test hook');

      expect(notifier.feedback, 'feedback');

      verify(() => mockFeedbackService.getFeedback(
            userPrompt: 'test hook',
            category: null,
            audience: null,
            tones: null,
          )).called(1);
    });
  });
}
