create table if not exists public.item_assets (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_type text not null check (asset_type in ('image')),
  storage_provider text not null default 'cloudflare_r2',
  storage_bucket text not null,
  storage_key text not null,
  original_filename text,
  content_type text,
  byte_size bigint,
  width integer,
  height integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(storage_provider, storage_bucket, storage_key)
);

create index if not exists item_assets_item_id_idx on public.item_assets(item_id);
create index if not exists item_assets_user_id_created_idx on public.item_assets(user_id, created_at desc);

alter table public.item_assets enable row level security;

drop policy if exists "Users can read own item assets" on public.item_assets;
create policy "Users can read own item assets"
on public.item_assets
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own item assets" on public.item_assets;
create policy "Users can insert own item assets"
on public.item_assets
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own item assets" on public.item_assets;
create policy "Users can update own item assets"
on public.item_assets
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own item assets" on public.item_assets;
create policy "Users can delete own item assets"
on public.item_assets
for delete
using (auth.uid() = user_id);
