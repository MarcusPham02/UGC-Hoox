import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../screens/access_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/home_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/script_analyzer_screen.dart';

GoRouter createRouter(AuthNotifier authNotifier, {String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final location = state.matchedLocation;

      // Password recovery flow — redirect to reset screen
      if (authNotifier.isPasswordRecovery && location != '/reset-password') {
        return '/reset-password';
      }

      // Not logged in and trying to access protected page -> send to auth
      if (!isLoggedIn && !authNotifier.isPasswordRecovery &&
          (location == '/access' || location == '/feedback' ||
           location == '/script-analyzer' || location == '/reset-password')) {
        return '/auth';
      }

      // Logged in and still on auth page -> send to access
      if (isLoggedIn && location == '/auth') {
        return '/access';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthScreen(
          auth: authNotifier.auth,
          sessionExpired: authNotifier.sessionExpired,
          onSessionExpiredShown: () => authNotifier.clearSessionExpired(),
        ),
      ),
      GoRoute(
        path: '/access',
        builder: (context, state) => AccessScreen(auth: authNotifier.auth),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => FeedbackScreen(
          authNotifier: authNotifier,
        ),
      ),
      GoRoute(
        path: '/script-analyzer',
        builder: (context, state) => ScriptAnalyzerScreen(
          authNotifier: authNotifier,
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          auth: authNotifier.auth,
          onPasswordReset: () => authNotifier.clearPasswordRecovery(),
        ),
      ),
    ],
  );
}
