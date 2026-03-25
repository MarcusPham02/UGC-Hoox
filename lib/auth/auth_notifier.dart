import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Wraps Supabase auth state into a ChangeNotifier so GoRouter can
// react to login/logout automatically via refreshListenable.
// Accepting an optional GoTrueClient so I can inject a mock in tests
// without needing to call Supabase.initialize().
class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;
  final GoTrueClient auth;

  // Checks for existing session on app start, and updates state accordingly.
  // This is important for the redirect logic to work correctly on app start.
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isPasswordRecovery = false;
  bool get isPasswordRecovery => _isPasswordRecovery;

  bool _sessionExpired = false;
  bool get sessionExpired => _sessionExpired;

  AuthNotifier({GoTrueClient? auth})
    : auth = auth ?? Supabase.instance.client.auth {
    _isLoggedIn = this.auth.currentSession != null;

    // Listen for auth changes and update login state accordingly
    _subscription = this.auth.onAuthStateChange.listen((AuthState data) {
      final bool newLoggedIn;

      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          newLoggedIn = true;
        case AuthChangeEvent.signedOut:
          newLoggedIn = false;
        case AuthChangeEvent.passwordRecovery:
          newLoggedIn = true;
          _isPasswordRecovery = true;
        default:
          // For any other event, just check if there's a session
          newLoggedIn = data.session != null;
      }

      // Only notify if the state actually changed — avoids unnecessary rebuilds
      if (newLoggedIn != _isLoggedIn || _isPasswordRecovery) {
        _isLoggedIn = newLoggedIn;
        notifyListeners();
      }
    });
  }
  void setPasswordRecovery() {
    _isPasswordRecovery = true;
    notifyListeners();
  }

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  /// Proactively refreshes the session token.
  /// If the refresh token is also expired, signs the user out
  /// and sets [sessionExpired] so the auth screen can show a message.
  Future<void> refreshSession() async {
    if (auth.currentSession == null) return;
    try {
      await auth.refreshSession();
    } catch (_) {
      _sessionExpired = true;
      await auth.signOut();
    }
  }

  void clearSessionExpired() {
    _sessionExpired = false;
  }

  //Memory Leak//
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
