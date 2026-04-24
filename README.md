# Dualio

Dualio is a Flutter mobile client for an AI-first semantic memory inbox. The current implementation is a native mobile scaffold with a mock editorial feed, typed item detail layouts, strict Dart analysis settings, localization files, and Supabase RAG schema contracts.

## Setup

Flutter is not installed in this workspace environment, so native platform wrappers and generated localization files should be produced locally after installing Flutter latest stable.

```bash
flutter create --platforms=android,ios --project-name dualio .
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d android
```

The feed is intentionally backed by mock semantic items until the card system visually matches the design.
