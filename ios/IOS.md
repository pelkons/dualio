# iOS Backlog & Working Notes

This file tracks every iOS-specific decision, gap, and follow-up for Dualio.
Android is the first production target, but each Android-only feature must
have a matching iOS plan recorded here so the gap is explicit.

When working on iOS, **read this file first**, and **append to it** any new
iOS-specific finding, decision, or task — do not let iOS notes drift into
`roadmap.md` or random PR descriptions.

## Definition of done for iOS internal beta

- The app **builds and signs** for iOS device targets via `flutter build ios`
  and Xcode archive without warnings about missing entitlements, privacy keys,
  or icons.
- A user can **launch**, **sign in via Apple**, **sign in via Google**, **sign
  in via magic link**, **share a link / image / text from another app into
  Dualio**, **paste clipboard image into the capture flow**, and **see the
  feed** on a real iPhone running the latest stable iOS.
- All native permission prompts (camera, photo library) appear in the user's
  device language, not English-only.
- App Store review is unblocked: Privacy Manifest present, encryption
  declaration set, all required `NS*UsageDescription` keys present, app icon
  filled out for every required size.

## Critical for App Store

- **Add `PrivacyInfo.xcprivacy`** to `ios/Runner/`. Apple rejects builds
  without it since Spring 2024. Must declare collected data categories,
  tracking domains, and required-reason API usage. Cross-check the
  declarations with the same data inventory used for the Privacy Policy.
- **Rename Bundle ID** away from the placeholder `com.example.dualio`. Pick a
  production identifier (e.g. `app.dualio.ios`) and update
  `ios/Runner.xcodeproj/project.pbxproj` plus any provisioning profile
  references.
- **Add `NSCameraUsageDescription`** to `ios/Runner/Info.plist`. Without it
  the app crashes the first time `image_picker` opens the camera.
- **Add `NSPhotoLibraryUsageDescription`** to `ios/Runner/Info.plist`. Same
  reasoning for photo library access from `image_picker` and from
  `receive_sharing_intent` photo flows.
- **Add `NSPhotoLibraryAddUsageDescription`** if/when the export flow ever
  writes to the camera roll.
- **Set `ITSAppUsesNonExemptEncryption=false`** in `ios/Runner/Info.plist`.
  We use only Apple-provided HTTPS, so the export-compliance step in App
  Store Connect should be skippable.
- **Configure App Store privacy labels** to match the actual data collected
  (email for auth, item content + media for processing, no advertising
  identifiers). Mirror the wording with `landing/src/pages/privacy.astro`.

## Native parity with Android

Each item lists the existing Android implementation so the iOS path can be
matched intentionally rather than reinvented.

- **Sign in with Apple — Supabase provider**. The
  `com.apple.developer.applesignin` entitlement is already in
  `ios/Runner/Runner.entitlements`, and the Flutter UI in
  `lib/features/auth/presentation/sign_in_screen.dart` already shows the
  Apple button on iOS. The remaining work is configuring the Supabase Apple
  provider with the App ID, Service ID, key, and team ID, and verifying the
  redirect path against the existing `dualio://auth/callback` deep link.
- **`receive_sharing_intent` Share Extension**. Android registers SEND and
  SEND_MULTIPLE intents in `android/app/src/main/AndroidManifest.xml`. iOS
  has no equivalent without a native Share Extension target. Build one in
  Xcode under `ios/`, follow `receive_sharing_intent` README for the App
  Group identifier, and verify with shares from Safari, Photos, Instagram,
  TikTok, Facebook, WhatsApp, and Notes.
- **`PROCESS_TEXT` action**. Android registers
  `android.intent.action.PROCESS_TEXT` so users can save selected text from
  any app. iOS equivalent is an Action Extension target — separate from the
  Share Extension. Add as a follow-up after the Share Extension ships.
- **Clipboard image bridge — keep the same MethodChannel name**. Android
  uses `dualio/clipboard` in
  `android/app/src/main/kotlin/com/example/dualio/MainActivity.kt`, with
  `readClipboard` returning `{type: 'image' | 'text' | ...}`. The Swift side
  in `ios/Runner/AppDelegate.swift` (or a dedicated handler file) must
  register the same channel name and the same return shape so
  `lib/features/capture/application/clipboard_intake_service.dart` does not
  need any platform-specific Dart change.
- **HEIC handling**. iPhone photos default to HEIC. If the on-device image
  optimizer or the Dart `image` package cannot decode HEIC, add a native
  HEIC-to-JPEG conversion step on the Swift side before handing the path to
  Flutter.
- **Background/upload behavior**. iOS suspends apps quickly. Android's
  share/capture flow can rely on the OS keeping the process alive. On iOS,
  shared files must be uploaded with `URLSession` background tasks, or
  buffered to local storage with a clear retry strategy on next foreground.

## Brand & launch screen

- **Run `dart run flutter_launcher_icons`** to generate
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` from `design/icon.png`.
  Verify all required sizes are populated; commit the result.
- **Replace the default Flutter launch screen**. `LaunchScreen.storyboard`
  ships with the Flutter logo. Replace with Dualio icon centred on the
  brand cream background `#FDF8F8` to match the in-app surface and the
  landing page hero.
- **Set `CFBundleDisplayName=Dualio`** (already correct) and verify
  `CFBundleName` reads as expected on the home screen icon long-press.

## Locale & accessibility

- **Add `CFBundleLocalizations`** to `ios/Runner/Info.plist` listing
  `en, ru, he, it, fr, es, de`. Without this, native iOS permission prompts
  appear only in English regardless of the user's device language.
- **Add `ios/Runner/<lang>.lproj/InfoPlist.strings`** files for each locale
  with translated `NS*UsageDescription` strings. Keep the wording aligned
  with the in-app `lib/core/l10n/*.arb` translations for the same context.
- **Verify Hebrew RTL** in native iOS dialogs and the Flutter UI when the
  device is set to Hebrew. Confirm right-to-left direction propagates to
  share confirmation and feed.

## Production prep

- **Configure release signing**. Set up the Apple Developer team identifier,
  provisioning profile, and signing certificate in Xcode and the Codemagic /
  CI pipeline. Mirror the TODO already present in `android/app/build.gradle`.
- **Test the deep link** `dualio://auth/callback` on a clean install. The
  `CFBundleURLTypes` entry already exists in `ios/Runner/Info.plist`, but
  Supabase OAuth redirects must round-trip back into the running app, not
  open the system browser tab.
- **Smoke-test on a real iPad and one iPhone (simulator or device)** before
  inviting any iOS beta tester. Check feed layout at iPad split widths if
  iPad is supported, otherwise lock orientation/idiom appropriately.
- **`UIBackgroundModes`** — only add the modes actually needed for R2
  uploads (likely `fetch` plus `BGProcessingTask`). Do not enable modes the
  reviewer cannot justify; App Store review will push back.

## Testing checklist before iOS beta

Before inviting a beta tester:

- Cold launch on a Hebrew-set device — UI is RTL, native dialogs are
  Hebrew.
- Share a link from Safari → Dualio Share Extension → confirm screen →
  saved item processed.
- Share a photo from Photos → Dualio Share Extension → screenshot/photo
  card processed.
- Paste an image copied from another app → Dualio capture → photo card.
- Sign in with Apple, Google, magic link — all three reach the feed.
- Sign out, kill the app, reopen — should land on the sign-in screen.
- Delete an item, delete the account — confirm R2 objects and Postgres
  rows are gone.

## Working notes

Append-only section. Add dated entries when an iOS-specific decision is
made or a non-obvious detail is discovered, so the next agent does not have
to re-derive it.
