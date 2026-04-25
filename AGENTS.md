# Dualio Agent Instructions

These instructions apply to all AI coding agents working in this repository.

## Product Context

Dualio is a native mobile app for Android and iOS. The first production target is Android.

Dualio is a single AI-first inbox for anything a user wants to save for later:

- Links
- Screenshots
- Photos
- Raw text

The app must be treated as a personal semantic memory / RAG system, not as a generic card feed. Search quality is the core product value.

## Required Reading

Before significant work, read:

- `roadmap.md`
- `design/DESIGN.md`
- `design/code.html`
- `design/screen.png`
- `pubspec.yaml`
- `analysis_options.yaml`
- Relevant files under `lib/` and `supabase/`

## Communication And Language

- Communicate with the user in Russian.
- Code, filenames, code comments, and user-facing app strings must be in English unless the user explicitly asks otherwise.
- User-facing strings must go through Flutter localization files.

## Attribution And Git Rules

- Never add AI agents, Codex, Claude, OpenAI, Anthropic, or assistant names as co-authors, contributors, maintainers, copyright holders, or credits.
- Never add `Co-Authored-By`, `Generated-By`, `Assisted-By`, or similar AI attribution trailers to commits, PR text, changelogs, docs, or metadata.
- Do not describe yourself as the user's co-author.
- If asked to prepare commit messages, keep them conventional and project-focused with no AI attribution.
- The project owner is the user unless the user explicitly provides another owner identity.

## Stack

Mobile client:

- Flutter latest stable
- Dart strict analysis
- Material 3 as technical foundation only
- Custom visual system from `design/`
- `go_router`
- `flutter_riverpod`
- `freezed` + `json_serializable`
- Flutter `gen-l10n`
- Supabase client packages

Backend:

- Supabase Postgres/Auth/Realtime/Edge Functions/RLS
- `pgvector`
- OpenAI API for parsing, extraction, embeddings, and reranking
- Cloudflare R2 for uploaded images
- R2 access only through signed URLs from backend code

## Architecture Rules

- Keep the app mobile-first and native-oriented.
- Do not build a web app.
- After every completed implementation, explicitly check whether the behavior also works on iOS. If the change is Android-only or may need different iOS handling, either implement the iOS path in the same task or add a concrete follow-up item to `ios/IOS.md` before finishing.
- All iOS-specific tasks, decisions, and working notes belong in `ios/IOS.md`. Read that file before starting any iOS work, and append to it (do not put iOS-specific items in `roadmap.md`).
- Use feature-first Flutter structure.
- Keep domain models strongly typed.
- Use immutable generated models when data crosses boundaries.
- Do not duplicate business logic between screens.
- Do not connect the feed to Supabase until the mock feed visually matches the design.
- Do not add paywall, social features, folders, or manual tags unless explicitly requested.

## UI Rules

- Follow `design/screen.png` and `design/DESIGN.md`.
- Preserve the editorial monochrome premium visual system.
- Use Noto Serif for editorial titles and Manrope for body/interface text.
- Support light and dark themes from day one.
- Use soft shadows, generous whitespace, and 14px rounded cards.
- Preserve the top header, search pill, bottom navigation, and floating add button patterns.
- Keep Hebrew RTL layout in mind for directional spacing and alignment.

## RAG And Search Rules

- Model saved content as semantic memory.
- Core tables: `profiles`, `items`, `item_chunks`, `item_entities`, `search_events`.
- Search must be hybrid: item vectors, chunk vectors, full text, aliases, entities, recency/context boosting, and reranking.
- Cross-lingual search must work across English, Hebrew, Russian, Italian, French, Spanish, and German.
- Keep internal match reasons available for debugging search quality.

## Security Rules

- Enable and preserve strict RLS for all user data.
- Users can only read/write their own data.
- Never expose service role keys to the Flutter client.
- Treat signed media access as backend-only.

## Validation

Run when available:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

If Flutter or Dart is unavailable, state that clearly and validate with static inspection.

## Project Skills

Project-level Codex skills are stored in `.codex/skills/`. Prefer them when the task matches their scope.
