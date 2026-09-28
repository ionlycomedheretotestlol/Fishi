create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null check (char_length(username) between 1 and 32),
  created_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 48),
  created_by uuid references public.profiles on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms on delete cascade,
  user_id uuid not null references public.profiles on delete cascade default auth.uid(),
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index if not exists messages_room_created_idx on public.messages (room_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.messages enable row level security;

create policy "profiles readable" on public.profiles for select to authenticated using (true);
create policy "own profile insert" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "own profile update" on public.profiles for update to authenticated using (id = auth.uid());

create policy "rooms readable" on public.rooms for select to authenticated using (true);
create policy "rooms insert" on public.rooms for insert to authenticated with check (created_by = auth.uid());

create policy "messages readable" on public.messages for select to authenticated using (true);
create policy "messages insert" on public.messages for insert to authenticated with check (user_id = auth.uid());
create policy "own messages delete" on public.messages for delete to authenticated using (user_id = auth.uid());

alter publication supabase_realtime add table public.messages, public.rooms;
