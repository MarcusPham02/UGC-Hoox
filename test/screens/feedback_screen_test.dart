import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/feedback_screen.dart';
import 'package:hooks_app/services/feedback_service.dart';
import 'package:hooks_app/services/hooks_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHooksService extends Mock implements HooksService {}

class MockFeedbackService extends Mock implements FeedbackService {}

void main() {
  late MockHooksService mockHooksService;
  late MockFeedbackService mockFeedbackService;

  setUp(() {
    mockHooksService = MockHooksService();
    mockFeedbackService = MockFeedbackService();
    when(() => mockHooksService.getCategories())
        .thenAnswer((_) async => <String>[]);
  });

  Widget buildApp() {
    return MaterialApp(
      home: FeedbackScreen(
        hooksService: mockHooksService,
        feedbackService: mockFeedbackService,
      ),
    );
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Continue').hitTestable().first);
    await tester.pumpAndSettle();
  }

  Future<void> advanceToStep(WidgetTester tester, int step) async {
    for (var i = 0; i < step; i++) {
      await tapContinue(tester);
    }
  }

  group('FeedbackScreen wizard', () {
    testWidgets('renders stepper with 4 steps', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Audience'), findsOneWidget);
      expect(find.text('Tone'), findsOneWidget);
      expect(find.text('Your Hook'), findsOneWidget);
    });

    testWidgets('shows category chips on step 0', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Any'), findsOneWidget);
      expect(find.text('Social Media'), findsOneWidget);
      expect(find.text('Video Hook'), findsOneWidget);
      expect(find.text('Blog Intro'), findsOneWidget);
      expect(find.text('Email Subject'), findsOneWidget);
    });

    testWidgets('Continue advances to next step', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tapContinue(tester);

      expect(find.text('Who are you trying to reach?'), findsOneWidget);
    });

    testWidgets('Back button returns to previous step', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tapContinue(tester);

      await tester.tap(find.text('Back').hitTestable().first);
      await tester.pumpAndSettle();

      expect(find.text('What type of hook are you writing?'), findsOneWidget);
    });

    testWidgets('step 2 shows tone chips', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await advanceToStep(tester, 2);

      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      expect(find.text('Provocative'), findsOneWidget);
      expect(find.text('Inspirational'), findsOneWidget);
      expect(find.text('Humorous'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('step 3 shows Get Feedback button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await advanceToStep(tester, 3);

      expect(find.text('Get Feedback').hitTestable(), findsOneWidget);
    });

    testWidgets('shows feedback result and Start Over button after submit',
        (tester) async {
      when(() => mockFeedbackService.getFeedback(
            userPrompt: any(named: 'userPrompt'),
            category: any(named: 'category'),
            audience: any(named: 'audience'),
            tones: any(named: 'tones'),
          )).thenAnswer((_) async => '## Nice hook!');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await advanceToStep(tester, 3);

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your hook'),
        'Stop scrolling now!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Feedback').hitTestable().first);
      await tester.pumpAndSettle();

      expect(find.text('Start Over'), findsOneWidget);
    });

    testWidgets('Start Over resets to wizard', (tester) async {
      when(() => mockFeedbackService.getFeedback(
            userPrompt: any(named: 'userPrompt'),
            category: any(named: 'category'),
            audience: any(named: 'audience'),
            tones: any(named: 'tones'),
          )).thenAnswer((_) async => '## Feedback');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await advanceToStep(tester, 3);

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your hook'),
        'My hook text',
      );
      await tester.tap(find.text('Get Feedback').hitTestable().first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      expect(find.text('What type of hook are you writing?'), findsOneWidget);
    });
  });
}
