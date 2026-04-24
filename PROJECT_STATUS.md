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
- Replaced the settings placeholder with theme controls plus account/subscription sections.
- Moved app language selection out of in-app Settings and into Android per-app language settings via `android:localeConfig`.
- Added Android share-sheet support for shared links/text and images through `ACTION_SEND` and `ACTION_SEND_MULTIPLE`.
- Added Flutter share intake listener using `receive_sharing_intent`; incoming shares create local pending semantic items.
- Verified on physical Samsung phone that sharing from another Android app into Dualio works.
- Added Supabase migration for profiles, items, item_chunks, item_entities, search_events, RLS, indexes, pgvector, and hybrid search RPC.
- Added Edge Function contracts for `process-item` and `search`.
- Created `roadmap.md`.
- Installed project-level skills in `.codex/skills/`.
- Added Claude project context in `CLAUDE.md`.
- Added Claude subagents in `.claude/agents/`.
- Renamed app identity from Embera to Dualio.
- Connected Git remote `origin` and completed the first GitHub push.
- Installed Flutter stable at `C:\Users\plkns\dev\flutter`.
- Installed Android command-line tools and accepted Android SDK licenses.
- Generated Android/iOS Flutter wrappers with `flutter create`.
- Ran `flutter pub get`.
- Generated Flutter localization files.
- Generated Freezed/json_serializable files.
- Ran `flutter analyze` successfully.
- Added a Flutter smoke test and ran `flutter test` successfully.
- Built Android debug APK successfully at `build\app\outputs\flutter-apk\app-debug.apk`.

## Not Yet Verified

- Android app has not been launched.
- The app has launched on a physical Samsung Android phone.
- The newest auth/settings changes have not yet been re-run on the physical phone.
- Google sign-in requires Supabase credentials via `--dart-define`, Google provider configuration in Supabase, and `dualio://auth/callback` in the Supabase redirect allow-list.

## Current Blockers

- `rg` failed with access denied, so PowerShell search was used instead.
- Visual Studio for Windows desktop builds is not installed/detected; this is not a blocker for Android.

## Immediate Next Tasks

1. Run the newest build on the connected Samsung phone.
2. Smoke-test sharing an image/screenshot into Dualio.
3. Smoke-test feed, capture, search, settings, and sign-in-not-configured state.
4. Tune non-design UX issues discovered on device.
5. Commit the current Flutter/Dualio scaffold and push it to GitHub.

## Files New Agents Should Read First

1. `PROJECT_STATUS.md`
2. `AGENTS.md`
3. `CLAUDE.md`
4. `roadmap.md`
5. `design/DESIGN.md`
6. `design/code.html`
7. `design/screen.png`
