-- Replace the two example addresses below with the email addresses of the two
-- accounts you created in Supabase Auth, then run this script in the SQL Editor.
-- The script replaces broad "authenticated user" policies with an explicit allowlist.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.recap_owners (
  singleton boolean primary key default true check (singleton),
  user_id uuid unique not null references auth.users (id) on delete cascade
);
alter table private.recap_owners enable row level security;
revoke all on table private.recap_owners from public, anon, authenticated;

-- Add fields required by the latest album UI; safe to run on an existing project.
alter table public.memories add column if not exists location text not null default '';
update storage.buckets set public = false where id = 'photos';
alter table public.memories enable row level security;
create table if not exists public.month_recap_memories (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  date date not null default current_date,
  moment_id text,
  note text not null default '',
  photo_path text not null,
  created_by uuid default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);
alter table public.month_recap_memories add column if not exists moment_id text;
alter table public.month_recap_memories enable row level security;
alter table public.shared_state enable row level security;

create table if not exists private.story_members (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table private.story_members enable row level security;
revoke all on table private.story_members from public, anon, authenticated;

do $$
declare
  allowed_ids uuid[];
begin
  select array_agg(id) into allowed_ids
  from auth.users
  where lower(email) in (lower('YOUR_EMAIL'), lower('VERO_EMAIL'));

  if coalesce(cardinality(allowed_ids), 0) <> 2 then
    raise exception 'Expected exactly two allowed Auth accounts. Replace YOUR_EMAIL and VERO_EMAIL, then run this script again.';
  end if;

  delete from private.story_members where not (user_id = any(allowed_ids));
  insert into private.story_members (user_id)
  select unnest(allowed_ids)
  on conflict (user_id) do nothing;
end;
$$;

create or replace function public.is_story_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.story_members
    where user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_story_member() from public, anon;
grant execute on function public.is_story_member() to authenticated;

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

drop policy if exists "members only" on public.memories;
drop policy if exists "story members only" on public.memories;
create policy "story members only" on public.memories
  for all to authenticated
  using (public.is_story_member())
  with check (public.is_story_member());

grant select, insert, delete on public.month_recap_memories to authenticated;
drop policy if exists "story members only" on public.month_recap_memories;
drop policy if exists "recap owner or released" on public.month_recap_memories;
create policy "recap owner or released" on public.month_recap_memories
  for select to authenticated
  using (public.is_story_member() and (public.is_recap_owner() or public.is_recap_released()));
drop policy if exists "recap owner insert" on public.month_recap_memories;
create policy "recap owner insert" on public.month_recap_memories
  for insert to authenticated
  with check (public.is_story_member() and public.is_recap_owner() and created_by = (select auth.uid()));
drop policy if exists "recap owner delete" on public.month_recap_memories;
create policy "recap owner delete" on public.month_recap_memories
  for delete to authenticated
  using (public.is_story_member() and public.is_recap_owner() and created_by = (select auth.uid()));

drop policy if exists "members only" on public.shared_state;
drop policy if exists "story members only" on public.shared_state;
create policy "story members only" on public.shared_state
  for all to authenticated
  using (public.is_story_member())
  with check (public.is_story_member());

drop policy if exists "members only photos" on storage.objects;
drop policy if exists "story members only photos" on storage.objects;
drop policy if exists "story members read photos" on storage.objects;
drop policy if exists "story members upload photos" on storage.objects;
drop policy if exists "story members delete photos" on storage.objects;
create policy "story members read photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'photos' and public.is_story_member() and (name not like 'recap/%' or public.is_recap_owner() or public.is_recap_released()));
create policy "story members upload photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'photos' and public.is_story_member() and (name not like 'recap/%' or public.is_recap_owner()));
create policy "story members delete photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'photos' and public.is_story_member() and (name not like 'recap/%' or public.is_recap_owner()));

-- Verify this returns 2 before testing both logins.
select count(*) as allowed_accounts from private.story_members;
