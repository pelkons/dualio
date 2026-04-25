# Dualio Project Status

Last updated: 2026-04-25

## Current Identity

- Project name: Dualio
- Previous name: Embera
- GitHub repository: `https://github.com/pelkons/dualio.git`
- First GitHub push: completed.
- Repository folder is still `C:\Users\plkns\mycode\embera`; app/package identity is `dualio`.
- The user is the project owner.
- AI agents must never be listed as co-authors, contributors, maintainers, copyright holders, or credits.
- Do not add AI attribution trailers such as `Co-Authored-By`, `Generated-By`, or `Assisted-By`.

## Current Stage

Dualio is in backend hardening and production-safety stage after first-pass embedding-backed search integration.

The project has a Flutter-first mobile app, authenticated Supabase feed, Android share intake, on-device image optimization before R2 upload, R2 cleanup lifecycle functions, social/link resolving, link/text/image semantic extraction, best-effort item/chunk embedding generation, first-pass backend hybrid search, RAG-first Supabase schema, project-level Codex skills, and Claude agent instructions. Flutter and Android tooling are installed and the Android debug APK builds successfully.

## Completed

- Read and preserved the design source files in `design/`.
- Created Flutter project structure manually.
- Added strict Dart analysis settings.
- Added Flutter dependencies in `pubspec.yaml`.
- Added localization setup for English, Hebrew, Russian, Italian, French, Spanish, and German.
- Built design tokens, light/dark theme, typography, top header, search pill, bottom navigation, and floating add button.
- Added mock semantic items for the original item types.
- Added compact feed cards for article, recipe, film, place, product, video, manual, note, and unknown.
- Added placeholder screens for sign-in, add/capture, search, settings, and item details.
- Added type-specific detail layouts.
- Added Riverpod local semantic item state.
- Replaced the capture placeholder with a mock-first capture screen for text, links, photo library, and camera.
- Replaced the search placeholder with local mock semantic search over titles, summaries, aliases, and parsed content.
- Added app configuration via `--dart-define` for optional Supabase URL and anon key.
- Added optional Supabase bootstrap that keeps the app runnable without backend credentials.
- Replaced the sign-in placeholder with an email magic-link screen wired to Supabase when configured.
- Added Google OAuth sign-in button using Supabase Auth and Android deep link callback `dualio://auth/callback`.
- Added iOS-only Apple OAuth sign-in scaffold using Supabase Auth, iOS Sign in with Apple entitlement, and iOS `dualio://auth/callback` URL scheme.
- Replaced the settings placeholder with theme controls plus account/subscription sections.
- Moved app language selection out of in-app Settings and into Android per-app language settings via `android:localeConfig`.
- Added Android share-sheet support for shared links/text and images through `ACTION_SEND` and `ACTION_SEND_MULTIPLE`.
- Added Flutter share intake listener using `receive_sharing_intent`; incoming shares create local pending semantic items.
- Verified on physical Samsung phone that sharing from another Android app into Dualio works.
- Added `design/icon.png` as the app launcher icon source and generated Android/iOS launcher icons.
- Built and installed the debug APK with the new launcher icon on the connected Samsung Android phone.
- Added Supabase migration for profiles, items, item_chunks, item_entities, search_events, RLS, indexes, pgvector, and hybrid search RPC.
- Added Edge Function contracts for `process-item` and `search`.
- Added `ItemsRepository` for Supabase `items` reads and pending item inserts.
- Connected feed/detail/search to remote Supabase items when a signed-in user exists, with mock/local fallback.
- Connected Add and Android share intake to insert pending items into Supabase after local optimistic insertion.
- Fixed Android magic-link deep link routing for `dualio://auth/callback?...` so GoRouter redirects callbacks to the feed instead of Page Not Found.
- Made Add capture return to the feed immediately after local save while Supabase sync runs in the background.
- Added swipe-left deletion from the feed with confirmation dialog and best-effort Supabase remote delete.
- Added visible signed-in account state: Account now shows the current email and a sign-out action instead of always showing magic-link sign-in.
- Fixed signed-in feed visibility after capture by merging local optimistic pending items above remote items.
- Smoothed feed deletion by hiding removed items locally and avoiding full-screen reload during remote delete.
- Removed demo-feed fallback during signed-in feed loading/error states to avoid flashing mock cards after deletion.
- Fixed deletion edge case where signed-in feed could briefly re-render mock demo items or a dismissed card during refresh.
- Scoped the floating add button to the home feed only; secondary screens no longer show it.
- Fixed swipe-delete confirmation so the item is marked removed immediately on first confirmation instead of waiting for a second attempt.
- Removed mock demo items from the runtime feed provider; demo fixtures remain in `lib/mock/` but are no longer shown in the app.
- Deleted the mock demo item fixture file entirely from `lib/mock/`.
- Added raw-content retention schema fields with migration `202604240002_raw_content_retention.sql`.
- Implemented and deployed `process-item` Edge Function v1 for link metadata fetching without OpenAI.
- Connected link item creation to invoke `process-item` after Supabase insert.
- Fixed article/link preview cards and details to tolerate missing full-article fields from metadata-only processing.
- Replaced the question-mark icon on processing cards with a neutral sync icon to avoid confusing RTL-mirrored help icons.
- Added `legal/TERMS_PRIVACY_NOTES.md` as the non-legal source-of-truth for future Terms, Privacy Policy, AI processing disclosure, retention, and subprocessors.
- Created `roadmap.md`.
- Installed project-level skills in `.codex/skills/`.
- Added Claude project context in `CLAUDE.md`.
- Added Claude subagents in `.claude/agents/`.
- Renamed app identity from Embera to Dualio.
- Connected Git remote `origin` and completed the first GitHub push.
- Created the Supabase development project at `https://uogaveubabnsskfwftui.supabase.co`.
- Added local `.env.local` for uncommitted secrets and `.env.example` for safe project documentation.
- Added `scripts/run_android_dev.ps1` to run Flutter with Supabase values loaded from `.env.local`.
- Initialized Supabase CLI config for the project and configured mobile auth redirect `dualio://auth/callback`.
- Linked the local Supabase CLI project to remote project `uogaveubabnsskfwftui`.
- Applied remote migration `202604240001_rag_semantic_memory.sql`; local and remote migration versions match.
- Installed Flutter stable at `C:\Users\plkns\dev\flutter`.
- Installed Android command-line tools and accepted Android SDK licenses.
- Generated Android/iOS Flutter wrappers with `flutter create`.
- Ran `flutter pub get`.
- Generated Flutter localization files.
- Generated Freezed/json_serializable files.
- Ran `flutter analyze` successfully.
- Added a Flutter smoke test and ran `flutter test` successfully.
- Built Android debug APK successfully at `build\app\outputs\flutter-apk\app-debug.apk`.
- Created Cloudflare R2 bucket `dualio-assets` and configured R2 secrets for Supabase Edge Functions.
- Added `item_assets` migration for per-user image asset metadata with strict RLS.
- Added `create-asset-upload` Edge Function for signed R2 PUT/GET URL creation.
- Connected photo/screenshot share intake to upload images to R2 before processing.
- Fixed R2 upload `411 Length Required` by sending explicit `Content-Length` from Flutter.
- Added on-device photo/screenshot optimization before R2 upload and a declared byte-size limit in `create-asset-upload`.
- Added `asset_cleanup_jobs` and Edge Functions for R2 cleanup on item deletion, account deletion, and scheduled abandoned-upload cleanup.
- Applied remote migrations through `202604240005_schedule_asset_cleanup.sql`.
- Deployed `create-asset-upload`, `delete-item`, `delete-account`, `cleanup-assets`, `process-item`, and `search` to Supabase.
- Added `CLEANUP_ASSETS_SECRET` locally and in Supabase secrets, stored the schedule copy in Supabase Vault, and enabled hourly `dualio-cleanup-assets-hourly`.
- Added Settings account deletion flow for signed-in users.
- Built and installed the updated Android debug APK with Supabase dart-defines on the connected Samsung device.
- Verified a shared WhatsApp image uploads to R2, creates an `item_assets` row, and replaces the local Android cache path with a signed R2 URL.
- Extended `process-item` to process photo/screenshot items from R2 asset metadata.
- Added image vision analysis contract using the OpenAI Responses API when `OPENAI_API_KEY` is configured, with a safe fallback when vision credentials are absent.
- Added image search-doc writes: `item_chunks`, `item_entities`, searchable summary, searchable aliases, parsed image summary, and visible text.
- Added dedicated feed/detail presentation for processed image items so inferred item type does not rely on mock-only fields.
- Added share-confirmation flow before saving incoming Android shares, including optional personal note capture.
- Fixed duplicate local `Processing` placeholders by matching optimistic local captures to processed remote items by source, URL, filename, and asset metadata.
- Added social/link resolver support for TikTok, YouTube, X/Twitter, Facebook/Instagram fallback paths, Reddit, and generic OpenGraph.
- Fixed Reddit short-share links (`/r/.../s/...`) by expanding them to canonical `/comments/...` URLs before resolving.
- Added Reddit JSON extraction for title, self text, author, subreddit, score, comment count, permalink, and usable preview metadata.
- Added Reddit oEmbed fallback so Reddit links do not degrade to empty `Reddit link` cards if JSON is unavailable.
- Added Reddit preview thumbnail fallback for self posts using `share.redd.it/preview/post/<post_id>`.
- Added schema.org Recipe JSON-LD extraction for recipe sites so link processing can read ingredients, steps, times, yield, image, author, and rating instead of relying only on OpenGraph title/description.
- Split experimental public HTML enrichment into the general `ENABLE_UNOFFICIAL_LINK_ENRICHMENT` flag and a separate `ENABLE_SOCIAL_HTML_ENRICHMENT` flag so social HTML enrichment stays disabled by default.
- Added Deno tests for social HTML enrichment opt-in behavior.
- Added an OpenRouter structured-output adapter for saved links, raw text, and image analysis with `provider.require_parameters=true`, plus a temporary direct OpenAI fallback while the migration is in progress.
- Extended `process-item` to write typed `parsed_content`, summaries, aliases, entities, and chunks for saved links and raw text.
- Added OpenRouter embedding generation for item-level and chunk-level search documents, using `openai/text-embedding-3-small` by default to preserve the current `vector(1536)` schema and writing pgvector-compatible values.
- Made embedding generation best-effort so missing or failed embedding calls do not fail item processing.
- Added Deno tests for embedding fallback and pgvector serialization.
- Implemented the `search` Edge Function with query embeddings, `match_semantic_items` RPC calls, lexical fallback, inferred item type hints, result score/match reason output, and `search_events` logging.
- Fixed multilingual search intent inference by replacing damaged Russian/Hebrew regex text with a tested shared `search_intent` module.
- Connected the Flutter search screen to backend search for signed-in users while preserving the local search fallback.
- Changed raw text capture to invoke `process-item` so text notes can become semantic memory items with summaries, chunks, entities, aliases, and embeddings.
- Hardened item detail JSON list handling so AI-produced `ingredients`, `steps`, `cast`, and `specs` do not crash when decoded as generic JSON arrays.
- Added `manual` as a real item type in Supabase, Flutter, link/text extraction, image analysis classification, feed cards, localization, and search intent inference.
- Manual/how-to items use the interactive steps detail layout with editable generated content, and Russian/Hebrew/English manual queries are covered by Deno tests.

## Verified

- The app has launched on a physical Samsung Android phone.
- Android share-sheet link/text intake into Dualio works on the physical phone.
- Email magic-link callback opens Dualio on the physical Android phone after the routing fix.
- Shared images upload to Cloudflare R2 and persist asset metadata in Supabase.
- `process-item` Edge Function with image-processing path has been deployed to Supabase.
- Reddit resolver behavior has been manually verified against concrete Reddit short links that expand to `An open letter to Anthropic`.
- `flutter analyze` passes after link/text extraction changes.
- `flutter test` passes after link/text extraction changes.
- Deno resolver/enrichment tests pass through `npx deno-bin`.
- Deno resolver tests cover schema.org Recipe JSON-LD extraction.
- Deno embedding tests pass through `npx deno-bin`.
- Deno OpenRouter adapter tests pass through `npx deno-bin`.
- Deno search-intent tests pass for Russian, Hebrew, and English item-type hints, including manual/how-to intent.
- `deno check` passes for `process-item`, `search`, `semantic_extraction`, embeddings, and link enrichment modules through `npx deno-bin`.

## Not Yet Verified

- The newest launcher icon change has been installed on the physical phone, but visual confirmation on the launcher has not yet been reported.
- End-to-end signed-in state and remote item insert still need to be verified after the successful callback.
- End-to-end social-link processing still needs repeated Android smoke tests after each resolver change: share link -> confirm -> pending item -> Edge Function metadata -> ready card.
- End-to-end backend search needs smoke tests with real processed rows and OpenRouter-generated embeddings.
- Cross-lingual semantic search needs real examples validated after embeddings are generated in Supabase.
- Google sign-in has not yet been tested with real Supabase credentials.
- Apple sign-in has not yet been tested with real Supabase credentials and Apple Developer configuration.
- Add/feed remote item flow has been built but not yet verified with a signed-in Supabase user.
- Supabase CLI is available through `npx supabase`; access token is present locally in `.env.local`.
- Supabase anon key is present locally in `.env.local`; it must not be committed.
- Google sign-in requires Supabase anon key via `--dart-define`, Google provider configuration in Supabase, and `dualio://auth/callback` in the Supabase redirect allow-list.
- Apple sign-in requires Apple provider configuration in Supabase, Apple Developer capability/signing setup, and `dualio://auth/callback` in the Supabase redirect allow-list.
- iOS follow-up work is tracked in `roadmap.md`: camera/photo permissions, Share Extension, HEIC optimization, temporary share-file access, Apple Sign-In verification, and App Store privacy labels.
- `OPENROUTER_API_KEY` is present in Supabase Function secrets. Link/text/image AI extraction and embeddings now use OpenRouter first; direct OpenAI remains only as a temporary fallback if `OPENAI_API_KEY` is also configured.

## Current Blockers

- `rg` failed with access denied, so PowerShell search was used instead.
- Visual Studio for Windows desktop builds is not installed/detected; this is not a blocker for Android.

## Immediate Next Tasks

1. Smoke-test R2 lifecycle flows on Android: upload image, delete item, verify R2 object cleanup, delete account, verify user data cleanup.
2. Smoke-test content flows: Reddit link, Facebook/TikTok link, WhatsApp image, raw text, Russian query for English content, Hebrew RTL query.
3. Add search-quality fixtures for cross-lingual examples and debug match reasons.
4. Add reranking once the first hybrid search path has real test data.
5. Add account-level free-tier hard limits as final pre-public-launch hardening.

## Future Backlog Notes

- `roadmap.md` now contains a Future Source Resolver Backlog covering social/video, shopping, maps/places, articles, recipes, media/books, developer/knowledge, local marketplaces, and travel/events sources.
- Resolver backlog should be implemented as official API/oEmbed/OpenGraph first, with optional non-blocking enrichment as a second stage.

## Files New Agents Should Read First

1. `PROJECT_STATUS.md`
2. `AGENTS.md`
3. `CLAUDE.md`
4. `roadmap.md`
5. `design/DESIGN.md`
6. `design/code.html`
7. `design/screen.png`
8. `legal/TERMS_PRIVACY_NOTES.md`
