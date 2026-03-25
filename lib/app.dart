import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_notifier.dart';
import 'router/app_router.dart';

// Root widget — owns the auth notifier and router so they share the same lifecycle.
// Using StatefulWidget here so I can properly dispose the auth subscription.
class HooksApp extends StatefulWidget {
  final bool isPasswordRecovery;

  const HooksApp({super.key, this.isPasswordRecovery = false});

  @override
  State<HooksApp> createState() => _HooksAppState();
}

class _HooksAppState extends State<HooksApp> {
  late final AuthNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the auth notifier first since the router depends on it
    _authNotifier = AuthNotifier();
    // If we detected a password recovery URL before Supabase init,
    // set the flag now so GoRouter redirects to /reset-password.
    if (widget.isPasswordRecovery) {
      _authNotifier.setPasswordRecovery();
    }
    _router = createRouter(
      _authNotifier,
      initialLocation: widget.isPasswordRecovery ? '/reset-password' : null,
    );

    // Proactively refresh the session on app start so stale tokens
    // are caught immediately rather than on the first API call.
    if (!widget.isPasswordRecovery) {
      _authNotifier.refreshSession();
    }
  }

  @override
  void dispose() {
    // Clean up the auth stream subscription
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hooks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
