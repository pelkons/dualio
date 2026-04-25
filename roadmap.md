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
- Cost controls are a core product constraint: the free tier must not allow unbounded AI processing, media storage, or lifetime storage of abandoned user data.

## Free Tier And Retention Guardrails

Initial free tier:

- Allow 10 saved memories total per free account.
- Limit free image/photo/screenshot items to 3 total.
- Limit free processing attempts to 20 total.
- Limit free image OCR/vision attempts to 3 total.
- Enforce a maximum upload size before writing to R2.
- Keep thumbnails and extracted searchable text while the item exists.
- Expire original full-resolution images after a defined retention window, starting with 30 days for free accounts.
- Delete failed, abandoned, or orphaned pending uploads with a scheduled cleanup job.
- Delete all Postgres rows and R2 objects when a user deletes an item or account.
- Check limits in backend code before uploading media to R2 or starting AI processing.

Required accounting fields:

- Track plan, saved item count, processing attempt count, image processing attempt count, and media storage bytes per user.
- Store R2 object keys with user/item prefixes so backend cleanup can reliably delete media for one item or account.

## Current Status

- Flutter project scaffold exists and builds for Android.
- Design tokens, light/dark themes, typography, feed shell, search bar, bottom navigation, and floating add button exist.
- The app is connected to Supabase for authenticated item persistence and newest-first feed reads.
- Compact feed cards exist for article, recipe, film, place, product, video, manual, note, and unknown.
- Type-specific detail placeholders exist.
- Localization files exist for all target languages.
- Supabase migration exists for the RAG-first schema.
- Edge Function contracts exist for `process-item` and `search`; `process-item` is implemented for link/text/image semantic extraction with safe fallback behavior.
- Android share intake opens a confirmation screen before saving and supports links, text, photos, and screenshots.
- Cloudflare R2 stores user-uploaded image assets through signed URLs.
- Mobile photo/screenshot uploads are optimized on-device before R2 upload, and signed upload URL creation enforces declared image byte-size limits.
- R2 cleanup is modeled with `asset_cleanup_jobs`; item deletion, account deletion, and scheduled abandoned-upload cleanup have dedicated Edge Functions deployed to Supabase.
- The scheduled `dualio-cleanup-assets-hourly` Postgres cron job invokes `cleanup-assets` every hour with `CLEANUP_ASSETS_SECRET`.
- Settings includes a signed-in account deletion flow that calls backend cleanup before removing the auth user.
- Link processing resolves public metadata through platform-specific paths and OpenGraph/oEmbed fallback, then runs typed semantic extraction for supported link/text inputs, including manual/how-to instructions.
- Reddit short-share links now expand to canonical posts and can extract title, self text, author, subreddit, score, comments, and preview metadata.
- Recipe links with schema.org Recipe JSON-LD can extract ingredients, steps, timing, yield, image, author, and rating before AI semantic extraction runs.
- Image/photo/screenshot processing now routes vision analysis through OpenRouter when `OPENROUTER_API_KEY` is configured, with a temporary direct OpenAI fallback.
- Public HTML enrichment is split into general unofficial enrichment and a separate social HTML opt-in flag so social platforms remain disabled by default unless explicitly enabled.
- Processing now generates item-level and chunk-level embeddings through OpenRouter when `OPENROUTER_API_KEY` is configured, using `openai/text-embedding-3-small` by default to preserve the current `vector(1536)` schema.
- The `search` Edge Function now performs first-pass hybrid search with query embeddings, the existing `match_semantic_items` RPC, and lexical fallback when embeddings/RPC are unavailable.
- Search intent inference for Russian and Hebrew queries is covered by Deno tests.
- The Flutter search screen calls backend search for signed-in users and preserves local search fallback.

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
- Resolve social links through official oEmbed/API or OpenGraph first; public HTML enrichment for social platforms must stay opt-in and disabled by default.
- Extract HTML metadata.
- OCR screenshots/photos.
- Detect item type with the configured AI router.
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

Current implementation note:

- Link processing resolves public metadata and optional enrichment. Reddit currently has the strongest resolver path: short-link expansion, JSON extraction, oEmbed fallback, and preview thumbnail fallback.
- Generic recipe sites are checked for schema.org Recipe JSON-LD and pass structured recipe data into AI extraction.
- Public HTML enrichment for social platforms requires `ENABLE_SOCIAL_HTML_ENRICHMENT=true` in addition to the general `ENABLE_UNOFFICIAL_LINK_ENRICHMENT=true` flag.
- Link/text processing calls an OpenRouter structured-output adapter first, with `provider.require_parameters=true` so providers cannot ignore JSON schema output. It stores typed `parsed_content`, user-facing summary, aliases, entities, and chunks, and falls back safely when AI credentials are absent or unavailable.
- Image/photo/screenshot processing reads Cloudflare R2 asset metadata, signs a temporary GET URL, calls OpenRouter vision analysis first, stores parsed image summary/visible text, writes chunks/entities, and falls back safely when vision credentials are missing.
- Item and chunk embeddings are generated best-effort with `openai/text-embedding-3-small` through OpenRouter by default. Missing or failed embedding generation does not fail item processing.
- Hybrid semantic search backend and Flutter integration exist as a first pass. Reranking and deeper search-quality evaluation are still pending.

### Future Source Resolver Backlog

Dualio should expect users to save links from many app categories. Resolver support should be added incrementally, with official APIs/oEmbed/OpenGraph first, and optional enrichment only as a non-blocking second stage.

Priority source groups:

- Social/video: TikTok, Instagram, Facebook, YouTube, X/Twitter, Reddit, Pinterest, Threads, Snapchat Spotlight, LinkedIn, Telegram public posts/channels.
- Shopping/marketplaces: Amazon, eBay, AliExpress, Temu, SHEIN, Etsy, Walmart, Target, Best Buy, Wayfair, IKEA, Home Depot, Zara, H&M.
- Maps/places/travel: Google Maps, Apple Maps, Waze, TripAdvisor, Yelp, Booking.com, Airbnb, Google Travel/Hotels.
- Articles/read-later: Medium, Substack, NYTimes, WSJ, Guardian, BBC, CNN, local news, Wikipedia, Hacker News, Product Hunt.
- Food/recipes: Allrecipes, NYT Cooking, Tasty, Food Network, Serious Eats, restaurant sites, Uber Eats, DoorDash, Wolt, Deliveroo, Grubhub.
- Media/books: Spotify, Apple Music, SoundCloud, YouTube Music, Goodreads, Amazon Books/Kindle links, IMDb, Letterboxd, Rotten Tomatoes, Netflix, Prime Video, Disney+, Apple TV.
- Developer/knowledge: GitHub, GitLab, Stack Overflow, npm, pub.dev, arXiv, Google Scholar, Hugging Face, Notion public pages, Google Docs/Sheets public links.
- Local marketplaces: Facebook Marketplace, Craigslist, OfferUp, Vinted, Depop, Poshmark, Mercari, Yad2, Gumtree, OLX, Mercado Libre, Shopee, Lazada, Coupang, Rakuten.
- Later/community/events: Twitch clips, Discord public links, Bluesky, Mastodon, Tumblr, Quora, Behance, Dribbble, DeviantArt, Expedia, Skyscanner, Kayak, Google Flights, Eventbrite, Meetup, Ticketmaster, OpenTable, TheFork, Resy.

Resolver families to build:

- `oembed_resolver`
- `opengraph_resolver`
- `schema_org_product_resolver`
- `schema_org_recipe_resolver`
- `schema_org_place_resolver`
- `marketplace_resolver`
- `maps_resolver`
- `fallback_resolver`

Suggested implementation order:

1. TikTok, YouTube, X/Twitter, Reddit, Pinterest.
2. Instagram/Facebook with Meta token plus OpenGraph fallback.
3. Amazon, eBay, AliExpress, Temu, Etsy.
4. Google Maps, Booking.com, Airbnb, TripAdvisor.
5. Recipe and article sites.

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

## iOS Follow-Up Backlog

Goal: keep iOS-specific work explicit while Android remains the first production target.

- Configure iOS `Info.plist` usage descriptions for camera and photo library access.
- Configure iOS URL scheme/deep link handling for `dualio://auth/callback`.
- Configure and test Sign in with Apple entitlement and Supabase Apple provider.
- Build a native iOS Share Extension for sharing links, text, photos, and screenshots into Dualio.
- Verify `receive_sharing_intent` behavior with Safari, Photos, Instagram, TikTok, Facebook, and Notes.
- Verify temporary file access from iOS share/capture flows before upload starts.
- Add native HEIC-to-JPEG conversion if Dart image decoding cannot optimize iPhone HEIC files.
- Smoke-test on a real iPad and at least one iPhone simulator/device before iOS beta.
- Review iOS background/upload behavior so shared files are uploaded or safely retained before the app is suspended.
- Confirm App Store privacy labels and permission prompts match actual data collection.

## Not In Scope Yet

- Paywall implementation.
- Social features.
- Web version.
- Folders.
- Manual tags.
- Full collaborative sharing.

## Immediate Next Tasks

1. Smoke-test R2 lifecycle flows on Android: upload image, delete item, verify R2 object cleanup, delete account, verify user data cleanup.
2. Smoke-test Android content flows after AI processing/search is enabled: Reddit link, Facebook/TikTok link, WhatsApp image, raw text, Russian query for English content, and Hebrew RTL query.
3. Add search-quality fixtures for cross-lingual examples and debug match reasons.
4. Add reranking once the first hybrid search path has real test data.
5. Add account-level free-tier hard limits as final pre-public-launch hardening.
