import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/auth_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockAuth = MockGoTrueClient();
  });

  Widget buildTestWidget({GoTrueClient? auth}) {
    return MaterialApp(home: AuthScreen(auth: auth));
  }

  group('AuthScreen', () {
    testWidgets('renders sign-in form by default', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets); // AppBar title + button
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('toggles to sign-up form', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets); // AppBar title + button
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('toggles back to sign-in form', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      // Toggle to sign-up.
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Toggle back to sign-in.
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty fields', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      // Tap sign-in with empty fields.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(
        find.text('Email and password are required.'),
        findsOneWidget,
      );
    });

    testWidgets('clears error message when toggling mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      // Trigger validation error.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      expect(find.text('Email and password are required.'), findsOneWidget);

      // Toggle to sign-up — error should clear.
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Email and password are required.'), findsNothing);
    });
  });

  group('sign-up edge cases', () {
    testWidgets(
        'shows confirmation message and switches to sign-in mode',
        (tester) async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            user: _fakeUser(identities: [_fakeIdentity()]),
          ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      // Switch to sign-up mode.
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Enter credentials.
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      // Submit.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Success message shown.
      expect(
        find.text(
            'Check your email for a confirmation link to complete sign-up.'),
        findsOneWidget,
      );

      // Form switched to sign-in mode.
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('email is preserved and password is cleared after sign-up',
        (tester) async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            user: _fakeUser(identities: [_fakeIdentity()]),
          ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Email preserved.
      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller?.text, 'test@example.com');

      // Password cleared.
      final passwordField =
          tester.widget<TextField>(find.byType(TextField).last);
      expect(passwordField.controller?.text, isEmpty);
    });

    testWidgets(
        'shows duplicate email error and switches to sign-in mode',
        (tester) async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            user: _fakeUser(identities: []), // Empty identities = duplicate
          ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(
          find.byType(TextField).first, 'taken@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Error message shown.
      expect(
        find.text('An account with this email already exists. '
            'Try signing in instead.'),
        findsOneWidget,
      );

      // Form switched to sign-in mode.
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    });
  });

  group('sign-in error handling', () {
    testWidgets('shows helpful message for email not confirmed error',
        (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'unconfirmed@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to sign in. If you recently signed up, '
            'please check your inbox for a confirmation link.'),
        findsOneWidget,
      );
    });

    testWidgets('shows improved message for invalid login credentials',
        (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException(
        'Invalid login credentials',
        statusCode: '400',
      ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid email or password. '
            'Please check your credentials and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows generic message for other AuthException errors',
        (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException(
        'Rate limit exceeded',
        statusCode: '429',
        code: 'over_request_rate_limit',
      ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid email or password. '
            'Please check your credentials and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows generic error for unexpected exceptions',
        (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('network failure'));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });
  });

  group('password reset', () {
    testWidgets('Forgot Password button is visible in sign-in mode',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Forgot Password button is hidden in sign-up mode',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Forgot Password?'), findsNothing);
    });

    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      expect(
        find.text('Enter your email to reset your password.'),
        findsOneWidget,
      );
    });

    testWidgets('shows success message after reset request', (tester) async {
      when(() => mockAuth.resetPasswordForEmail(any(),
              redirectTo: any(named: 'redirectTo')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(
        find.text('Check your email for a password reset link.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error on AuthException', (tester) async {
      when(() => mockAuth.resetPasswordForEmail(any(),
              redirectTo: any(named: 'redirectTo')))
          .thenThrow(const AuthException(
        'Rate limit exceeded',
        statusCode: '429',
      ));

      await tester.pumpWidget(buildTestWidget(auth: mockAuth));

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Rate limit exceeded'), findsOneWidget);
    });
  });
}

User _fakeUser({List<UserIdentity>? identities}) {
  return User(
    id: 'test-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2025-01-01T00:00:00Z',
    email: 'test@example.com',
    identities: identities,
  );
}

UserIdentity _fakeIdentity() {
  return const UserIdentity(
    id: 'identity-1',
    userId: 'test-user-id',
    identityData: {},
    identityId: 'identity-1',
    provider: 'email',
    createdAt: '2025-01-01T00:00:00Z',
    lastSignInAt: '2025-01-01T00:00:00Z',
  );
}
