create table private.age_asks (
  chat_id uuid primary key references public.chats on delete cascade,
  asker uuid not null,
  asked_at timestamptz not null default now()
);

create or replace function private.scan_age() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  text_l text := lower(new.body);
  ask private.age_asks;
  age int;
begin
  if new.kind <> 'text' or new.body = '' then
    return new;
  end if;

  if text_l ~ '(how\s*old|\mhoru\M|\mhru\s*old|(\mur|\myour|\mu\s*r)\s+age\M|\mage\s*\?|\masl\M)' then
    insert into private.age_asks (chat_id, asker, asked_at) values (new.chat_id, new.sender_id, now())
      on conflict (chat_id) do update set asker = excluded.asker, asked_at = excluded.asked_at;
    return new;
  end if;

  age := nullif(substring(text_l from '\m(?:i''?m|i\s+am|im)\s+(\d{1,2})\M'), '')::int;

  if age is null then
    select * into ask from private.age_asks where chat_id = new.chat_id;
    if ask.chat_id is not null and ask.asker <> new.sender_id and ask.asked_at > now() - interval '1 hour'
       and char_length(new.body) <= 60 then
      age := nullif(substring(text_l from '\m(\d{1,2})\M'), '')::int;
      if age is not null then
        delete from private.age_asks where chat_id = new.chat_id;
      end if;
    end if;
  end if;

  if age is not null and age between 5 and 17 then
    insert into private.flags (message_id, matched) values (new.id, 'said they are ' || age)
      on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger on_message_age after insert on public.messages
  for each row execute function private.scan_age();

alter table public.profiles add column adult_confirmed_at timestamptz;
grant update (adult_confirmed_at) on public.profiles to authenticated;
