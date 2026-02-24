import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../screens/access_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';

GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final location = state.matchedLocation;

      // Not logged in and trying to access protected page -> send to auth
      if (!isLoggedIn && location == '/access') {
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
        builder: (context, state) => AuthScreen(auth: authNotifier.auth),
      ),
      GoRoute(
        path: '/access',
        builder: (context, state) => AccessScreen(auth: authNotifier.auth),
      ),
    ],
  );
}
