---
name: supabase-rag-backend
description: Supabase RAG backend engineering for Dualio. Use when Codex designs, edits, reviews, or debugs Supabase migrations, Postgres schemas, pgvector indexes, RLS policies, RPC search functions, Edge Function contracts, Auth profiles, Realtime boundaries, and R2 signed media metadata for Dualio semantic memory.
---

# Supabase RAG Backend

Use this skill for database and Supabase backend work.

## Schema Principles

- Model Dualio as semantic memory, not as simple saved cards.
- Keep these core tables central: `profiles`, `items`, `item_chunks`, `item_entities`, `search_events`.
- Store raw input separately from parsed structured content.
- Keep item-level and chunk-level embeddings.
- Use `vector(1536)` when using `text-embedding-3-small`.
- Add indexes for user feed, vector search, aliases, full text, and entities.

## Security Rules

- Enable RLS on every user-data table.
- Users may only read/write their own rows.
- Use `auth.uid()` policies with both `using` and `with check` where applicable.
- Edge Functions may use service role only server-side.
- Never expose service role keys to the Flutter client.
- Treat views and security definer functions carefully; avoid bypassing RLS unintentionally.

## Search Backend Rules

- Implement hybrid search, not vector-only search.
- Combine item embedding, chunk embedding, full text, aliases, entities, type inference, recency/context boosting, and reranking.
- Store search events for quality debugging.
- Include internal match reasons for diagnostics.

## Validation

- Review migrations for rollback and idempotency concerns.
- Test RLS with at least two users before trusting policies.
- Run Supabase migration tooling when available.
