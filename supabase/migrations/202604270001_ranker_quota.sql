alter table public.profiles
  add column if not exists ranked_searches_today int not null default 0;

alter table public.profiles
  add column if not exists ranked_searches_reset_at timestamptz not null default now();
