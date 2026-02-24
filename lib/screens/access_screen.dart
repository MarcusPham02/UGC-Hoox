import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessScreen extends StatelessWidget {
  final GoTrueClient? _auth;

  /// Pass [auth] to inject a mock for testing.
  /// Defaults to the Supabase singleton auth client.
  const AccessScreen({super.key, GoTrueClient? auth}) : _auth = auth;

  GoTrueClient get _resolvedAuth =>
      _auth ?? Supabase.instance.client.auth;

  @override
  Widget build(BuildContext context) {
    final user = _resolvedAuth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'You are signed in!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Email: ${user?.email ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('User ID: ${user?.id ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Created: ${user?.createdAt ?? 'Unknown'}'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  await _resolvedAuth.signOut();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
