import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/screens/access_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('AccessScreen', () {
    testWidgets('renders signed-in UI with user info from mock',
        (tester) async {
      final mockAuth = MockGoTrueClient();
      when(() => mockAuth.currentUser).thenReturn(const User(
        id: 'abc-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        email: 'test@example.com',
        createdAt: '2025-01-01T00:00:00Z',
      ));

      await tester.pumpWidget(MaterialApp(
        home: AccessScreen(auth: mockAuth),
      ));

      expect(find.text('You are signed in!'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
      expect(find.text('User ID: abc-123'), findsOneWidget);
      expect(find.text('Created: 2025-01-01T00:00:00Z'), findsOneWidget);
    });

    testWidgets('renders Unknown when user is null', (tester) async {
      final mockAuth = MockGoTrueClient();
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(MaterialApp(
        home: AccessScreen(auth: mockAuth),
      ));

      expect(find.text('Email: Unknown'), findsOneWidget);
      expect(find.text('User ID: Unknown'), findsOneWidget);
      expect(find.text('Created: Unknown'), findsOneWidget);
    });
  });
}
