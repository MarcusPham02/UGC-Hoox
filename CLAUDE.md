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
# Run (debug, web on Chrome)
flutter run -d chrome --dart-define-from-file=.env.json --web-port=3000

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
- **Docker builds** require `.env.json` in the project root (it's not excluded by `.dockerignore` — the Dockerfile copies it for `--dart-define-from-file`)
- **Netlify builds:** `netlify.toml` runs `flutter build web --release` without `--dart-define-from-file` — Dart defines must be configured via Netlify's build environment or the build command needs updating

## Architecture

Code lives under `lib/` organized by concern: `auth/`, `config/`, `models/`, `services/`, `feedback/`, `router/`, `screens/`. Entry point is `main.dart` (Supabase init + PKCE handling) → `app.dart` (owns `AuthNotifier` + `GoRouter`).

### Routes

Defined in `router/app_router.dart` via `createRouter()`:

| Path | Screen | Auth required |
|------|--------|---------------|
| `/` | HomeScreen | No |
| `/auth` | AuthScreen | No (redirects to `/access` if logged in) |
| `/access` | AccessScreen | Yes (redirects to `/auth` if not logged in) |
| `/feedback` | FeedbackScreen | Yes |
| `/reset-password` | ResetPasswordScreen | Yes (bypassed during password recovery flow) |

Note: `ProfileScreen` exists in `screens/` but is **not registered** in the router.

### Key Patterns

- **Auth flow:** `AuthNotifier` listens to Supabase `onAuthStateChange`, calls `notifyListeners()`. GoRouter uses it as `refreshListenable` to re-run redirect logic automatically. No manual `context.go()` after login/logout.
- **Password recovery (web):** `resetPasswordForEmail` sends email linking to `/auth/confirm?token_hash=xxx&type=recovery&next=/reset-password`. On return, `main.dart` uses `detectRecoveryFromUrl()` (in `auth/recovery_detection.dart`) to parse the URL *before* `Supabase.initialize()`, extracting the `token_hash` and detecting the recovery type. It then calls `verifyOTP(tokenHash:, type: recovery)` to establish a session and passes `isPasswordRecovery: true` to `HooksApp`, which calls `AuthNotifier.setPasswordRecovery()` so GoRouter redirects to `/reset-password`. This pre-init approach is necessary because the SDK's `passwordRecovery` auth event fires on a broadcast stream before `AuthNotifier` subscribes.
- **Redirect guard:** Not logged in + protected route → redirect to `/auth`. Logged in + `/auth` → redirect to `/access`. The `/reset-password` guard is bypassed when `isPasswordRecovery` is true to avoid a redirect race.
- **Dependency injection for testability:** `AuthNotifier`, screens, and services accept optional client parameters (e.g., `GoTrueClient`, `FunctionsClient`, `SupabaseClient`), defaulting to Supabase singletons. This avoids needing `Supabase.initialize()` in tests.
- **Feedback system:** User submits a hook text + optional category → `FeedbackService` invokes the `get-feedback` Supabase Edge Function → Edge Function fetches reference hooks from the `hooks` table server-side (falls back to hardcoded samples if table doesn't exist), calls Gemini (gemini-2.0-flash), and returns structured feedback. The Gemini API key never touches the client. Feedback is rendered as markdown via `flutter_markdown`.
- **No state management library** — only `ChangeNotifier` (`AuthNotifier`, `FeedbackNotifier`).

## Testing

Tests mirror the `lib/` structure under `test/`. Uses `mocktail` for mocks.

**Pattern:** Mock `GoTrueClient` and inject it via constructor to test auth logic without Supabase initialization:
```dart
class MockGoTrueClient extends Mock implements GoTrueClient {}
```

For `AuthNotifier` tests, create a `StreamController<AuthState>.broadcast()` and stub `mockAuth.onAuthStateChange` to return its stream. Use `await Future<void>.delayed(Duration.zero)` to let stream events propagate before asserting.

## Deployment

- **Web:** Netlify — configured in `netlify.toml`, publishes `build/web`, SPA redirects enabled for GoRouter. Security headers (CSP, HSTS, X-Frame-Options) configured in `netlify.toml`. CLI accessible via `npx netlify`.
- **Docker:** Multi-stage build (Flutter build → nginx:alpine). Read-only container (`read_only: true` in compose) with `tmpfs` mounts for nginx cache/run dirs. Resource limits (256M RAM, 0.5 CPU). Port 3000 → 80. Custom `nginx.conf` for SPA routing.
- **Supabase Edge Functions:** `supabase/functions/` — deployed via `supabase functions deploy`. Secrets set via `supabase secrets set`.

## Supabase

- **Edge Functions:** `supabase/functions/get-feedback/index.ts` — Deno-based, uses `Deno.serve()`. Rate-limited (10 req/min per user, in-memory). Allowed categories: `social_media`, `video_hook`, `blog_intro`, `email_subject`. Max prompt length: 500 chars.
- **Migrations:** `supabase/migrations/` — SQL migrations managed via Supabase CLI (`supabase db push` / `supabase migration new`).
- **Config:** `supabase/config.toml` — local dev configuration.

## CI

- **Trivy** runs on push/PR to `main` (`.github/workflows/trivy-scan.yml`): vulnerability scan, secret scan, and SARIF upload to GitHub Security tab.

## Code Style

- Linting: `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
- Theming: Material3 with `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`
- Keep functions and classes separate for decoupling and testability
- Test new functions and correct them if needed
