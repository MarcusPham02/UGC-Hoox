import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/auth/auth_notifier.dart';
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

  group('AuthNotifier', () {
    test('starts as logged out when no current session', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      final notifier = AuthNotifier(auth: mockAuth);

      expect(notifier.isLoggedIn, false);
      notifier.dispose();
    });

    test('starts as logged in when session exists', () {
      when(() => mockAuth.currentSession).thenReturn(_fakeSession());

      final notifier = AuthNotifier(auth: mockAuth);

      expect(notifier.isLoggedIn, true);
      notifier.dispose();
    });

    test('updates to logged in on signedIn event', () async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);

      var notified = false;
      notifier.addListener(() => notified = true);

      authStreamController.add(AuthState(
        AuthChangeEvent.signedIn,
        _fakeSession(),
      ));

      // Let the stream event propagate.
      await Future<void>.delayed(Duration.zero);

      expect(notifier.isLoggedIn, true);
      expect(notified, true);
      notifier.dispose();
    });

    test('updates to logged out on signedOut event', () async {
      when(() => mockAuth.currentSession).thenReturn(_fakeSession());
      final notifier = AuthNotifier(auth: mockAuth);

      var notified = false;
      notifier.addListener(() => notified = true);

      authStreamController.add(const AuthState(
        AuthChangeEvent.signedOut,
        null,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(notifier.isLoggedIn, false);
      expect(notified, true);
      notifier.dispose();
    });

    test('does not notify when state has not changed', () async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);

      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      // Already logged out, sending signedOut should not notify.
      authStreamController.add(const AuthState(
        AuthChangeEvent.signedOut,
        null,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, 0);
      notifier.dispose();
    });

    test('handles tokenRefreshed as still logged in', () async {
      when(() => mockAuth.currentSession).thenReturn(null);
      final notifier = AuthNotifier(auth: mockAuth);

      authStreamController.add(AuthState(
        AuthChangeEvent.tokenRefreshed,
        _fakeSession(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(notifier.isLoggedIn, true);
      notifier.dispose();
    });
  });
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
