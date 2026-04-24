# Dualio Project Status

Last updated: 2026-04-24

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

Dualio is in early foundation stage.

The project has a Flutter-first mobile scaffold, mock semantic feed, mock capture/search flows, RAG-first Supabase schema, project-level Codex skills, and Claude agent instructions. Flutter and Android tooling are installed and the Android debug APK builds successfully.

## Completed

- Read and preserved the design source files in `design/`.
- Created Flutter project structure manually.
- Added strict Dart analysis settings.
- Added Flutter dependencies in `pubspec.yaml`.
- Added localization setup for English, Hebrew, Russian, Italian, French, Spanish, and German.
- Built design tokens, light/dark theme, typography, top header, search pill, bottom navigation, and floating add button.
- Added mock semantic items for all 8 item types.
- Added compact feed cards for article, recipe, film, place, product, video, note, and unknown.
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

## Verified

- The app has launched on a physical Samsung Android phone.
- Android share-sheet link/text intake into Dualio works on the physical phone.
- Email magic-link callback opens Dualio on the physical Android phone after the routing fix.

## Not Yet Verified

- Image/screenshot share intake has not yet been tested on the physical phone.
- The newest launcher icon change has been installed on the physical phone, but visual confirmation on the launcher has not yet been reported.
- End-to-end signed-in state and remote item insert still need to be verified after the successful callback.
- End-to-end link processing needs to be tested from the Android app after sign-in: save link -> pending item -> Edge Function metadata -> ready card.
- Google sign-in has not yet been tested with real Supabase credentials.
- Apple sign-in has not yet been tested with real Supabase credentials and Apple Developer configuration.
- Add/feed remote item flow has been built but not yet verified with a signed-in Supabase user.
- Supabase CLI is available through `npx supabase`; access token is present locally in `.env.local`.
- Supabase anon key is present locally in `.env.local`; it must not be committed.
- Google sign-in requires Supabase anon key via `--dart-define`, Google provider configuration in Supabase, and `dualio://auth/callback` in the Supabase redirect allow-list.
- Apple sign-in requires Apple provider configuration in Supabase, Apple Developer capability/signing setup, and `dualio://auth/callback` in the Supabase redirect allow-list.

## Current Blockers

- `rg` failed with access denied, so PowerShell search was used instead.
- Visual Studio for Windows desktop builds is not installed/detected; this is not a blocker for Android.

## Immediate Next Tasks

1. Run the newest build on the connected Samsung phone.
2. Smoke-test sharing an image/screenshot into Dualio.
3. Configure Supabase Auth redirect URL `dualio://auth/callback` in the Dashboard.
4. Smoke-test magic-link sign-in on Android.
5. Smoke-test Add text/link -> Supabase pending item -> Feed remote read.

## Files New Agents Should Read First

1. `PROJECT_STATUS.md`
2. `AGENTS.md`
3. `CLAUDE.md`
4. `roadmap.md`
5. `design/DESIGN.md`
6. `design/code.html`
7. `design/screen.png`
8. `legal/TERMS_PRIVACY_NOTES.md`
