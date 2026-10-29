-- ════════════════════════════════════════════════════════════════════════════
-- UniFind — Messaging Feature Migration
-- ════════════════════════════════════════════════════════════════════════════
--
-- HOW TO RUN:
--   1. Supabase Dashboard → SQL Editor → New query
--   2. Paste this entire file → Run
--
-- IMPORTANT: Run AFTER supabase_setup.sql (the base tables must exist first)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── CONVERSATIONS TABLE ────────────────────────────────────────────────────

create table if not exists public.conversations (
  id              uuid primary key default gen_random_uuid(),
  user1_id        uuid not null references public.profiles(id) on delete cascade,
  user2_id        uuid not null references public.profiles(id) on delete cascade,
  last_message     text,
  last_message_at  timestamptz default now(),
  created_at       timestamptz not null default now(),
  constraint unique_conversation unique (user1_id, user2_id),
  constraint no_self_chat check (user1_id <> user2_id)
);

create index if not exists idx_conversations_user1 on public.conversations(user1_id);
create index if not exists idx_conversations_user2 on public.conversations(user2_id);
create index if not exists idx_conversations_last_msg on public.conversations(last_message_at desc);


-- ─── MESSAGES TABLE ─────────────────────────────────────────────────────────

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  content         text not null,
  is_read         boolean not null default false,
  created_at      timestamptz not null default now()
);

create index if not exists idx_messages_conversation on public.messages(conversation_id, created_at desc);
create index if not exists idx_messages_sender on public.messages(sender_id);


-- ─── ROW LEVEL SECURITY ─────────────────────────────────────────────────────

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- CONVERSATIONS policies — users can only see/modify their own conversations

drop policy if exists "conversations_select_own" on public.conversations;
create policy "conversations_select_own"
  on public.conversations for select
  to authenticated
  using (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "conversations_insert_own" on public.conversations;
create policy "conversations_insert_own"
  on public.conversations for insert
  to authenticated
  with check (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "conversations_update_own" on public.conversations;
create policy "conversations_update_own"
  on public.conversations for update
  to authenticated
  using (auth.uid() = user1_id or auth.uid() = user2_id)
  with check (auth.uid() = user1_id or auth.uid() = user2_id);

-- MESSAGES policies — users can only see/send in their own conversations

drop policy if exists "messages_select_own" on public.messages;
create policy "messages_select_own"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  );

drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own"
  on public.messages for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  );

drop policy if exists "messages_update_read" on public.messages;
create policy "messages_update_read"
  on public.messages for update
  to authenticated
  using (
    sender_id <> auth.uid()  -- only the receiver can mark as read
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  )
  with check (
    sender_id <> auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  );


-- ─── HELPER FUNCTION: get or create conversation ────────────────────────────

create or replace function public.get_or_create_conversation(
  p_user1 uuid,
  p_user2 uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_a uuid := least(p_user1, p_user2);
  v_b uuid := greatest(p_user1, p_user2);
begin
  -- Try to find existing conversation (order-independent)
  select id into v_id
  from public.conversations
  where (user1_id = v_a and user2_id = v_b)
     or (user1_id = v_b and user2_id = v_a)
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  -- Create new conversation (always store smaller uuid as user1)
  insert into public.conversations (user1_id, user2_id)
  values (v_a, v_b)
  returning id into v_id;

  return v_id;
end;
$$;


-- ─── REALTIME ───────────────────────────────────────────────────────────────

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;


-- ─── VERIFY ─────────────────────────────────────────────────────────────────
-- Run these to confirm:
--   select table_name from information_schema.tables where table_schema='public';
--   Expected: profiles, posts, conversations, messages
--
--   select policyname from pg_policies where tablename in ('conversations','messages');
--   Expected: 6 policies (3 conversations + 3 messages)

-- ════════════════════════════════════════════════════════════════════════════
-- DONE. Messaging tables are ready.
-- ════════════════════════════════════════════════════════════════════════════
