-- Run once in the Supabase dashboard: SQL Editor > New query > paste > Run.

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  date date not null default current_date,
  note text not null default '',
  photo_path text,
  created_by uuid default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);

alter table public.memories enable row level security;

-- Only logged-in users (you two, since sign-ups are disabled) can use the album.
create policy "members only" on public.memories
  for all to authenticated
  using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

create policy "members only photos" on storage.objects
  for all to authenticated
  using (bucket_id = 'photos') with check (bucket_id = 'photos');
