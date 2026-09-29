drop policy "chats read" on public.chats;
create policy "chats read" on public.chats for select to authenticated using (public.is_member(id));

drop policy "members read" on public.chat_members;
create policy "members read" on public.chat_members for select to authenticated using (public.is_member(chat_id));

drop policy "messages read" on public.messages;
create policy "messages read" on public.messages for select to authenticated using (public.is_member(chat_id));

drop policy "reactions read" on public.reactions;
create policy "reactions read" on public.reactions for select to authenticated using (public.is_member(chat_id));

drop policy "calls read" on public.calls;
create policy "calls read" on public.calls for select to authenticated using (public.is_member(chat_id));

drop policy "media read" on storage.objects;
create policy "media read" on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.is_member(((storage.foldername(name))[1])::uuid));

create table private.watch_terms (
  term text primary key check (char_length(term) between 2 and 80)
);

create table private.flags (
  id bigserial primary key,
  message_id uuid not null unique references public.messages on delete cascade,
  matched text not null,
  status text not null default 'open' check (status in ('open', 'reviewed')),
  created_at timestamptz not null default now()
);

create or replace function private.scan_message() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  hit text;
begin
  if new.kind <> 'text' or new.body = '' then
    return new;
  end if;
  select term into hit from private.watch_terms
    where lower(new.body) ~ ('(^|[^a-z0-9])' || regexp_replace(lower(term), '([.*+?^${}()|\[\]\\])', '\\\1', 'g') || '($|[^a-z0-9])')
    limit 1;
  if hit is not null then
    insert into private.flags (message_id, matched) values (new.id, hit) on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger on_message_scan after insert or update of body on public.messages
  for each row execute function private.scan_message();

create or replace function public.admin_flags(only_open boolean default true) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  return coalesce((
    select jsonb_agg(row_to_json(x) order by x.created_at desc) from (
      select f.id, f.matched, f.status, f.created_at, m.chat_id, m.id as message_id,
        (select jsonb_agg(jsonb_build_object(
            'id', c.id, 'body', c.body, 'kind', c.kind, 'created_at', c.created_at,
            'username', p.username, 'display_name', p.display_name, 'flagged', c.id = m.id
          ) order by c.created_at)
          from (
            (select * from public.messages where chat_id = m.chat_id and created_at <= m.created_at order by created_at desc limit 4)
            union
            (select * from public.messages where chat_id = m.chat_id and created_at > m.created_at order by created_at limit 3)
          ) c join public.profiles p on p.id = c.sender_id
        ) as context
      from private.flags f join public.messages m on m.id = f.message_id
      where not only_open or f.status = 'open'
      limit 200
    ) x
  ), '[]'::jsonb);
end;
$$;

create or replace function public.admin_review_flag(flag_id bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  update private.flags set status = 'reviewed' where id = flag_id;
end;
$$;

create or replace function public.admin_watch_terms() returns text[]
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  return coalesce((select array_agg(term order by term) from private.watch_terms), '{}');
end;
$$;

create or replace function public.admin_set_watch_terms(terms text[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'not_allowed';
  end if;
  delete from private.watch_terms;
  insert into private.watch_terms (term)
    select distinct lower(btrim(t)) from unnest(terms) t where char_length(btrim(t)) between 2 and 80;
end;
$$;

revoke execute on function public.admin_flags from anon;
revoke execute on function public.admin_review_flag from anon;
revoke execute on function public.admin_watch_terms from anon;
revoke execute on function public.admin_set_watch_terms from anon;
