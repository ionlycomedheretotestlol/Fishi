create extension if not exists pgcrypto;
create schema if not exists private;

create table private.staff (
  user_id uuid primary key references auth.users on delete cascade
);

create table private.finn_config (
  id int primary key default 1 check (id = 1),
  api_key text,
  endpoint text not null default 'https://openrouter.ai/api/v1',
  model text not null default 'stealth/space-bunny-alpha',
  audio_model text not null default 'google/gemini-3.8-flash',
  system_prompt text,
  updated_at timestamptz not null default now()
);
insert into private.finn_config (id) values (1) on conflict do nothing;

create table private.finn_memory (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  fact text not null check (char_length(fact) <= 500),
  created_at timestamptz not null default now()
);
create index on private.finn_memory (user_id);

create table private.reserved_usernames (name text primary key);
insert into private.reserved_usernames (name) values
  ('fishi'), ('finn'), ('admin'), ('administrator'), ('official'), ('support'), ('staff'),
  ('moderator'), ('mod'), ('system'), ('root'), ('help'), ('security'), ('team'),
  ('fishiapp'), ('fishi_app'), ('fishiofficial'), ('fishi_official'), ('fishi_team'),
  ('fishi_support'), ('finn_ai'), ('finnai'), ('everyone'), ('here'), ('null'), ('undefined');

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.staff where user_id = auth.uid());
$$;

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null check (char_length(btrim(display_name)) between 1 and 40),
  bio text not null default '' check (char_length(bio) <= 160),
  avatar_path text,
  bubble jsonb not null default '{"shape":"classic","color":null}',
  badges text[] not null default '{}',
  is_bot boolean not null default false,
  last_seen timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create or replace function public.username_available(name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select lower(name) ~ '^[a-z0-9_]{3,20}$'
    and lower(name) !~ '^_|_$|__'
    and not exists (select 1 from private.reserved_usernames r where r.name = lower($1))
    and not exists (select 1 from public.profiles p where p.username = lower($1));
$$;

create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  uname text := lower(coalesce(new.raw_user_meta_data ->> 'username', ''));
  dname text := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
begin
  if coalesce((new.raw_app_meta_data ->> 'seeded')::boolean, false) then
    return new;
  end if;
  if not public.username_available(uname) then
    raise exception 'username_unavailable';
  end if;
  if char_length(dname) = 0 then
    dname := uname;
  end if;
  insert into public.profiles (id, username, display_name) values (new.id, uname, dname);
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

create table public.chats (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct', 'group', 'finn')),
  name text check (name is null or char_length(btrim(name)) between 1 and 48),
  avatar_path text,
  direct_key text unique,
  created_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.chat_members (
  chat_id uuid not null references public.chats on delete cascade,
  user_id uuid not null references public.profiles on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  last_read_at timestamptz not null default now(),
  muted boolean not null default false,
  pinned boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (chat_id, user_id)
);
create index on public.chat_members (user_id);

create or replace function public.is_member(chat uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.chat_members where chat_id = chat and user_id = auth.uid());
$$;

create or replace function public.shares_chat(other uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chat_members a
    join public.chat_members b on a.chat_id = b.chat_id
    where a.user_id = auth.uid() and b.user_id = other
  );
$$;

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles on delete cascade,
  kind text not null default 'text' check (kind in ('text', 'image', 'video', 'audio', 'system', 'call')),
  body text not null default '' check (char_length(body) <= 8000),
  media_path text,
  media_meta jsonb,
  reply_to uuid references public.messages on delete set null,
  mentions uuid[] not null default '{}',
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.messages (chat_id, created_at desc);

create table public.reactions (
  message_id uuid not null references public.messages on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles on delete cascade,
  chat_id uuid not null references public.chats on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats on delete cascade,
  started_by uuid not null default auth.uid() references public.profiles on delete cascade,
  video boolean not null default false,
  status text not null default 'ringing' check (status in ('ringing', 'active', 'ended', 'missed', 'declined')),
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 80),
  body text not null check (char_length(body) between 1 and 4000),
  created_by uuid default auth.uid() references public.profiles on delete set null,
  created_at timestamptz not null default now()
);

create or replace function private.touch_chat() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.chats set last_message_at = new.created_at where id = new.chat_id;
  return new;
end;
$$;
create trigger on_message_insert after insert on public.messages
  for each row execute function private.touch_chat();

alter table public.profiles enable row level security;
alter table public.chats enable row level security;
alter table public.chat_members enable row level security;
alter table public.messages enable row level security;
alter table public.reactions enable row level security;
alter table public.calls enable row level security;
alter table public.announcements enable row level security;

create policy "profiles read" on public.profiles for select to authenticated using (true);
create policy "profiles update own" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated, anon;
grant update (display_name, bio, avatar_path, bubble, last_seen) on public.profiles to authenticated;
revoke insert, delete on public.profiles from authenticated, anon;

create policy "chats read" on public.chats for select to authenticated
  using (public.is_member(id) or public.is_admin());
create policy "chats update group" on public.chats for update to authenticated
  using (kind = 'group' and exists (
    select 1 from public.chat_members m where m.chat_id = id and m.user_id = auth.uid() and m.role in ('owner', 'admin')
  ));
revoke insert, delete on public.chats from authenticated, anon;
revoke update on public.chats from authenticated, anon;
grant update (name, avatar_path) on public.chats to authenticated;

create policy "members read" on public.chat_members for select to authenticated
  using (public.is_member(chat_id) or public.is_admin());
create policy "members update own" on public.chat_members for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
revoke insert, delete, update on public.chat_members from authenticated, anon;
grant update (last_read_at, muted, pinned) on public.chat_members to authenticated;

create policy "messages read" on public.messages for select to authenticated
  using (public.is_member(chat_id) or public.is_admin());
create policy "messages insert" on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.is_member(chat_id) and kind <> 'system');
create policy "messages update own" on public.messages for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());
revoke update on public.messages from authenticated, anon;
grant update (body, edited_at, deleted_at) on public.messages to authenticated;
revoke delete on public.messages from authenticated, anon;

create policy "reactions read" on public.reactions for select to authenticated
  using (public.is_member(chat_id) or public.is_admin());
create policy "reactions write" on public.reactions for insert to authenticated
  with check (user_id = auth.uid() and public.is_member(chat_id));
create policy "reactions change" on public.reactions for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "reactions delete" on public.reactions for delete to authenticated
  using (user_id = auth.uid());

create policy "calls read" on public.calls for select to authenticated
  using (public.is_member(chat_id) or public.is_admin());
create policy "calls insert" on public.calls for insert to authenticated
  with check (started_by = auth.uid() and public.is_member(chat_id));
create policy "calls update" on public.calls for update to authenticated
  using (public.is_member(chat_id));

create policy "announcements read" on public.announcements for select to authenticated using (true);
create policy "announcements insert" on public.announcements for insert to authenticated with check (public.is_admin());
create policy "announcements delete" on public.announcements for delete to authenticated using (public.is_admin());

create or replace function public.finn_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select id from public.profiles where username = 'finn';
$$;

create or replace function public.open_direct(other uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  key text;
  cid uuid;
begin
  if me is null or other is null or other = me then
    raise exception 'invalid_user';
  end if;
  if not exists (select 1 from public.profiles where id = other) then
    raise exception 'invalid_user';
  end if;
  if other = public.finn_id() then
    return public.open_finn();
  end if;
  key := least(me::text, other::text) || ':' || greatest(me::text, other::text);
  select id into cid from public.chats where direct_key = key;
  if cid is null then
    insert into public.chats (kind, direct_key, created_by) values ('direct', key, me) returning id into cid;
    insert into public.chat_members (chat_id, user_id) values (cid, me), (cid, other);
  end if;
  return cid;
end;
$$;

create or replace function public.open_finn() returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  finn uuid := public.finn_id();
  key text;
  cid uuid;
begin
  if me is null then
    raise exception 'not_signed_in';
  end if;
  key := 'finn:' || me::text;
  select id into cid from public.chats where direct_key = key;
  if cid is null then
    insert into public.chats (kind, direct_key, created_by) values ('finn', key, me) returning id into cid;
    insert into public.chat_members (chat_id, user_id) values (cid, me), (cid, finn);
  end if;
  return cid;
end;
$$;

create or replace function public.create_group(group_name text, member_ids uuid[]) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  cid uuid;
begin
  if me is null then
    raise exception 'not_signed_in';
  end if;
  insert into public.chats (kind, name, created_by) values ('group', btrim(group_name), me) returning id into cid;
  insert into public.chat_members (chat_id, user_id, role) values (cid, me, 'owner');
  insert into public.chat_members (chat_id, user_id)
    select cid, p.id from public.profiles p
    where p.id = any(member_ids) and p.id <> me
    on conflict do nothing;
  insert into public.messages (chat_id, sender_id, kind, body) values (cid, me, 'system', 'created the group');
  return cid;
end;
$$;

create or replace function public.add_group_members(chat uuid, member_ids uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.chat_members m join public.chats c on c.id = m.chat_id
    where m.chat_id = chat and m.user_id = auth.uid() and m.role in ('owner', 'admin') and c.kind = 'group'
  ) then
    raise exception 'not_allowed';
  end if;
  insert into public.chat_members (chat_id, user_id)
    select chat, p.id from public.profiles p where p.id = any(member_ids)
    on conflict do nothing;
  insert into public.messages (chat_id, sender_id, kind, body) values (chat, auth.uid(), 'system', 'added people');
end;
$$;

create or replace function public.leave_group(chat uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.chats where id = chat and kind = 'group') then
    raise exception 'not_allowed';
  end if;
  insert into public.messages (chat_id, sender_id, kind, body) values (chat, auth.uid(), 'system', 'left the group');
  delete from public.chat_members where chat_id = chat and user_id = auth.uid();
end;
$$;

create or replace function public.admin_set_finn_config(
  new_api_key text default null,
  new_endpoint text default null,
  new_model text default null,
  new_audio_model text default null,
  new_system_prompt text default null
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  update private.finn_config set
    api_key = coalesce(nullif(new_api_key, ''), api_key),
    endpoint = coalesce(nullif(new_endpoint, ''), endpoint),
    model = coalesce(nullif(new_model, ''), model),
    audio_model = coalesce(nullif(new_audio_model, ''), audio_model),
    system_prompt = case when new_system_prompt is null then system_prompt else nullif(new_system_prompt, '') end,
    updated_at = now()
  where id = 1;
end;
$$;

create or replace function public.admin_get_finn_config() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  c private.finn_config;
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  select * into c from private.finn_config where id = 1;
  return jsonb_build_object(
    'endpoint', c.endpoint,
    'model', c.model,
    'audio_model', c.audio_model,
    'system_prompt', c.system_prompt,
    'has_key', c.api_key is not null,
    'key_hint', case when c.api_key is null then null else '...' || right(c.api_key, 4) end,
    'updated_at', c.updated_at
  );
end;
$$;

create or replace function public.admin_set_badges(target uuid, new_badges text[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  update public.profiles set badges = new_badges where id = target;
end;
$$;

create or replace function public.admin_stats() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  return jsonb_build_object(
    'users', (select count(*) from public.profiles where not is_bot),
    'chats', (select count(*) from public.chats),
    'messages', (select count(*) from public.messages),
    'messages_today', (select count(*) from public.messages where created_at > now() - interval '1 day'),
    'active_today', (select count(*) from public.profiles where last_seen > now() - interval '1 day')
  );
end;
$$;

revoke execute on function public.admin_set_finn_config from anon;
revoke execute on function public.admin_get_finn_config from anon;
revoke execute on function public.admin_set_badges from anon;
revoke execute on function public.admin_stats from anon;

insert into storage.buckets (id, name, public) values ('media', 'media', false) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true) on conflict do nothing;

create policy "media read" on storage.objects for select to authenticated
  using (bucket_id = 'media' and (public.is_member(((storage.foldername(name))[1])::uuid) or public.is_admin()));
create policy "media upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_member(((storage.foldername(name))[1])::uuid));
create policy "avatars upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

alter publication supabase_realtime add table
  public.messages, public.reactions, public.chats, public.chat_members, public.calls, public.announcements, public.profiles;
