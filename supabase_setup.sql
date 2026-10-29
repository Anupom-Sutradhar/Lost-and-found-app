-- ════════════════════════════════════════════════════════════════════════════
-- UniFind — Supabase SQL setup
-- ════════════════════════════════════════════════════════════════════════════
-- HOW TO USE:
--   1. Open Supabase dashboard → SQL Editor → New query.
--   2. Paste this entire file → Run.
--   3. Storage buckets: see the "STORAGE" section at the bottom — those steps
--      use the Storage UI, not SQL.
-- ════════════════════════════════════════════════════════════════════════════

-- ─── ENUMS ──────────────────────────────────────────────────────────────────

do $$ begin
  create type post_type as enum ('lost', 'found');
exception when duplicate_object then null; end $$;

do $$ begin
  create type post_status as enum ('active', 'resolved');
exception when duplicate_object then null; end $$;


-- ─── PROFILES TABLE ─────────────────────────────────────────────────────────
-- One row per Supabase auth user.

create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null unique,
  name         text not null,
  student_id   text not null,
  department   text,
  phone        text,
  photo_url    text,
  created_at   timestamptz not null default now()
);

-- Index for fast student_id lookups (optional)
create index if not exists idx_profiles_student_id on public.profiles(student_id);

-- ─── PROFILE AUTO-CREATION TRIGGER ──────────────────────────────────────────
-- When a new user signs up via Supabase Auth, automatically create a profile
-- row using the metadata passed during signUp (name, student_id, department).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, student_id, department)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'name', 'Student'),
    coalesce(new.raw_user_meta_data ->> 'student_id', ''),
    new.raw_user_meta_data ->> 'department'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ─── POSTS TABLE ────────────────────────────────────────────────────────────

create table if not exists public.posts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  user_name       text not null,
  user_photo_url  text,
  type            post_type   not null,
  status          post_status not null default 'active',
  title           text not null,
  description     text not null,
  image_url       text,
  location        text not null,
  contact_info    text not null,
  category        text not null,
  created_at      timestamptz not null default now(),
  resolved_at     timestamptz
);

-- Indexes for the queries the app actually makes
create index if not exists idx_posts_type_status_created on public.posts(type, status, created_at desc);
create index if not exists idx_posts_user_created       on public.posts(user_id, created_at desc);
create index if not exists idx_posts_title_trgm         on public.posts using gin (title gin_trgm_ops);

-- Enable trigram extension for fast ilike search
create extension if not exists pg_trgm;


-- ─── ROW LEVEL SECURITY ─────────────────────────────────────────────────────

alter table public.profiles enable row level security;
alter table public.posts    enable row level security;

-- Notes:
--   * `auth.uid()` is set only when the user is signed in.
--   * Supabase, when "Confirm email" is enabled in Auth settings, will NOT
--     issue a usable JWT until the email is confirmed — so any authenticated
--     request implies email is verified.
--   * The university-domain check below uses `auth.jwt() ->> 'email'`.

-- ─── PROFILES POLICIES ──────────────────────────────────────────────────────

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (
    auth.uid() = id
    and (auth.jwt() ->> 'email') ilike '%@lus.ac.bd'
  );

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- No delete policy → nobody can delete their profile manually
-- (auth.users cascade will delete it if the account is removed).


-- ─── POSTS POLICIES ─────────────────────────────────────────────────────────

drop policy if exists "posts_select_authenticated" on public.posts;
create policy "posts_select_authenticated"
  on public.posts for select
  to authenticated
  using (true);

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id);


-- ─── REALTIME ───────────────────────────────────────────────────────────────
-- Enable realtime publication for posts (so the .stream() in Flutter works).

alter publication supabase_realtime add table public.posts;


-- ════════════════════════════════════════════════════════════════════════════
-- STORAGE — DO THIS IN THE STORAGE UI, NOT VIA SQL
-- ════════════════════════════════════════════════════════════════════════════
--
-- In the Supabase dashboard → Storage → New bucket:
--   1. Create bucket "post-images"     — set PUBLIC
--   2. Create bucket "profile-images"  — set PUBLIC
--
-- Then come back here and run the policies below.


-- ─── STORAGE POLICIES ───────────────────────────────────────────────────────

-- post-images: any authenticated user can read; only the owner of the
-- folder (`{userId}/...`) can write/delete.

drop policy if exists "post_images_read"   on storage.objects;
drop policy if exists "post_images_insert" on storage.objects;
drop policy if exists "post_images_delete" on storage.objects;

create policy "post_images_read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'post-images');

create policy "post_images_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "post_images_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- profile-images: any authenticated user can read; users can write only
-- their own file (`{userId}.jpg`).

drop policy if exists "profile_images_read"   on storage.objects;
drop policy if exists "profile_images_upsert" on storage.objects;
drop policy if exists "profile_images_delete" on storage.objects;

create policy "profile_images_read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'profile-images');

create policy "profile_images_upsert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'profile-images'
    and split_part(name, '.', 1) = auth.uid()::text
  );

-- Allow updating (re-uploading) own avatar
drop policy if exists "profile_images_update" on storage.objects;
create policy "profile_images_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'profile-images'
    and split_part(name, '.', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-images'
    and split_part(name, '.', 1) = auth.uid()::text
  );

create policy "profile_images_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'profile-images'
    and split_part(name, '.', 1) = auth.uid()::text
  );

-- ════════════════════════════════════════════════════════════════════════════
-- DONE 🎉
-- Your database is ready. Plug your supabase URL + anon key into
-- lib/config/constants.dart and run the app.
-- ════════════════════════════════════════════════════════════════════════════
