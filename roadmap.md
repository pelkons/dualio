# Dualio Roadmap

Dualio is a native mobile app for Android and iOS. The first production target is Android.

The product is a single AI-first inbox for anything a user wants to save for later: links, screenshots, photos, and raw text. Under the UI, Dualio is a personal semantic memory system with hybrid multilingual search as the core feature.

## Product Principles

- Mobile-first native experience.
- Android first, iOS second, shared Flutter codebase.
- Premium editorial visual system based on `design/`.
- Search is the primary navigation and retrieval experience.
- Saved items are semantic memory objects, not generic cards.
- Mock-first UI until feed quality matches the design.
- Backend access must be secure by default with strict RLS.
- Cross-lingual search must work across English, Hebrew, Russian, Italian, French, Spanish, and German.

## Current Status

- Flutter project scaffold exists.
- Design tokens, light/dark themes, typography, feed shell, search bar, bottom navigation, and floating add button exist.
- Mock semantic feed exists for all 8 supported item types.
- Compact feed cards exist for article, recipe, film, place, product, video, note, and unknown.
- Type-specific detail placeholders exist.
- Localization files exist for all target languages.
- Supabase migration exists for the RAG-first schema.
- Edge Function contracts exist for `process-item` and `search`.
- Feed is intentionally not connected to Supabase yet.

## Phase 1: Mobile Foundation

Goal: make the Flutter app build, run, and feel like the design on Android.

- Generate native Android/iOS project wrappers with Flutter.
- Run `flutter pub get`.
- Generate localization files.
- Generate Freezed and JSON serialization files.
- Fix analyzer issues after code generation.
- Add a small widget smoke test.
- Validate feed layout on common Android sizes.
- Tune spacing, card heights, dark theme, and text overflow.
- Replace temporary remote image choices where they do not match the design quality.

Definition of done:

- `flutter analyze` passes.
- `flutter test` passes.
- `flutter run -d android` opens the mock feed.
- Feed visually matches `design/screen.png` closely enough to proceed.

## Phase 2: Capture UX

Goal: make saving feel immediate before backend processing exists.

- Build add/capture screen.
- Support paste link.
- Support raw text.
- Support photo library.
- Support camera.
- Add optimistic pending item state.
- Add save success haptic tick.
- Add error and retry states.
- Add first pass share intent handling on Android.
- Add share extension instructions in settings.

Definition of done:

- User can create local pending mock items from all capture paths.
- UI reflects `pending`, `processing`, `ready`, `needs_clarification`, and `failed`.
- Capture flow does not require Supabase to feel usable.

## Phase 3: Auth And Supabase Integration

Goal: connect the app to Supabase without changing the feed design.

- Configure Supabase environment values.
- Implement email magic link sign-in.
- Create profile on first sign-in.
- Add authenticated session routing.
- Insert raw pending items into `items`.
- Read newest-first feed from Supabase.
- Preserve optimistic UI behavior.
- Add signed URL contract for images.
- Verify RLS policies manually and with SQL tests.

Definition of done:

- Users only see their own data.
- Signed-out users cannot access private data.
- Captured items persist in Supabase.
- Feed still matches the mock design.

## Phase 4: Processing Pipeline MVP

Goal: process saved inputs into typed semantic memory items.

- Implement idempotent `process-item` Edge Function.
- Fetch and normalize URLs.
- Extract HTML metadata.
- OCR screenshots/photos.
- Detect item type with OpenAI.
- Extract type-specific structured fields.
- Generate user-visible summary.
- Extract entities.
- Generate searchable aliases and synonyms.
- Generate multilingual/cross-lingual search hints.
- Split item into semantic chunks.
- Generate item and chunk embeddings.
- Upload derived images/thumbnails to R2.
- Store R2 metadata and issue signed URLs.
- Mark item ready or `needs_clarification`.
- Log every stage.

Definition of done:

- One saved URL can become a ready article card.
- One saved screenshot/photo can become a ready or clarification item.
- Failed processing is retry-safe.
- Processing logs are useful for debugging.

## Phase 5: Hybrid Semantic Search

Goal: make search the core product experience.

- Build search screen UI.
- Embed user queries.
- Infer likely item type when useful.
- Search item-level embeddings.
- Search chunk-level embeddings.
- Search full text.
- Search entities.
- Search aliases/synonyms.
- Add recency and context boosting.
- Add reranking.
- Return top 20.
- Store search events.
- Add internal match reasons for debugging.
- Validate cross-lingual examples.

Definition of done:

- Searching in Russian can retrieve relevant English content.
- Searching in Hebrew works with RTL UI.
- Search results explain internally why they matched.
- Search is faster and more useful than scrolling.

## Phase 6: Detail Screens

Goal: make every item type useful after opening.

- Recipe detail: hero image, ingredients with checkboxes, steps, source link.
- Film/show detail: poster, year, director, rating, synopsis, cast, watch links.
- Place detail: map preview, address, venue type, hours, notes, source link.
- Article detail: reading view, author, read time, cleaned body, source link.
- Product detail: image, price, specs, store/source link.
- Video detail: thumbnail, title, channel, duration, deep link placeholder.
- Note detail: cleaned free text.
- Unknown detail: raw content and clarification state.

Definition of done:

- Each detail screen has a distinct layout.
- Parsed content is readable and actionable.
- Source attribution is always available when present.

## Phase 7: Internationalization And Accessibility

Goal: make localization and accessibility first-class.

- Complete real translations for all strings.
- Audit for hardcoded user-facing strings.
- Add RTL layout validation for Hebrew.
- Add dynamic text size checks.
- Add semantic labels for icon-only controls.
- Check contrast in light and dark themes.
- Add locale and theme settings.

Definition of done:

- App works in all target locales.
- Hebrew layout is usable in RTL.
- No user-facing strings are hardcoded in widgets.

## Phase 8: Production Readiness

Goal: prepare Android beta.

- Add app icons and splash.
- Configure Android package name.
- Configure permissions for camera, photos, and sharing.
- Add crash reporting.
- Add privacy policy and terms links.
- Add export flow.
- Add account deletion flow.
- Add backup and data retention policy.
- Add basic subscription seam without paywall.
- Harden Edge Function limits and retries.
- Add database migration checks.
- Add CI for analyze, tests, and generated code drift.

Definition of done:

- Android internal testing build is ready.
- Core capture, processing, and search flows work end to end.
- Privacy and account lifecycle requirements are covered.

## Not In Scope Yet

- Paywall implementation.
- Social features.
- Web version.
- Folders.
- Manual tags.
- Full collaborative sharing.

## Immediate Next Tasks

1. Install Flutter latest stable locally.
2. Run `flutter create --platforms=android,ios --project-name dualio .`.
3. Run `flutter pub get`.
4. Run `flutter gen-l10n`.
5. Run `dart run build_runner build --delete-conflicting-outputs`.
6. Run `flutter analyze` and fix generated-code integration issues.
7. Run the Android app and tune feed visuals against `design/screen.png`.
