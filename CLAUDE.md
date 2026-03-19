# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hooks is a Flutter web app ("Connecting people through shared moments"). It uses Supabase as its backend (auth, database, Edge Functions) and Google Gemini for AI-powered hook feedback via a server-side Edge Function.

- **Dart SDK:** ^3.11.0
- **App ID:** com.hooks.hooks
- **Package name:** hooks_app (to avoid pub.dev conflicts)

## Build & Run Commands

All run/build commands require credentials passed via `--dart-define-from-file`:

```bash
# Run (debug)
flutter run --dart-define-from-file=.env.json

# Build web
flutter build web --dart-define-from-file=.env.json

# Tests
flutter test                        # all tests
flutter test test/widget_test.dart  # single test file

# Code analysis
flutter analyze

# Docker (production-like web build, fixed port)
docker compose up --build        # Build and run on http://localhost:3000
docker compose down              # Stop
```

## Environment Setup

Secrets are injected at compile time via Dart defines, never hardcoded:
- Copy `.env.json.example` to `.env.json` and fill in real credentials
- Required keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SITE_URL`
- `GEMINI_API_KEY` is stored as a Supabase secret (not in `.env.json`) — set via `supabase secrets set GEMINI_API_KEY=...`
- `SITE_URL` is used for Supabase auth redirects (e.g., password reset emails). Set to your running app's URL (e.g., `http://localhost:3000` for dev, Netlify URL for prod)
- `.env.json` is gitignored; the `.example` file is tracked

## Architecture

Code lives under `lib/` organized by concern: `auth/`, `config/`, `models/`, `services/`, `feedback/`, `router/`, `screens/`. Entry point is `main.dart` (Supabase init + PKCE handling) → `app.dart` (owns `AuthNotifier` + `GoRouter`).

### Routes

| Path | Screen | Auth required |
|------|--------|---------------|
| `/` | HomeScreen | No |
| `/auth` | AuthScreen | No (redirects to `/access` if logged in) |
| `/access` | AccessScreen | Yes (redirects to `/auth` if not logged in) |
| `/feedback` | FeedbackScreen | Yes |
| `/profile` | ProfileScreen | Yes |
| `/reset-password` | ResetPasswordScreen | Yes (bypassed during password recovery flow) |

### Key Patterns

- **Auth flow:** `AuthNotifier` listens to Supabase `onAuthStateChange`, calls `notifyListeners()`. GoRouter uses it as `refreshListenable` to re-run redirect logic automatically. No manual `context.go()` after login/logout.
- **Password recovery (web):** `resetPasswordForEmail` sends email with `redirectTo` pointing to `$SITE_URL/reset-password`. On return, `main.dart` parses the URL *before* `Supabase.initialize()` to extract the PKCE `code` param and detect the `/reset-password` path. It then exchanges the code for a session and passes `isPasswordRecovery: true` to `HooksApp`, which calls `AuthNotifier.setPasswordRecovery()` so GoRouter redirects to `/reset-password`. This pre-init approach is necessary because the SDK's `passwordRecovery` auth event fires on a broadcast stream before `AuthNotifier` subscribes.
- **Redirect guard:** Not logged in + protected route → redirect to `/auth`. Logged in + `/auth` → redirect to `/access`. The `/reset-password` guard is bypassed when `isPasswordRecovery` is true to avoid a redirect race.
- **Dependency injection for testability:** `AuthNotifier`, screens, and services accept optional client parameters, defaulting to Supabase singletons. This avoids needing `Supabase.initialize()` in tests.
- **Feedback system:** User submits a hook text + optional category → `FeedbackService` invokes the `get-feedback` Supabase Edge Function → Edge Function fetches reference hooks server-side, calls Gemini (gemini-2.0-flash), and returns rating, strengths, improvements, alternatives. The Gemini API key never touches the client.
- **Theming:** Material3 with `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`.
- **No state management library** — only `ChangeNotifier` (AuthNotifier, FeedbackNotifier).

## Testing

Tests mirror the `lib/` structure under `test/`. Uses `mocktail` for mocks.

**Pattern:** Mock `GoTrueClient` and inject it via constructor to test auth logic without Supabase initialization:
```dart
class MockGoTrueClient extends Mock implements GoTrueClient {}
```

For `AuthNotifier` tests, create a `StreamController<AuthState>.broadcast()` and stub `mockAuth.onAuthStateChange` to return its stream. Use `await Future<void>.delayed(Duration.zero)` to let stream events propagate before asserting.

## Deployment

- **Web:** Netlify — configured in `netlify.toml`, publishes `build/web`, SPA redirects enabled for GoRouter. CLI accessible via `npx netlify`
- **Docker:** Multi-stage build (Flutter build → nginx:alpine). Read-only container with resource limits. Port 3000 → 80.
- **Supabase Edge Functions:** `supabase/functions/` — deployed via `supabase functions deploy`. Secrets set via `supabase secrets set`.

## CI

- **Trivy SAST scan** runs on push/PR to `main` (`.github/workflows/trivy-scan.yml`) — checks for HIGH/CRITICAL vulnerabilities

## Code Style

- Keep functions and classes separate for decoupling and testability
- Test new functions and correct them if needed
- Linting: `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
