# Feedback System Workflow — PR Review

## Overview

A Gemini-powered feedback system where users submit hook ideas and receive AI-generated feedback evaluated against a curated library of reference hooks stored in Supabase.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SUPABASE DATABASE                     │
│                                                         │
│  hooks table (curated reference library)                │
│  ┌──────┬──────────────────────┬───────────────┐        │
│  │  id  │      content         │   category    │        │
│  ├──────┼──────────────────────┼───────────────┤        │
│  │ uuid │ "Did you know 90%…"  │ social_media  │        │
│  │ uuid │ "Stop scrolling…"    │ video_hook    │        │
│  │ uuid │ "The secret nobody…" │ blog_intro    │        │
│  └──────┴──────────────────────┴───────────────┘        │
│  RLS: only authenticated users can SELECT               │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ ② Fetch reference hooks
                         │    (filtered by category)
                         │
┌────────────┐     ┌─────┴──────────────┐     ┌──────────────────┐
│            │     │                    │     │                  │
│   USER     │ ①   │  FeedbackNotifier  │ ③   │   GEMINI API     │
│            ├────►│  (orchestrator)    ├────►│  (gemini-2.0-flash)│
│ Submits    │     │                    │     │                  │
│ hook text  │     │ • Loads categories │     │  Receives:       │
│ + picks    │     │ • Fetches hooks    │     │  • System prompt │
│ category   │     │ • Calls Gemini     │     │  • Reference     │
│            │◄────┤ • Exposes state    │◄────┤    hooks context │
│ Sees AI    │ ⑤   │   (loading/result/ │ ④   │  • User's hook   │
│ feedback   │     │    error)          │     │                  │
│            │     │                    │     │  Returns:        │
└────────────┘     └────────────────────┘     │  • Rating (1-10) │
                                              │  • Comparison    │
                                              │  • Strengths     │
                                              │  • Improvements  │
                                              │  • Alternatives  │
                                              └──────────────────┘
```

## Step-by-Step Data Flow

| Step | Action | Detail |
|------|--------|--------|
| **①** | User submits | Types hook text, optionally selects a category (e.g., "social_media") |
| **②** | Fetch from Supabase | `HooksService.getHooks(category)` queries the `hooks` table for reference content |
| **③** | Call Gemini | `FeedbackService` builds a prompt combining the reference hooks + user's hook, sends to Gemini |
| **④** | Gemini responds | Returns structured feedback: rating, comparison to references, strengths, improvements, alternatives |
| **⑤** | Display result | `FeedbackNotifier` updates state → screen rebuilds with AI feedback |

## Database Schema

```sql
create table hooks (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  category text not null,
  description text,
  created_at timestamptz default now()
);

alter table hooks enable row level security;

create policy "Authenticated users can read hooks"
  on hooks for select to authenticated using (true);
```

## New Files

```
lib/
├── config/
│   └── gemini_config.dart          # Reads GEMINI_API_KEY from compile-time env
├── models/
│   └── hook.dart                   # Data class: id, content, category, description + fromJson
├── services/
│   ├── hooks_service.dart          # Supabase queries: getHooks(), getCategories()
│   └── feedback_service.dart       # Gemini API: builds prompt, returns feedback text
├── feedback/
│   └── feedback_notifier.dart      # ChangeNotifier: orchestrates fetch → call → expose state
└── screens/
    └── feedback_screen.dart        # UI: category picker, text input, submit, feedback display
```

## Route Changes

| Path | Screen | Auth required |
|------|--------|---------------|
| `/feedback` | FeedbackScreen | Yes |

- `/feedback` protected with same redirect logic as `/access`
- Navigation button added to `AccessScreen`

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Compile-time Gemini API key via `.env.json` | Matches existing Supabase key pattern |
| Constructor-based DI on all new classes | Matches `AuthNotifier`/`AuthScreen` pattern for testability |
| `FeedbackNotifier` as `ChangeNotifier` | Matches `AuthNotifier` pattern; no new state management library |
| No streaming from Gemini | Simpler initial implementation; can add later |
| Fetch all hooks per category | Fine for curated library (tens-hundreds of rows) |

## Open Questions for Review

1. **Is the hooks table schema sufficient?** Just `content`, `category`, `description` — no tags, no scoring, no user ownership
2. **Should Gemini get ALL hooks for a category, or a subset?** Currently fetches all — fine for tens/hundreds, not thousands
3. **Is client-side Gemini API key acceptable?** Or should this go through a Supabase Edge Function to keep the key server-side?
4. **Is the prompt structure right?** Rating + comparison + strengths + improvements + alternatives

## Dependencies Added

```yaml
google_generative_ai: ^0.4.6  # Official Google Generative AI SDK for Dart
```

## Environment Variables Added

```json
{
  "GEMINI_API_KEY": "your-gemini-api-key"
}
```
