# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hooks is a cross-platform Flutter app ("Connecting people through shared moments") targeting iOS, Android, and Web. It uses Supabase as its backend and Google Gemini for AI-powered hook feedback.

- **Dart SDK:** ^3.11.0
- **App ID:** com.hooks.hooks
- **Package name:** hooks_app (to avoid pub.dev conflicts)

## Build & Run Commands

All run/build commands require credentials passed via `--dart-define-from-file`:

```bash
# Run (debug)
flutter run --dart-define-from-file=.env.json

# Build per platform
flutter build web --dart-define-from-file=.env.json
flutter build apk --dart-define-from-file=.env.json
flutter build ios --dart-define-from-file=.env.json
flutter build ipa --dart-define-from-file=.env.json  # iOS archive for App Store

# Tests
flutter test                        # all tests
flutter test test/widget_test.dart  # single test file

# Code analysis
flutter analyze
```

## Environment Setup

Secrets are injected at compile time via Dart defines, never hardcoded:
- Copy `.env.json.example` to `.env.json` and fill in real credentials
- Required keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GEMINI_API_KEY`, `SITE_URL`
- `SITE_URL` is used for Supabase auth redirects (e.g., password reset emails). Set to your running app's URL (e.g., `http://localhost:PORT` for dev, Netlify URL for prod)
- `.env.json` is gitignored; the `.example` file is tracked
- Android signing uses `android/key.properties` (also gitignored, see `android/key.properties.example`)

## Architecture

```
lib/
├── main.dart                  # Entry point — initializes Supabase, runs app
├── app.dart                   # StatefulWidget: owns AuthNotifier + GoRouter lifecycle
├── auth/
│   └── auth_notifier.dart     # ChangeNotifier wrapping onAuthStateChange stream
├── config/
│   ├── supabase_config.dart   # Reads SUPABASE_URL, SUPABASE_ANON_KEY, SITE_URL from env
│   └── gemini_config.dart     # Reads GEMINI_API_KEY from env
├── models/
│   └── hook.dart              # Hook data class (id, content, category, description)
├── services/
│   ├── hooks_service.dart     # Supabase queries: getHooks(category?), getCategories()
│   └── feedback_service.dart  # Gemini API: generates AI feedback on user-submitted hooks
├── feedback/
│   └── feedback_notifier.dart # ChangeNotifier orchestrating hook fetch + Gemini feedback
├── router/
│   └── app_router.dart        # GoRouter with auth redirect guard (refreshListenable)
└── screens/
    ├── home_screen.dart           # Public landing page (/)
    ├── auth_screen.dart           # Email/password sign-in and sign-up (/auth)
    ├── access_screen.dart         # Protected — user info + sign out (/access)
    ├── feedback_screen.dart       # Protected — hook feedback with AI (/feedback)
    └── reset_password_screen.dart # Protected — new password form (/reset-password)
```

### Routes

| Path | Screen | Auth required |
|------|--------|---------------|
| `/` | HomeScreen | No |
| `/auth` | AuthScreen | No (redirects to `/access` if logged in) |
| `/access` | AccessScreen | Yes (redirects to `/auth` if not logged in) |
| `/feedback` | FeedbackScreen | Yes |
| `/reset-password` | ResetPasswordScreen | Yes |

### Key Patterns

- **Auth flow:** `AuthNotifier` listens to Supabase `onAuthStateChange`, calls `notifyListeners()`. GoRouter uses it as `refreshListenable` to re-run redirect logic automatically. No manual `context.go()` after login/logout.
- **Password recovery:** `resetPasswordForEmail` sends email with `redirectTo` pointing to `SITE_URL`. On return, `AuthNotifier` detects the `passwordRecovery` event and GoRouter redirects to `/reset-password`.
- **Redirect guard:** Not logged in + protected route → redirect to `/auth`. Logged in + `/auth` → redirect to `/access`.
- **Dependency injection for testability:** `AuthNotifier`, screens, and services accept optional client parameters, defaulting to Supabase/Gemini singletons. This avoids needing `Supabase.initialize()` in tests.
- **Feedback system:** User submits a hook text + optional category → `FeedbackNotifier` fetches reference hooks from Supabase → sends to Gemini (gemini-2.0-flash) → returns rating, strengths, improvements, alternatives.
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
- **iOS:** Privacy manifest at `ios/Runner/PrivacyInfo.xcprivacy` (UserDefaults + boot time APIs declared)
- **Android:** Release signing configured in `build.gradle.kts` via `key.properties`

## CI

- **Trivy SAST scan** runs on push/PR to `main` (`.github/workflows/trivy-scan.yml`) — checks for HIGH/CRITICAL vulnerabilities

## Code Style

- Keep functions and classes separate for decoupling and testability
- Test new functions and correct them if needed
- Linting: `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
