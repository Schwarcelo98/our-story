-- Run once in the Supabase SQL Editor. Create two users in Authentication > Users first.
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  date date not null default current_date,
  note text not null default '',
  photo_path text,
  created_by uuid default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);

alter table public.memories enable row level security;
drop policy if exists "members only" on public.memories;
create policy "members only" on public.memories for all to authenticated using (true) with check (true);

create table if not exists public.shared_state (
  id text primary key check (id = 'couple'),
  data jsonb not null default '{"progress":{},"custom":{}}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.shared_state enable row level security;
drop policy if exists "members only" on public.shared_state;
create policy "members only" on public.shared_state for all to authenticated using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;
drop policy if exists "members only photos" on storage.objects;
create policy "members only photos" on storage.objects for all to authenticated
  using (bucket_id = 'photos') with check (bucket_id = 'photos');
