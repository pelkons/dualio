# AI Models for Dualio

Source for pricing and availability: OpenRouter `/api/v1/models`, pulled on 2026-04-27.

This file is written for product decisions, not for code review. The goal is to decide which model should handle each AI job in Dualio.

## Decision Summary

Use cheap structured models for repeatable JSON work. Use a stronger or more reliable model only where the result is directly visible to the user or where Hebrew OCR quality matters.

Recommended setup:

```env
AI_TEXT_EXTRACT_PRIMARY=qwen/qwen3.5-flash-02-23
AI_TEXT_ONLY_FALLBACK=deepseek/deepseek-v4-flash
AI_TEXT_EXTRACT_FALLBACK=openai/gpt-5.4-nano

AI_QUERY_PLAN_PRIMARY=qwen/qwen3.5-flash-02-23

AI_SEARCH_RANKER_PRIMARY=deepseek/deepseek-v4-flash
AI_SEARCH_RANKER_FALLBACK=openai/gpt-5.4-nano

AI_VISION_EXTRACT_PRIMARY=qwen/qwen3.5-flash-02-23
AI_VISION_EXTRACT_FALLBACK=google/gemini-3.1-flash-lite-preview
AI_VISION_HEBREW_MODEL=google/gemini-3.1-flash-lite-preview

AI_EMBEDDING_MODEL=openai/text-embedding-3-small
```

## What To Change First

1. Change `AI_QUERY_PLAN_PRIMARY` to `qwen/qwen3.5-flash-02-23`.

This is only a Supabase secret change. No code change. Easy rollback.

2. Change search ranker order:

```env
AI_SEARCH_RANKER_PRIMARY=deepseek/deepseek-v4-flash
AI_SEARCH_RANKER_FALLBACK=openai/gpt-5.4-nano
```

This makes AI search explanations cheaper, because ranker output is token-heavy.

3. Keep embeddings unchanged.

Do not change embeddings now. The database vectors are built around `text-embedding-3-small`; changing this means re-embedding all saved items and chunks.

## Model Prices

Prices below are per 1M input / output tokens.

- `qwen/qwen3.5-flash-02-23`: $0.065 / $0.26
- `deepseek/deepseek-v4-flash`: $0.14 / $0.28
- `openai/gpt-5.4-nano`: $0.20 / $1.25
- `qwen/qwen3-vl-30b-a3b-instruct`: $0.13 / $0.52
- `google/gemini-3.1-flash-lite-preview`: $0.25 / $1.50
- `text-embedding-3-small`: keep current direct OpenAI setup

## Decisions By Role

### 1. Extraction Primary

What it does:

Turns links, screenshots, photos, and raw text into structured JSON: title, summary, content type, entities, aliases, chunks, and memory profile.

Current model:

`qwen/qwen3.5-flash-02-23`

Other agent recommendation:

Keep it.

Codex position:

Agree.

Decision:

Keep `qwen/qwen3.5-flash-02-23`.

Why:

This is the high-volume save-time model. It supports multimodal input, structured JSON, multilingual content, and 1M context. It is also cheap enough for routine item processing.

### 2. Extraction Text Fallback

What it does:

Runs when the primary extraction path fails and the input can be handled as plain text.

Current model:

`deepseek/deepseek-v4-flash`

Other agent recommendation:

Keep it.

Codex position:

Agree.

Decision:

Keep `deepseek/deepseek-v4-flash`.

Why:

It is cheap, structured-output capable, and gives vendor/model diversity instead of using another Qwen model as fallback.

### 3. Extraction Last-Resort

What it does:

Runs only if the primary and text fallback fail.

Current model:

`openai/gpt-5.4-nano`

Other agent recommendation:

Keep it.

Codex position:

Agree.

Decision:

Keep `openai/gpt-5.4-nano`.

Why:

It is more expensive than DeepSeek/Qwen, but this path should be rare. The point is reliability from a different vendor.

### 4. Query Planner

What it does:

Converts a user query like “find the breakfast recipe I saved a few months ago” into structured search intent: language, semantic query, likely domains, filters, and keywords.

Current model:

`openai/gpt-5.4-nano`

Other agent recommendation:

Use `qwen/qwen3.5-flash-02-23`.

Codex position:

Agree.

Decision:

Use `qwen/qwen3.5-flash-02-23`.

Why:

This is mostly classification and structured planning. It does not need an expensive model. Moving from GPT-5.4-nano to Qwen cuts cost sharply without changing the architecture.

### 5. Search Ranker Primary

What it does:

Takes up to 20 search candidates and decides which results are primary, which are secondary, and why each result was returned.

Current model:

`openai/gpt-5.4-nano`

Other agent recommendation:

Use `deepseek/deepseek-v4-flash`.

Codex position:

Agree.

Decision:

Use `deepseek/deepseek-v4-flash`.

Why:

The ranker writes explanations. Output tokens are the expensive part. DeepSeek has much cheaper output tokens and is good enough for this reasoning/ranking layer.

### 6. Search Ranker Fallback

What it does:

Runs if the primary ranker fails or times out.

Current model:

`deepseek/deepseek-v4-flash`

Other agent recommendation:

Use `openai/gpt-5.4-nano`.

Codex position:

Agree.

Decision:

Use `openai/gpt-5.4-nano`.

Why:

If DeepSeek fails, using another cheap model from the same quality tier is not very useful. The fallback should be a different vendor and a stable structured model.

### 7. Vision OCR

What it does:

Reads screenshots and photos, extracts visible text, understands the content, and turns it into a structured item.

Current legacy direct-OpenAI path:

`gpt-4.1-mini`

Other agent recommendation:

Eventually move to `qwen/qwen3-vl-30b-a3b-instruct`.

Codex position:

Partially agree.

Decision:

Keep the current OpenRouter primary as `qwen/qwen3.5-flash-02-23` for now.

Use `google/gemini-3.1-flash-lite-preview` as fallback and as the mandatory Hebrew vision model.

Why:

Qwen-VL may be cheaper for OCR, but Hebrew quality is a hard requirement. Gemini should be the explicit Hebrew path. Before replacing the general vision primary with Qwen-VL, test real screenshots in Russian, Hebrew, English, and mixed-language tables.

### 8. Hebrew Vision Override

What it does:

If image analysis detects Hebrew text, the OCR/understanding pass must use Gemini.

Current model:

`AI_VISION_HEBREW_MODEL`

Other agent recommendation:

This was implied under OCR.

Codex position:

Make it explicit.

Decision:

Set `AI_VISION_HEBREW_MODEL=google/gemini-3.1-flash-lite-preview`.

Why:

This is not just a model preference. It is a product rule: Hebrew OCR quality matters enough to route it separately.

### 9. Embeddings

What it does:

Creates vectors for item-level and chunk-level semantic search.

Current model:

`text-embedding-3-small`

Other agent recommendation:

Keep it.

Codex position:

Agree.

Decision:

Keep `text-embedding-3-small`.

Why:

The vector schema and indexes are already built around this embedding size. Changing embeddings later requires a planned full re-embed, not a casual env change.

## Final Recommendation

Do not change everything at once.

Step 1:

Change query planner and ranker env values only.

Step 2:

Test search quality with real saved items:

- Russian query against Hebrew recipe
- Hebrew query against Russian screenshot
- English query against non-English item
- vague associative query like “what can I cook in the morning”
- disambiguation query like “movie with food in the title”

Step 3:

Only after that, test OCR model swaps on real screenshots/photos.

## Codex Notes

The role decomposition is mostly correct. The main structural correction is that Hebrew vision should be a first-class routing rule, not a footnote under general OCR. Query planner and extraction primary can share a cheap structured model because both are JSON tasks. Search ranker should stay separate because it directly shapes whether search feels intelligent to the user. Ranker fallback is worth keeping during beta, but we should measure fallback frequency; if it almost never runs, we can simplify later.
