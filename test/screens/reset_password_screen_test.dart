import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/reset_password_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakeUserAttributes extends Fake implements UserAttributes {}

void main() {
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(FakeUserAttributes());
  });

  setUp(() {
    mockAuth = MockGoTrueClient();
  });

  Widget buildTestWidget({
    GoTrueClient? auth,
    VoidCallback? onPasswordReset,
  }) {
    return MaterialApp(
      home: ResetPasswordScreen(
        auth: auth,
        onPasswordReset: onPasswordReset,
      ),
    );
  }

  group('ResetPasswordScreen', () {
    testWidgets('renders password fields and update button', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      expect(find.text('Enter your new password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update Password'),
          findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pump();

      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pump();

      expect(
          find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(find.byType(TextField).first, 'password123');
      await tester.enterText(find.byType(TextField).last, 'different456');
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('calls updateUser and onPasswordReset on success',
        (tester) async {
      var resetCalled = false;

      when(() => mockAuth.updateUser(any()))
          .thenAnswer((_) async => UserResponse.fromJson({
                'user': {
                  'id': 'test-id',
                  'app_metadata': {},
                  'user_metadata': {},
                  'aud': 'authenticated',
                  'created_at': '2025-01-01T00:00:00Z',
                },
              }));

      await tester.pumpWidget(buildTestWidget(
        auth: mockAuth,
        onPasswordReset: () => resetCalled = true,
      ));

      await tester.enterText(find.byType(TextField).first, 'newpass123');
      await tester.enterText(find.byType(TextField).last, 'newpass123');
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      verify(() => mockAuth.updateUser(any())).called(1);
      expect(resetCalled, isTrue);
    });

    testWidgets('shows error on AuthException', (tester) async {
      when(() => mockAuth.updateUser(any())).thenThrow(
        const AuthException('Password too weak', statusCode: '422'),
      );

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(find.byType(TextField).first, 'newpass123');
      await tester.enterText(find.byType(TextField).last, 'newpass123');
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password too weak'), findsOneWidget);
    });
  });
}
