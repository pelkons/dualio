create table if not exists public.asset_cleanup_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  item_id uuid,
  reason text not null check (reason in ('pending_upload', 'item_deleted', 'account_deleted', 'orphaned_asset')),
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed', 'cancelled')),
  storage_provider text not null default 'cloudflare_r2',
  storage_bucket text not null,
  storage_key text not null,
  attempts integer not null default 0 check (attempts >= 0),
  last_error text,
  next_attempt_at timestamptz not null default now(),
  cleaned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(storage_provider, storage_bucket, storage_key)
);

create index if not exists asset_cleanup_jobs_due_idx
on public.asset_cleanup_jobs(status, next_attempt_at, created_at);

create index if not exists asset_cleanup_jobs_user_created_idx
on public.asset_cleanup_jobs(user_id, created_at desc);

alter table public.asset_cleanup_jobs enable row level security;

drop policy if exists "No direct client access to asset cleanup jobs" on public.asset_cleanup_jobs;
create policy "No direct client access to asset cleanup jobs"
on public.asset_cleanup_jobs
for all
using (false)
with check (false);
