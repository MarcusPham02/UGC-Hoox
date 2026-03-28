import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthScreen extends StatefulWidget {
  final GoTrueClient? _auth;
  final bool sessionExpired;
  final VoidCallback? onSessionExpiredShown;

  /// Pass [auth] to inject a mock for testing.
  /// Defaults to the Supabase singleton auth client.
  const AuthScreen({
    super.key,
    GoTrueClient? auth,
    this.sessionExpired = false,
    this.onSessionExpiredShown,
  }) : _auth = auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  GoTrueClient get _auth =>
      widget._auth ?? Supabase.instance.client.auth;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      _errorMessage = 'Your session has expired. Please sign in again.';
      widget.onSessionExpiredShown?.call();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isSignUp) {
        final response = await _auth.signUp(
          email: email,
          password: password,
        );

        // Edge case: email already registered.
        // Supabase returns a user with empty identities instead of throwing,
        // to prevent email enumeration attacks.
        if (response.user?.identities != null &&
            response.user!.identities!.isEmpty) {
          if (mounted) {
            setState(() {
              _errorMessage = 'An account with this email already exists. '
                  'Try signing in instead.';
              _isSignUp = false;
              _passwordController.clear();
            });
          }
          return;
        }

        // Edge case: email confirmation is required.
        // Supabase returns a user but no session until the email is confirmed.
        if (response.session == null && response.user != null) {
          if (mounted) {
            setState(() {
              _successMessage =
                  'Check your email for a confirmation link to complete sign-up.';
              _isSignUp = false;
              _passwordController.clear();
            });
          }
          return;
        }

        // If session exists, AuthNotifier picks it up and GoRouter redirects.
      } else {
        await _auth.signInWithPassword(
          email: email,
          password: password,
        );
        // AuthNotifier picks up the session change and GoRouter redirects.
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'email_not_confirmed') {
            _errorMessage =
                'Unable to sign in. If you recently signed up, '
                'please check your inbox for a confirmation link.';
          } else {
            _errorMessage =
                'Invalid email or password. '
                'Please check your credentials and try again.';
          }
          debugPrint('Auth error: ${e.code} - ${e.message}');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email to reset your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: '${SupabaseConfig.siteUrl.replaceAll(RegExp(r'/+$'), '')}/auth/confirm',
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Check your email for a password reset link.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSignUp ? 'Create an account' : 'Welcome back',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
            ),
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign In'
                    : "Don't have an account? Sign Up",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
