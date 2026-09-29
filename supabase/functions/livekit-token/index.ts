import { createClient } from 'npm:@supabase/supabase-js@2'
import { AccessToken } from 'npm:livekit-server-sdk@2'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  const auth = req.headers.get('Authorization') ?? ''
  const supa = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: auth } },
  })
  const { data: { user } } = await supa.auth.getUser(auth.replace('Bearer ', ''))
  if (!user) return json({ error: 'unauthorized' }, 401)

  const { chat_id } = await req.json()
  const { data: member } = await supa.rpc('is_member', { chat: chat_id })
  if (!member) return json({ error: 'not_member' }, 403)

  const { data: profile } = await supa.from('profiles').select('display_name').eq('id', user.id).single()
  const token = new AccessToken(Deno.env.get('LIVEKIT_API_KEY')!, Deno.env.get('LIVEKIT_API_SECRET')!, {
    identity: user.id,
    name: profile?.display_name ?? '',
    ttl: '2h',
  })
  token.addGrant({ roomJoin: true, room: chat_id, canPublish: true, canSubscribe: true })

  return json({ token: await token.toJwt(), url: Deno.env.get('LIVEKIT_URL') })
})
