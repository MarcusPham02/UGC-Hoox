import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_notifier.dart';
import 'router/app_router.dart';

// Root widget — owns the auth notifier and router so they share the same lifecycle.
// Using StatefulWidget here so I can properly dispose the auth subscription.
class HooksApp extends StatefulWidget {
  const HooksApp({super.key});

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
    _router = createRouter(_authNotifier);
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
