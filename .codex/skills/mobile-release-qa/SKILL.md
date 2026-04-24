---
name: mobile-release-qa
description: Mobile release readiness and QA for Dualio. Use when Codex prepares, reviews, or debugs Android/iOS build configuration, permissions, app icons, splash screens, CI, analyzer/test gates, generated code drift, crash reporting, privacy/account lifecycle requirements, Play Store internal testing, and production hardening.
---

# Mobile Release QA

Use this skill when moving Dualio from development toward test builds or release.

## Build Readiness

- Verify Android package name and iOS bundle identifier.
- Check camera, photo library, notification, share extension, and deep link permissions.
- Ensure generated files are current.
- Keep Flutter, Dart SDK, Gradle, Kotlin, CocoaPods, and Xcode constraints explicit.
- Do not commit build artifacts.

## Quality Gates

Run when available:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

Add CI gates for analyzer, tests, generated-code drift, and migration checks.

## Product Readiness

- Add privacy policy and terms links before external testing.
- Add account deletion and export flows.
- Add crash reporting before beta.
- Verify RLS and signed media access before real user data.
- Keep subscription seam separate from paywall implementation until explicitly requested.

## Reporting

When QA fails, report exact command, failure summary, affected file/config, and next fix.
