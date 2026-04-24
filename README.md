# Dualio

Dualio is a Flutter mobile client for an AI-first semantic memory inbox. The current implementation is a native mobile scaffold with a mock editorial feed, typed item detail layouts, strict Dart analysis settings, localization files, and Supabase RAG schema contracts.

## Setup

Flutter is installed locally at `C:\Users\plkns\dev\flutter`.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d android
```

## Supabase

Development project URL:

```text
https://uogaveubabnsskfwftui.supabase.co
```

Run the app with Supabase enabled:

```powershell
.\scripts\run_android_dev.ps1 -d RFCY702JKVP
```

Do not commit Supabase anon, service role, OpenAI, Cloudflare, or OAuth secrets.

Apply remote database migrations:

```powershell
npx supabase login
npx supabase link --project-ref uogaveubabnsskfwftui
npx supabase db push
```

The feed is intentionally backed by mock semantic items until the card system visually matches the design.
