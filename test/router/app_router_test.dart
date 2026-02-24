import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_app/auth/auth_notifier.dart';
import 'package:hooks_app/router/app_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient mockAuth;
  late StreamController<AuthState> authStreamController;

  setUp(() {
    mockAuth = MockGoTrueClient();
    authStreamController = StreamController<AuthState>.broadcast();
    when(() => mockAuth.onAuthStateChange)
        .thenAnswer((_) => authStreamController.stream);
  });

  tearDown(() {
    authStreamController.close();
  });

  group('Router redirect logic', () {
    testWidgets('unauthenticated user accessing /access is redirected to /auth',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      // Navigate to /access while logged out.
      router.go('/access');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/auth');

      notifier.dispose();
    });

    testWidgets('authenticated user accessing /auth is redirected to /access',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(_fakeSession());
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      router.go('/auth');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/access');

      notifier.dispose();
    });

    testWidgets('unauthenticated user can access / freely',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/');

      notifier.dispose();
    });

    testWidgets('unauthenticated user can access /auth freely',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      router.go('/auth');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/auth');

      notifier.dispose();
    });

    testWidgets('authenticated user can access / freely',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(_fakeSession());
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/');

      notifier.dispose();
    });

    testWidgets('redirect triggers when auth state changes',
        (WidgetTester tester) async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);
      final router = createRouter(notifier);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();

      // Go to /auth while logged out — should stay.
      router.go('/auth');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/auth');

      // Simulate sign-in via stream event.
      authStreamController.add(AuthState(
        AuthChangeEvent.signedIn,
        _fakeSession(),
      ));
      await tester.pumpAndSettle();

      // Should now be redirected to /access.
      expect(router.state.matchedLocation, '/access');

      notifier.dispose();
    });
  });
}

class _TestApp extends StatelessWidget {
  final GoRouter router;
  const _TestApp({required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

Session _fakeSession() {
  return Session(
    accessToken: 'test-access-token',
    tokenType: 'Bearer',
    user: const User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2025-01-01T00:00:00Z',
    ),
  );
}
