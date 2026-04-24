---
name: ai-processing-pipeline
description: AI item processing pipeline for Dualio. Use when Codex implements, plans, reviews, or debugs processing saved links, screenshots, photos, and text into typed semantic items using OpenAI extraction, OCR, classification, summaries, entities, aliases, chunks, embeddings, reranking inputs, R2 thumbnails, idempotent Edge Functions, retries, and stage logging.
---

# AI Processing Pipeline

Use this skill for the `process-item` pipeline and AI search preparation.

## Pipeline Contract

When a user saves an item:

1. Insert raw input with `processing_status = pending`.
2. Update UI optimistically.
3. Process in an Edge Function.
4. Mark `ready`, `needs_clarification`, or `failed`.

The processing function must be idempotent and retry-safe.

## Required Stages

- Fetch item and lock/idempotency context.
- Normalize source.
- Fetch URL HTML/metadata when source is a link.
- OCR screenshots/photos.
- Use raw text directly when source is text.
- Detect item type.
- Extract type-specific structured fields.
- Generate user-visible summary.
- Extract entities.
- Generate multilingual aliases/synonyms.
- Split into semantic chunks.
- Generate item-level and chunk-level embeddings.
- Upload or derive images/thumbnails through R2.
- Store signed/public access metadata.
- Log every stage.

## Clarification Rule

If ambiguous, set `needs_clarification` with exactly one short user-facing question.

## Search Quality Rules

- Optimize for cross-lingual retrieval across English, Hebrew, Russian, Italian, French, Spanish, and German.
- Preserve original language and generate searchable aliases where useful.
- Keep chunk metadata rich enough to explain matches.
