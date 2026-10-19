-- LangkahKerja / Benelovent. Apply once with `supabase db push`.
create table public.user_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb check (octet_length(payload::text) <= 8388608),
  revision bigint not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.user_state enable row level security;
grant select on public.user_state to authenticated;
create policy "read own state" on public.user_state for select to authenticated using ((select auth.uid()) = user_id);
-- All writes go through the revision-checked RPC. No direct insert/update grants.
revoke insert, update, delete on public.user_state from anon, authenticated;

create function public.sync_user_state(expected_revision bigint, new_payload jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); current_revision bigint;
begin
  if uid is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if new_payload->>'app' is distinct from 'LangkahKerja' or new_payload->>'schema' is distinct from '2'
    or octet_length(new_payload::text) > 8388608 then
    raise exception 'Invalid state document' using errcode = '22023';
  end if;
  insert into public.user_state(user_id) values(uid) on conflict(user_id) do nothing;
  select revision into current_revision from public.user_state where user_id = uid for update;
  if current_revision <> expected_revision then
    raise exception 'Revision conflict' using errcode = '40001';
  end if;
  update public.user_state set payload = new_payload, revision = current_revision + 1, updated_at = now() where user_id = uid;
  return jsonb_build_object('revision', current_revision + 1);
end;
$$;
revoke all on function public.sync_user_state(bigint, jsonb) from public, anon;
grant execute on function public.sync_user_state(bigint, jsonb) to authenticated;

create table public.jobs (
  id text primary key check(length(id) <= 500),
  country text not null default 'ID' check(country = 'ID'),
  payload jsonb not null check(octet_length(payload::text) <= 250000),
  published boolean not null default false,
  published_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '14 days'),
  imported_at timestamptz not null default now()
);
create index jobs_feed on public.jobs(published_at desc, id) where published and country = 'ID';
alter table public.jobs enable row level security;
grant select on public.jobs to anon, authenticated;
revoke insert, update, delete on public.jobs from anon, authenticated;
create policy "read active Indonesia feed" on public.jobs for select to anon, authenticated using (published and country = 'ID' and expires_at > now());

create table public.job_reports (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  job_id text not null references public.jobs(id) on delete cascade check(length(job_id) <= 500),
  reason text not null check(reason in ('scam', 'closed', 'inaccurate', 'other')),
  detail text not null default '' check(length(detail) <= 1500),
  created_at timestamptz not null default now(),
  unique(user_id, job_id, reason)
);
alter table public.job_reports enable row level security;
grant insert, select on public.job_reports to authenticated;
grant usage, select on sequence public.job_reports_id_seq to authenticated;
create policy "submit own report" on public.job_reports for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "read own reports" on public.job_reports for select to authenticated using ((select auth.uid()) = user_id);

create function public.limit_job_reports() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Per-user lock prevents parallel requests from bypassing the daily limit.
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 0));
  if (select count(*) from public.job_reports where user_id = new.user_id and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'Daily report limit reached' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
create trigger limit_job_reports before insert on public.job_reports for each row execute function public.limit_job_reports();

-- Supabase's service role (server-side only) can moderate jobs/reports and import licensed feeds.
-- Never grant clients the service-role key, and never disable RLS.
