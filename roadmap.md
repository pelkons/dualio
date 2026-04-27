# Dualio Roadmap

Dualio is a native mobile app for Android and iOS. The first production target is Android.

The product is a single AI-first inbox for anything a user wants to save for later: links, screenshots, photos, and raw text. Under the UI, Dualio is a personal semantic memory system with hybrid multilingual search as the core feature.

## Product Principles

- Mobile-first native experience.
- Android first, iOS second, shared Flutter codebase.
- Premium editorial visual system based on `design/`.
- Search is the primary navigation and retrieval experience.
- Saved items are semantic memory objects, not generic cards.
- Saved items must become associative memory objects, not hard-coded category examples.
- Mock-first UI until feed quality matches the design.
- Backend access must be secure by default with strict RLS.
- Cross-lingual search must work across English, Hebrew, Russian, Italian, French, Spanish, and German.
- Cost controls are a core product constraint: the free tier must not allow unbounded AI processing, media storage, or lifetime storage of abandoned user data.

## Core Architecture: Associative Memory

The heart of Dualio is not a bookmark feed and not keyword search. A saved item must be processed as a memory object that knows what it is, why it may matter, and how a person may later remember it vaguely.

Dualio must not grow a hard-coded dictionary of examples such as breakfast, films, books, bottles, drinks, contracts, gifts, screenshots, tables, restaurants, or documents. Those are only examples of the same product principle: AI should reason associatively at save time and search time.

When processing any saved input, AI should silently reason about:

- What is this object?
- Why might a person save it?
- In what life/work context could it be useful?
- How might the user vaguely remember it months later?
- Which associations are central meaning?
- Which words are only incidental mentions?
- Which concepts should not retrieve this item?

The backend stores this as a universal `memoryProfile`, not as one-off rules. Intended shape:

- `domain`
- `objectType`
- `canonicalConcepts`
- `primaryConcepts`
- `searchIntents`
- `usageContexts`
- `facets`
- `incidentalMentions`
- `possibleRecallPhrases`
- `negativeSignals`
- `confidence`

Strong memory-profile terms may be written into aliases, chunks, and entities. Incidental mentions must stay weak, so a card is found because it is meaningfully about a concept, not merely because a word appears somewhere in the source.

Search should use an AI query planner through OpenRouter to interpret the user's memory request before hybrid retrieval. Rule-based parsing is only a cheap fallback for obvious type/date hints and must not become a hand-written ontology of every possible object or association.

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
- Capture screen uses a unified Paste action for clipboard text/URLs and Android clipboard images, with image paste routed through the existing optimized photo upload path.
- Cloudflare R2 stores user-uploaded image assets through signed URLs.
- Mobile photo/screenshot uploads are optimized on-device before R2 upload, and signed upload URL creation enforces declared image byte-size limits.
- R2 cleanup is modeled with `asset_cleanup_jobs`; item deletion, account deletion, and scheduled abandoned-upload cleanup have dedicated Edge Functions deployed to Supabase.
- The scheduled `dualio-cleanup-assets-hourly` Postgres cron job invokes `cleanup-assets` every hour with `CLEANUP_ASSETS_SECRET`.
- Settings includes a signed-in account deletion flow that calls backend cleanup before removing the auth user.
- Link processing resolves public metadata through platform-specific paths and OpenGraph/oEmbed fallback, then runs typed semantic extraction for supported link/text inputs, including manual/how-to instructions.
- Reddit short-share links now expand to canonical posts and can extract title, self text, author, subreddit, score, comments, and preview metadata.
- Recipe links with schema.org Recipe JSON-LD can extract ingredients, steps, timing, yield, image, author, and rating before AI semantic extraction runs.
- Image/photo/screenshot processing now routes vision analysis through OpenRouter when `OPENROUTER_API_KEY` is configured, with a temporary direct OpenAI fallback.
- Image/photo/screenshot processing can classify semantic item type from the visual context and extract recipe/manual structured fields such as ingredients/materials and steps instead of treating every saved image as a generic photo.
- Processing now builds a `memoryProfile` for saved links, text, photos, and screenshots with domain, object type, canonical concepts, primary concepts, search intents, usage contexts, facets, incidental mentions, possible recall phrases, negative signals, and confidence. Strong memory-profile terms are written into aliases, chunks, and entities while incidental mentions stay weak.
- Public HTML enrichment is split into general unofficial enrichment and a separate social HTML opt-in flag so social platforms remain disabled by default unless explicitly enabled.
- Processing now generates item-level and chunk-level embeddings through OpenRouter when `OPENROUTER_API_KEY` is configured, using `openai/text-embedding-3-small` by default to preserve the current `vector(1536)` schema.
- The `search` Edge Function now performs first-pass hybrid search with query embeddings, the existing `match_semantic_items` RPC, trigram similarity for morphology/typos, type-filter relaxation for recall, and lexical fallback when embeddings/RPC are unavailable.
- Search intent inference, saved-time phrase parsing, and memory-profile ranking are covered by Deno tests. The search function now supports an OpenRouter query planner that interprets associative memory requests before hybrid retrieval, with cheap keyword fallback when AI planning is unavailable.
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
- Vision analysis for recipe/manual images returns editable generated structure (`ingredients`/`materials`, `steps`, timing/facts when present), so image-derived recipes and instructions can use the same interactive detail UI as link/text-derived items.
- Item and chunk embeddings are generated best-effort with `openai/text-embedding-3-small` through OpenRouter by default. Missing or failed embedding generation does not fail item processing.
- Hybrid semantic search backend and Flutter integration exist as a first pass. Trigram similarity is layered in for Cyrillic/Hebrew morphology, short queries, and typos. Reranking and deeper search-quality evaluation are still pending.

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

## Code Quality And Safety Guards

Goal: stop runtime crashes and silent regressions before they ship, especially the kinds an AI agent can introduce when several agents work on the same code in parallel.

In priority order:

1. **Add stricter analyzer rules to `analysis_options.yaml`.**
   - `avoid_dynamic_calls: true`
   - `cast_nullable_to_non_nullable: true` (treated as a warning that fails CI)
   These two alone block the entire class of bugs where someone writes `parsedContent['x']! as String` and crashes when the key is absent.

2. **Pre-commit hook (Husky or simple `.git/hooks/pre-commit`).**
   Run `flutter analyze --fatal-warnings` and `flutter test` before every commit. Agents and humans alike cannot push code that does not analyze or test cleanly. Add a matching project script `scripts/precommit.ps1`.

3. **Smoke render tests for every feed card type.**
   One widget test per `ItemType` (`article`, `recipe`, `film`, `place`, `product`, `video`, `manual`, `note`, `unknown`, `image_analysis`) that renders the card with `parsedContent: {}` and asserts no exception is thrown. This is exactly the test that would have caught the `PlaceFeedCard`/`ProductFeedCard` `null!` crash.

4. **Typed view models for `parsed_content`.**
   Replace direct `Map<String, Object?>` access in widgets with strongly-typed view models per `kind` (e.g. `RecipeParsed`, `PlaceParsed`, `ProductParsed`, `LinkPreviewParsed`). Widgets only read the typed model. There is no `[]` operator and no place to write `!` on an unknown key. Generate models with Freezed.

5. **`ErrorBoundary` around each feed card and detail screen.**
   When a single item rejects to render, swap it for a soft fallback ("Something went wrong with this item") and log the failure to crash reporting (Sentry or Supabase log). Do not let one broken item turn the feed into a wall of red error widgets.

6. **GitHub Actions CI.**
   On every push: `flutter pub get`, `flutter gen-l10n`, `dart run build_runner build`, `flutter analyze`, `flutter test`, and Deno tests for `supabase/functions/**`. Pre-commit can be bypassed with `--no-verify`; CI cannot. Required to merge.

7. **AGENTS.md rule against direct `parsed_content` access.**
   Add a written rule: "Do not read `parsedContent[...]` from widgets. Use the typed view model for the item kind." This is what gates AI agents that have not yet learned the typed-model pattern.

Definition of done:

- A widget test that renders every feed card with empty `parsedContent` passes locally and in CI.
- `flutter analyze` and `flutter test` are gates on both pre-commit and CI.
- A failing item renders a soft fallback in the feed, not a red error widget.
- The lint rules above are active and enforced.
- New `ItemType`s require an accompanying typed view model and smoke render test before they can be merged.

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

## iOS

iOS-specific tasks, decisions, and working notes live in [`ios/IOS.md`](ios/IOS.md). Read that file before starting any iOS work, and append to it as new iOS-specific items come up — do not record iOS items in this roadmap.

## Open Questions

Items in this section are **not decided** yet. They are recorded so the model
for cost containment and free/paid tier shape gets discussed before code is
written. Each open question lists the options and the trade-offs as understood
right now.

### Pricing model and cost containment per item

The current free-tier guardrails in this roadmap (10 items, 3 images, 20
processing attempts) treat one card as the unit. That works for small text
notes but breaks down for large inputs: a 200-page book and a one-line
clipping are both "1 item" but the AI cost of processing them differs by 100x
or more. The paid tier shape needs to address this without making the product
feel like a metered service.

Options that have been raised:

- **A. Hidden per-item caps with simple paid plan ("$5 = unlimited items,
  bounded per-item cost").**
  Per-item hard limits enforced server-side: max input bytes, max AI input
  tokens, max output tokens, single AI call per item, single vision OCR per
  item. Storage is the only user-visible quota on the paid plan
  ("X GB used / Y GB"). Books and PDFs get a digest, not a full multi-call
  pass, so a single user cannot walk into hundreds of dollars of OpenAI cost.
  Pros: simple consumer messaging, no "credits remaining" UI anxiety, matches
  how Notion/Mem.ai/Reflect actually charge. Cons: power users who expect
  full-document processing will be surprised by the digest behaviour and need
  a clear "Pro+" upsell story.

- **B. Multi-dimensional plan with explicit AI processings or tokens.**
  The paid plan publishes an AI budget ("500 AI processings / month" or
  "1M tokens / month"), shown in the UI. Pros: predictable unit economics,
  easy to scale by selling higher tiers. Cons: anti-pattern in consumer apps
  ("how many do I have left?"), requires a usage screen, and most pricing
  research suggests it depresses upgrades vs. a flat plan.

- **C. Tiered flat plans without credits.**
  Several flat tiers ($5 basic, $15 pro, $50 power), each with progressively
  larger storage caps and per-item caps. No credit counter; tier matches user
  archetype. Pros: honest cost recovery, scales with heavier users. Cons:
  three SKUs to maintain at launch, more decisions for the user.

What the decision needs to consider:

- Real cost ceiling we are willing to absorb per paid user per month before
  it becomes a loss.
- Whether full-document processing (long PDFs, books, video transcripts) is
  ever a Dualio core feature or always a "Pro+" add-on.
- Whether the on-device summary/digest of a long document is acceptable UX
  or feels broken.
- Whether storage is a hard wall or a soft "you may need to upgrade" prompt.
- Cost log structure (`ai_call_log`, per-user monthly aggregates) is
  required for any of the three options and should be built first regardless.

This question must be resolved before implementing the free-tier guardrails
listed in **Free Tier And Retention Guardrails** above.

### Search quality on raw user content

Initial usage shows that vector + English-stemmed full-text search misses on
inflected Russian and on short partial queries (`магази` matches but `магазин`
does not because the English lexer does not normalise Cyrillic).

Options:

- **Trigram (`pg_trgm`) similarity layered on top of vector + FTS via
  Reciprocal Rank Fusion.** Language-agnostic, covers Cyrillic, Hebrew, and
  typos. Cheapest to add now. Does not understand semantics on its own
  (relies on embeddings for that).
- **Per-item language detection plus language-specific FTS configs (`russian`,
  `german`, etc.).** Correct linguistically but no built-in Postgres config
  for Hebrew, and it requires accurate language detection on every save.
- **External multilingual embedding model (Cohere `embed-multilingual-v3`,
  multilingual-e5).** Improves semantic recall across languages but does not
  fix the inflection / partial-query class of bug — that is what trigram
  solves cheaply.

Trigram + FTS + vector via RRF is the leading candidate. Decision needed
before the first paid tier ships.

### Account linking across providers

Auto-linking already happens when a user signs in with a second provider that
returns the same email as the existing account. The unresolved case is when
the same person signs in via Google with a different email than their original
magic-link address: Supabase creates a second user, the new feed is empty, and
the original 30+ items remain on the original account.

Options:

- Add a **"Link Google" button in Settings** that calls
  `supabase.auth.linkIdentity({ provider: google })` while logged in to the
  original account. This is the standard pattern in Notion/Linear/Slack.
- Offer **"Move my data here"** when the second account has zero items and a
  matching display name, transferring items from the original `user_id` to
  the new one (one-shot, irreversible).
- Continue treating them as fully separate accounts and document this clearly
  during sign-up.

The first option is the only one with no data-loss risk. Decision deferred
until we have real users hitting this case more than once.

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
