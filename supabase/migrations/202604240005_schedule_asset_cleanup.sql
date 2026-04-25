create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema extensions;

do $$
begin
  if exists (
    select 1
    from cron.job
    where jobname = 'dualio-cleanup-assets-hourly'
  ) then
    perform cron.unschedule('dualio-cleanup-assets-hourly');
  end if;
end $$;

select cron.schedule(
  'dualio-cleanup-assets-hourly',
  '17 * * * *',
  $$
  select net.http_post(
    url := 'https://uogaveubabnsskfwftui.supabase.co/functions/v1/cleanup-assets',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cleanup-secret', (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'cleanup_assets_secret'
        limit 1
      )
    ),
    body := '{"limit":100}'::jsonb
  );
  $$
);
