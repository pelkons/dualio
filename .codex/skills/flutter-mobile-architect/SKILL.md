---
name: flutter-mobile-architect
description: Flutter mobile architecture for Dualio. Use when Codex creates, edits, reviews, or plans Flutter/Dart mobile code for Dualio, including project structure, navigation with go_router, state with Riverpod, generated models, native Android/iOS readiness, capture flows, share intents, camera/photo handling, and mobile-first app architecture.
---

# Flutter Mobile Architect

Use this skill to keep Dualio's Flutter codebase native-mobile, typed, and maintainable.

## Workflow

1. Read `roadmap.md`, `pubspec.yaml`, `analysis_options.yaml`, and the relevant `lib/` feature files first.
2. Preserve the existing feature-first structure:
   - `lib/core/` for routing, theme, localization, shared infrastructure.
   - `lib/features/<feature>/domain` for models and pure domain types.
   - `lib/features/<feature>/presentation` for screens/widgets.
   - `lib/mock/` for mock semantic items until backend wiring is intentionally added.
3. Use `go_router` for navigation and Riverpod for app state.
4. Use `freezed` and `json_serializable` for immutable network/domain models when data crosses a boundary.
5. Keep UI backed by typed semantic memory models, not generic unstructured cards.
6. Do not connect mock UI to Supabase unless the task explicitly asks for backend integration.
7. Prefer small widgets with clear responsibilities over large screens with embedded business logic.

## Mobile Rules

- Build for Android first while keeping iOS-compatible APIs and layout assumptions.
- Treat web preview only as a debugging aid.
- Use platform packages deliberately: `image_picker`, `receive_sharing_intent`, haptics, Supabase auth/deep links.
- Keep permissions, share intents, camera/photo flows, and native wrappers in scope when implementing capture features.
- Use optimistic UI for item creation and model processing states explicitly.

## Validation

Run, when available:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

If Flutter is unavailable, state that clearly and validate with static file inspection.
