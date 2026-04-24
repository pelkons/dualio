create extension if not exists vector;

create type item_type as enum ('recipe', 'film', 'place', 'article', 'product', 'video', 'note', 'unknown');
create type source_type as enum ('link', 'screenshot', 'photo', 'text');
create type processing_status as enum ('pending', 'processing', 'ready', 'needs_clarification', 'failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  preferred_locale text not null default 'en',
  theme_preference text not null default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type item_type not null default 'unknown',
  source_url text,
  source_type source_type not null,
  raw_content jsonb not null default '{}'::jsonb,
  parsed_content jsonb not null default '{}'::jsonb,
  title text not null,
  thumbnail_url text,
  language text,
  searchable_summary text not null default '',
  searchable_aliases text[] not null default '{}',
  embedding vector(1536),
  processing_status processing_status not null default 'pending',
  clarification_question text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.item_chunks (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  chunk_type text not null,
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  embedding vector(1536),
  created_at timestamptz not null default now()
);

create table public.item_entities (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  entity text not null,
  entity_type text not null,
  normalized_value text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.search_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  query text not null,
  locale text not null,
  inferred_type item_type,
  clicked_item_id uuid references public.items(id) on delete set null,
  result_count integer not null default 0,
  created_at timestamptz not null default now()
);

create index items_user_created_idx on public.items(user_id, created_at desc);
create index items_aliases_gin_idx on public.items using gin(searchable_aliases);
create index items_fts_idx on public.items using gin(to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(searchable_summary, '')));
create index items_status_idx on public.items(user_id, processing_status);
create index item_chunks_item_idx on public.item_chunks(item_id);
create index item_chunks_user_idx on public.item_chunks(user_id);
create index item_chunks_fts_idx on public.item_chunks using gin(to_tsvector('simple', content));
create index item_entities_item_idx on public.item_entities(item_id);
create index item_entities_user_type_idx on public.item_entities(user_id, entity_type);
create index item_entities_normalized_idx on public.item_entities(user_id, normalized_value);
create index search_events_user_created_idx on public.search_events(user_id, created_at desc);

create index items_embedding_hnsw_idx on public.items using hnsw (embedding vector_cosine_ops);
create index item_chunks_embedding_hnsw_idx on public.item_chunks using hnsw (embedding vector_cosine_ops);

alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.item_chunks enable row level security;
alter table public.item_entities enable row level security;
alter table public.search_events enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "items_select_own" on public.items for select using (auth.uid() = user_id);
create policy "items_insert_own" on public.items for insert with check (auth.uid() = user_id);
create policy "items_update_own" on public.items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "items_delete_own" on public.items for delete using (auth.uid() = user_id);

create policy "item_chunks_select_own" on public.item_chunks for select using (auth.uid() = user_id);
create policy "item_chunks_insert_own" on public.item_chunks for insert with check (auth.uid() = user_id);
create policy "item_chunks_update_own" on public.item_chunks for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "item_chunks_delete_own" on public.item_chunks for delete using (auth.uid() = user_id);

create policy "item_entities_select_own" on public.item_entities for select using (auth.uid() = user_id);
create policy "item_entities_insert_own" on public.item_entities for insert with check (auth.uid() = user_id);
create policy "item_entities_update_own" on public.item_entities for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "item_entities_delete_own" on public.item_entities for delete using (auth.uid() = user_id);

create policy "search_events_select_own" on public.search_events for select using (auth.uid() = user_id);
create policy "search_events_insert_own" on public.search_events for insert with check (auth.uid() = user_id);

create or replace function public.match_semantic_items(
  query_embedding vector(1536),
  query_text text,
  inferred item_type default null,
  match_count integer default 20
)
returns table (
  item_id uuid,
  chunk_id uuid,
  score double precision,
  match_reason text
)
language sql
stable
as $$
  with chunk_matches as (
    select
      c.item_id,
      c.id as chunk_id,
      (1 - (c.embedding <=> query_embedding)) as score,
      'chunk_embedding'::text as reason
    from public.item_chunks c
    join public.items i on i.id = c.item_id
    where c.user_id = auth.uid()
      and c.embedding is not null
      and (inferred is null or i.type = inferred)
    order by c.embedding <=> query_embedding
    limit match_count * 3
  ),
  item_matches as (
    select
      i.id as item_id,
      null::uuid as chunk_id,
      (1 - (i.embedding <=> query_embedding)) as score,
      'item_embedding'::text as reason
    from public.items i
    where i.user_id = auth.uid()
      and i.embedding is not null
      and (inferred is null or i.type = inferred)
    order by i.embedding <=> query_embedding
    limit match_count * 3
  ),
  lexical_matches as (
    select
      i.id as item_id,
      null::uuid as chunk_id,
      0.74::double precision + least(0.08, extract(epoch from (now() - i.created_at)) / -6048000.0 + 0.08) as score,
      'full_text_or_alias'::text as reason
    from public.items i
    where i.user_id = auth.uid()
      and (to_tsvector('simple', coalesce(i.title, '') || ' ' || coalesce(i.searchable_summary, '')) @@ plainto_tsquery('simple', query_text)
        or query_text = any(i.searchable_aliases))
      and (inferred is null or i.type = inferred)
    limit match_count * 3
  ),
  entity_matches as (
    select
      e.item_id,
      null::uuid as chunk_id,
      0.78::double precision as score,
      'entity'::text as reason
    from public.item_entities e
    join public.items i on i.id = e.item_id
    where e.user_id = auth.uid()
      and (e.entity ilike '%' || query_text || '%'
        or e.normalized_value ilike '%' || query_text || '%')
      and (inferred is null or i.type = inferred)
    limit match_count * 3
  ),
  chunk_text_matches as (
    select
      c.item_id,
      c.id as chunk_id,
      0.72::double precision as score,
      'chunk_full_text'::text as reason
    from public.item_chunks c
    join public.items i on i.id = c.item_id
    where c.user_id = auth.uid()
      and to_tsvector('simple', c.content) @@ plainto_tsquery('simple', query_text)
      and (inferred is null or i.type = inferred)
    limit match_count * 3
  )
  select item_id, chunk_id, max(score) as score, string_agg(distinct reason, ', ') as match_reason
  from (
    select * from chunk_matches
    union all select * from item_matches
    union all select * from lexical_matches
    union all select * from entity_matches
    union all select * from chunk_text_matches
  ) matches
  group by item_id, chunk_id
  order by score desc
  limit match_count;
$$;
