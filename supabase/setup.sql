-- Run once in the Supabase SQL Editor. Create two users in Authentication > Users first.
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  date date not null default current_date,
  location text not null default '',
  note text not null default '',
  photo_path text,
  created_by uuid default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);
alter table public.memories add column if not exists location text not null default '';

alter table public.memories enable row level security;

-- Separate memories used only in the first-month recap (not shown in Our Album).
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
alter table public.month_recap_memories enable row level security;

create table if not exists public.shared_state (
  id text primary key check (id = 'couple'),
  data jsonb not null default '{"progress":{},"custom":{},"completed":[]}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.shared_state enable row level security;

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;
update storage.buckets set public = false where id = 'photos';

-- Run security-hardening.sql after creating the two Auth users to add the
-- explicit member-only RLS and private-storage policies.
