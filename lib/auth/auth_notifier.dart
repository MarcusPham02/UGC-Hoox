import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;
  final GoTrueClient auth;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  /// Pass [auth] to inject a mock for testing.
  /// Defaults to the Supabase singleton auth client.
  AuthNotifier({GoTrueClient? auth})
      : auth = auth ?? Supabase.instance.client.auth {
    _isLoggedIn = this.auth.currentSession != null;

    _subscription = this.auth.onAuthStateChange.listen(
      (AuthState data) {
        final bool newLoggedIn;

        switch (data.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
            newLoggedIn = true;
          case AuthChangeEvent.signedOut:
            newLoggedIn = false;
          default:
            newLoggedIn = data.session != null;
        }

        if (newLoggedIn != _isLoggedIn) {
          _isLoggedIn = newLoggedIn;
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
