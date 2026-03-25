# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hooks is a Flutter app ("connecting people through shared moments") that helps users craft attention-grabbing content openers ("hooks"). Users submit hook text and receive AI-powered feedback from Gemini via a Supabase Edge Function. The Dart package is named `hooks_app` (not `hooks`).

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run (requires .env.json — see .env.json.example for required keys)
flutter run --dart-define-from-file=.env.json

# Run on Chrome (web target)
flutter run -d chrome --dart-define-from-file=.env.json

# Build web release
flutter build web --release --dart-define-from-file=.env.json

# Run all tests
flutter test

# Run a single test file
flutter test test/auth/auth_notifier_test.dart

# Analyze (lint)
flutter analyze

# Serve Edge Functions locally
supabase functions serve
```

## Secrets & Environment

All secrets live in `.env.json` (gitignored). Required keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SITE_URL`. The Edge Function also needs `GEMINI_API_KEY` and `SUPABASE_SERVICE_ROLE_KEY` set in the Supabase environment. Secrets are injected at compile time via `--dart-define-from-file=.env.json` and read through `SupabaseConfig` using `String.fromEnvironment`.

## Architecture

**State management:** `ChangeNotifier` pattern throughout — no third-party state management libraries. `AuthNotifier` and `FeedbackNotifier` are the two notifiers.

**Routing:** `go_router` with `refreshListenable` tied to `AuthNotifier`. Router redirect logic handles auth guards — `/access`, `/feedback`, and `/reset-password` require authentication; unauthenticated users redirect to `/auth`.

**Dependency injection:** Constructor-based DI on all services and notifiers. Default constructors use `Supabase.instance.client` singletons; tests inject mocks via optional constructor parameters.

**Feedback flow:**
1. Flutter client (`FeedbackService`) calls the `get-feedback` Supabase Edge Function via `FunctionsClient.invoke`
2. Edge Function (`supabase/functions/get-feedback/index.ts`) validates JWT, rate-limits per user, fetches reference hooks from the `hooks` table, builds a prompt, and calls the Gemini API server-side
3. Response flows back through `FeedbackNotifier` to the UI

**Password recovery:** Detected from URL params before `Supabase.initialize()` on web (`recovery_detection.dart`), then token is verified via OTP and `AuthNotifier.isPasswordRecovery` drives router redirects.

**Auth token refresh:** `AuthNotifier.refreshSession()` runs on app start; if the refresh token is expired, the user is signed out and `sessionExpired` flag triggers a UI message. `FeedbackNotifier.submitPrompt` catches `FeedbackAuthException` (401 from Edge Function) and retries once after refreshing the session.

## Deployment

- **Web (Netlify):** Config in `netlify.toml`. Includes security headers (CSP, HSTS) and SPA redirect.
- **Docker:** Multi-stage `Dockerfile` (Flutter build → nginx:alpine). `docker-compose.yml` maps port 3000→80 with read-only filesystem and security hardening.
- **CI:** GitHub Actions Trivy scan (vulnerability + secret scanning) on push/PR to main.

## Testing Patterns

Tests use `mocktail` for mocking. Test files mirror `lib/` structure under `test/`. Services and notifiers accept optional constructor parameters for injecting mock Supabase clients (`GoTrueClient`, `FunctionsClient`, `SupabaseClient`).
