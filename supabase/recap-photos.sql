-- Run once in the Supabase SQL Editor after security-hardening.sql.
-- The recap owner can upload/delete. Both story members can view after release.
create table if not exists private.recap_owners (
  singleton boolean primary key default true check (singleton),
  user_id uuid unique not null references auth.users (id) on delete cascade
);
alter table private.recap_owners enable row level security;
revoke all on table private.recap_owners from public, anon, authenticated;

create or replace function public.is_recap_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.recap_owners
    where user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_recap_owner() from public, anon;
grant execute on function public.is_recap_owner() to authenticated;

create or replace function public.is_recap_released()
returns boolean
language sql
stable
set search_path = ''
as $$
  select now() >= timestamptz '2026-11-24 23:00:00+00';
$$;
revoke all on function public.is_recap_released() from public, anon;
grant execute on function public.is_recap_released() to authenticated;

create table if not exists public.month_recap_memories (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  date date not null default current_date,
  moment_id text,
  note text not null default '',
  photo_path text not null,
  created_by uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);
alter table public.month_recap_memories add column if not exists moment_id text;

alter table public.month_recap_memories enable row level security;
grant select, insert, delete on public.month_recap_memories to authenticated;

drop policy if exists "recap owner or released" on public.month_recap_memories;
create policy "recap owner or released" on public.month_recap_memories
  for select to authenticated
  using (
    public.is_story_member()
    and (public.is_recap_owner() or public.is_recap_released())
  );

drop policy if exists "recap owner insert" on public.month_recap_memories;
create policy "recap owner insert" on public.month_recap_memories
  for insert to authenticated
  with check (public.is_story_member() and public.is_recap_owner() and created_by = (select auth.uid()));

drop policy if exists "recap owner delete" on public.month_recap_memories;
create policy "recap owner delete" on public.month_recap_memories
  for delete to authenticated
  using (public.is_story_member() and public.is_recap_owner() and created_by = (select auth.uid()));

-- Keep Our Album available to both members; restrict recap/ files to the owner
-- until release, and allow only the owner to upload or delete them thereafter.
drop policy if exists "members only photos" on storage.objects;
drop policy if exists "story members only photos" on storage.objects;
drop policy if exists "story members read photos" on storage.objects;
drop policy if exists "story members upload photos" on storage.objects;
drop policy if exists "story members delete photos" on storage.objects;
create policy "story members read photos" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'photos'
    and public.is_story_member()
    and (name not like 'recap/%' or public.is_recap_owner() or public.is_recap_released())
  );
create policy "story members upload photos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'photos'
    and public.is_story_member()
    and (name not like 'recap/%' or public.is_recap_owner())
  );
create policy "story members delete photos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'photos'
    and public.is_story_member()
    and (name not like 'recap/%' or public.is_recap_owner())
  );

-- Assign your account as the sole recap owner. First find your UUID:
-- select id from auth.users where lower(email) = lower('YOUR_LOGIN_EMAIL');
-- Then register it (replace the UUID):
-- insert into private.recap_owners (user_id) values ('YOUR_AUTH_USER_UUID') on conflict do nothing;
