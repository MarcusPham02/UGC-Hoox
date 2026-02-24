import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/auth_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(home: AuthScreen());
  }

  group('AuthScreen', () {
    testWidgets('renders sign-in form by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets); // AppBar title + button
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('toggles to sign-up form', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets); // AppBar title + button
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('toggles back to sign-in form', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Toggle to sign-up.
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Toggle back to sign-in.
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap sign-in with empty fields.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(
        find.text('Email and password are required.'),
        findsOneWidget,
      );
    });

    testWidgets('clears error message when toggling mode', (tester) async {
      await tester.pumpWidget(buildTestWidget());

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
}
