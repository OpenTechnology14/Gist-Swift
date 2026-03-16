-- ============================================================
-- Gist App — Supabase Schema
-- Run this in your Supabase project: Dashboard → SQL Editor
-- ============================================================

-- 1. Profiles table (extends auth.users)
create table if not exists public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  email       text,
  role        text not null default 'user',   -- 'user' | 'admin'
  max_lists   int  not null default 4,
  max_items   int  not null default 50,
  created_at  timestamptz default now()
);

-- 2. Lists table
create table if not exists public.lists (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users on delete cascade not null,
  name        text not null,
  color       text not null default '#7ac94b',  -- hex colour swatch chosen by user
  sort_order  int  not null default 0,
  created_at  timestamptz default now()
);

-- Migration: if upgrading from an older schema that used emoji, run:
--   alter table public.lists rename column emoji to color;
--   alter table public.lists alter column color set default '#7ac94b';
--   update public.lists set color = '#7ac94b' where color like '%🛒%' or color like '%📝%';

-- 3. Items table
create table if not exists public.items (
  id                uuid default gen_random_uuid() primary key,
  user_id           uuid references auth.users on delete cascade not null,
  list_id           uuid references public.lists on delete cascade,
  name              text not null,
  brand             text,
  image_url         text,
  nutriscore_grade  text,
  nova_group        int,
  gist_score        int,
  quantity          int  not null default 1,
  is_checked        bool not null default false,
  item_type         text not null default 'recently_viewed', -- 'recently_viewed' | 'list_item'
  created_at        timestamptz default now()
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.lists    enable row level security;
alter table public.items    enable row level security;

-- Profiles: users read/update their own; admins read all
create policy "users_read_own_profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "users_update_own_profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "admins_read_all_profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy "admins_update_all_profiles"
  on public.profiles for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- Lists: users manage their own
create policy "users_manage_own_lists"
  on public.lists for all
  using (auth.uid() = user_id);

-- Items: users manage their own
create policy "users_manage_own_items"
  on public.items for all
  using (auth.uid() = user_id);

-- ============================================================
-- Auto-create profile on sign-up
-- ============================================================

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role, max_lists, max_items)
  values (new.id, new.email, 'user', 4, 50)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- To promote a user to admin, run:
--   update public.profiles set role = 'admin' where email = 'your@email.com';
-- ============================================================
