# Dualio

Dualio is a Flutter mobile client for an AI-first semantic memory inbox. The current implementation is a native mobile app with authenticated Supabase persistence, Android share intake, on-device image optimization before Cloudflare R2 upload, typed item detail layouts, strict Dart analysis settings, localization files, and Supabase RAG schema contracts.

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

`process-item` uses Supabase Edge Function secrets for OpenAI and Cloudflare R2. Without `OPENAI_API_KEY`, link/text/image processing still completes with safe fallback summaries and metadata, but item/chunk embeddings are not generated. The `search` Edge Function uses query embeddings plus the `match_semantic_items` RPC when embeddings are available, and falls back to lexical search otherwise. R2 cleanup uses `delete-item`, `delete-account`, and `cleanup-assets`; scheduled cleanup requires `CLEANUP_ASSETS_SECRET` and the `dualio-cleanup-assets-hourly` cron job.

Useful Edge Function checks:

```powershell
npx deno-bin test --allow-env supabase/functions/_shared/link_resolver_test.ts supabase/functions/_shared/link_enrichment_test.ts
npx deno-bin test --allow-env supabase/functions/_shared/embeddings_test.ts
npx deno-bin check supabase/functions/process-item/index.ts supabase/functions/search/index.ts supabase/functions/create-asset-upload/index.ts supabase/functions/delete-item/index.ts supabase/functions/delete-account/index.ts supabase/functions/cleanup-assets/index.ts supabase/functions/_shared/r2_cleanup.ts supabase/functions/_shared/semantic_extraction.ts supabase/functions/_shared/link_enrichment.ts supabase/functions/_shared/embeddings.ts
```

Apply remote database migrations:

```powershell
npx supabase login
npx supabase link --project-ref uogaveubabnsskfwftui
npx supabase db push
```

Signed-in feeds read from Supabase. Local optimistic items are still used so captures feel immediate while backend processing runs.
