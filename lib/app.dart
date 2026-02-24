import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_notifier.dart';
import 'router/app_router.dart';

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
    _authNotifier = AuthNotifier();
    _router = createRouter(_authNotifier);
  }

  @override
  void dispose() {
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
