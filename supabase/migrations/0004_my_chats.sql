create or replace function public.my_chats() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(x order by x ->> 'last_message_at' desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', c.id,
      'kind', c.kind,
      'name', c.name,
      'avatar_path', c.avatar_path,
      'last_message_at', c.last_message_at,
      'muted', m.muted,
      'pinned', m.pinned,
      'last_read_at', m.last_read_at,
      'other', (
        select to_jsonb(p) from public.chat_members o join public.profiles p on p.id = o.user_id
        where o.chat_id = c.id and o.user_id <> auth.uid() and c.kind <> 'group' limit 1
      ),
      'member_count', (select count(*) from public.chat_members where chat_id = c.id),
      'last', (
        select jsonb_build_object('body', lm.body, 'kind', lm.kind, 'sender_id', lm.sender_id,
          'created_at', lm.created_at, 'deleted', lm.deleted_at is not null)
        from public.messages lm where lm.chat_id = c.id order by lm.created_at desc limit 1
      ),
      'unread', (
        select count(*) from public.messages um
        where um.chat_id = c.id and um.created_at > m.last_read_at and um.sender_id <> auth.uid()
      )
    ) as x
    from public.chat_members m join public.chats c on c.id = m.chat_id
    where m.user_id = auth.uid()
  ) s;
$$;
revoke execute on function public.my_chats from anon;
