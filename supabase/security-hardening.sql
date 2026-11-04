-- Replace the two example addresses below with the email addresses of the two
-- accounts you created in Supabase Auth, then run this script in the SQL Editor.
-- The script replaces broad "authenticated user" policies with an explicit allowlist.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Add fields required by the latest album UI; safe to run on an existing project.
alter table public.memories add column if not exists location text not null default '';
update storage.buckets set public = false where id = 'photos';
alter table public.memories enable row level security;
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

drop policy if exists "members only" on public.memories;
drop policy if exists "story members only" on public.memories;
create policy "story members only" on public.memories
  for all to authenticated
  using (public.is_story_member())
  with check (public.is_story_member());

drop policy if exists "members only" on public.shared_state;
drop policy if exists "story members only" on public.shared_state;
create policy "story members only" on public.shared_state
  for all to authenticated
  using (public.is_story_member())
  with check (public.is_story_member());

drop policy if exists "members only photos" on storage.objects;
drop policy if exists "story members only photos" on storage.objects;
create policy "story members only photos" on storage.objects
  for all to authenticated
  using (bucket_id = 'photos' and public.is_story_member())
  with check (bucket_id = 'photos' and public.is_story_member());

-- Verify this returns 2 before testing both logins.
select count(*) as allowed_accounts from private.story_members;
