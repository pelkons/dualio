alter table public.items
  add column if not exists raw_content_expires_at timestamptz,
  add column if not exists raw_content_purged_at timestamptz,
  add column if not exists raw_content_retention_reason text;

create index if not exists items_raw_content_expires_idx
  on public.items(raw_content_expires_at)
  where raw_content_expires_at is not null and raw_content_purged_at is null;
