create extension if not exists pg_trgm;

create or replace function public.dualio_join_text_array(input_values text[])
returns text
language sql
immutable
parallel safe
as $$
  select array_to_string(coalesce(input_values, '{}'::text[]), ' ');
$$;

create index if not exists items_title_trgm_idx
  on public.items using gin ((lower(coalesce(title, ''))) gin_trgm_ops);

create index if not exists items_searchable_summary_trgm_idx
  on public.items using gin ((lower(coalesce(searchable_summary, ''))) gin_trgm_ops);

create index if not exists items_searchable_aliases_trgm_idx
  on public.items using gin (
    (lower(public.dualio_join_text_array(searchable_aliases))) gin_trgm_ops
  );

create index if not exists item_chunks_content_trgm_idx
  on public.item_chunks using gin ((lower(coalesce(content, ''))) gin_trgm_ops);

create or replace function public.match_items_trgm(
  query_text text,
  inferred item_type default null,
  match_count integer default 20,
  similarity_threshold double precision default 0.12
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
  with normalized as (
    select
      lower(trim(coalesce(query_text, ''))) as q,
      greatest(coalesce(match_count, 20), 1) as max_count,
      greatest(coalesce(similarity_threshold, 0.12), 0.01) as threshold
  ),
  item_scored as (
    select
      i.id as item_id,
      null::uuid as chunk_id,
      greatest(
        similarity(t.title_text, n.q),
        word_similarity(n.q, t.title_text),
        similarity(t.summary_text, n.q),
        word_similarity(n.q, t.summary_text),
        similarity(t.alias_text, n.q),
        word_similarity(n.q, t.alias_text)
      ) as score,
      case
        when t.title_text like '%' || n.q || '%'
          or word_similarity(n.q, t.title_text) >= n.threshold
          or similarity(t.title_text, n.q) >= n.threshold
          then 'title_trigram'
        when t.alias_text like '%' || n.q || '%'
          or word_similarity(n.q, t.alias_text) >= n.threshold
          or similarity(t.alias_text, n.q) >= n.threshold
          then 'alias_trigram'
        else 'summary_trigram'
      end as match_reason
    from public.items i
    cross join normalized n
    cross join lateral (
      select
        lower(coalesce(i.title, '')) as title_text,
        lower(coalesce(i.searchable_summary, '')) as summary_text,
        lower(public.dualio_join_text_array(i.searchable_aliases)) as alias_text
    ) t
    where i.user_id = auth.uid()
      and n.q <> ''
      and (inferred is null or i.type = inferred)
      and (
        t.title_text like '%' || n.q || '%'
        or t.summary_text like '%' || n.q || '%'
        or t.alias_text like '%' || n.q || '%'
        or greatest(
          similarity(t.title_text, n.q),
          word_similarity(n.q, t.title_text),
          similarity(t.summary_text, n.q),
          word_similarity(n.q, t.summary_text),
          similarity(t.alias_text, n.q),
          word_similarity(n.q, t.alias_text)
        ) >= n.threshold
      )
    order by score desc
    limit (select max_count * 3 from normalized)
  ),
  chunk_scored as (
    select
      c.item_id,
      c.id as chunk_id,
      greatest(
        similarity(t.content_text, n.q),
        word_similarity(n.q, t.content_text)
      ) as score,
      'chunk_trigram'::text as match_reason
    from public.item_chunks c
    join public.items i on i.id = c.item_id
    cross join normalized n
    cross join lateral (
      select lower(coalesce(c.content, '')) as content_text
    ) t
    where c.user_id = auth.uid()
      and n.q <> ''
      and (inferred is null or i.type = inferred)
      and (
        t.content_text like '%' || n.q || '%'
        or greatest(
          similarity(t.content_text, n.q),
          word_similarity(n.q, t.content_text)
        ) >= n.threshold
      )
    order by score desc
    limit (select max_count * 3 from normalized)
  )
  select item_id, chunk_id, score, match_reason
  from (
    select * from item_scored
    union all
    select * from chunk_scored
  ) matches
  order by score desc
  limit (select max_count from normalized);
$$;
