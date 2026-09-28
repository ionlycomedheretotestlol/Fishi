import { memo, useEffect, useRef, useState } from 'react'
import { supabase } from './supabase'

const PAGE = 100
const GROUP_MS = 2 * 60 * 1000

export default function Chat({ room, profile, onBack }) {
  const [messages, setMessages] = useState([])
  const [names, setNames] = useState({ [profile.id]: profile.username })
  const [typing, setTyping] = useState({})
  const [text, setText] = useState('')
  const [loaded, setLoaded] = useState(false)
  const channelRef = useRef(null)
  const lastTypingSent = useRef(0)
  const inputRef = useRef(null)

  async function loadNames(ids) {
    const missing = ids.filter((id) => !(id in names))
    if (!missing.length) return
    const { data } = await supabase.from('profiles').select('id, username').in('id', missing)
    if (data) setNames((n) => ({ ...n, ...Object.fromEntries(data.map((p) => [p.id, p.username])) }))
  }

  useEffect(() => {
    supabase
      .from('messages')
      .select('*')
      .eq('room_id', room.id)
      .order('created_at', { ascending: false })
      .limit(PAGE)
      .then(({ data }) => {
        if (data) {
          setMessages((cur) => mergeMessages(data, cur))
          loadNames([...new Set(data.map((m) => m.user_id))])
        }
        setLoaded(true)
      })

    const channel = supabase
      .channel(`room:${room.id}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `room_id=eq.${room.id}` },
        ({ new: m }) => {
          setMessages((cur) => mergeMessages([{ ...m, fresh: true }], cur))
          loadNames([m.user_id])
          setTyping((t) => {
            if (!t[m.user_id]) return t
            const next = { ...t }
            delete next[m.user_id]
            return next
          })
        },
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'messages' },
        ({ old }) => setMessages((cur) => cur.filter((m) => m.id !== old.id)),
      )
      .on('broadcast', { event: 'typing' }, ({ payload }) => {
        if (payload.id === profile.id) return
        setTyping((t) => ({ ...t, [payload.id]: { name: payload.name, at: Date.now() } }))
      })
      .subscribe()

    channelRef.current = channel
    const sweep = setInterval(() => {
      setTyping((t) => {
        const now = Date.now()
        const next = Object.fromEntries(Object.entries(t).filter(([, v]) => now - v.at < 3000))
        return Object.keys(next).length === Object.keys(t).length ? t : next
      })
    }, 1000)

    return () => {
      clearInterval(sweep)
      supabase.removeChannel(channel)
    }
  }, [room.id])

  function onType(e) {
    setText(e.target.value)
    const now = Date.now()
    if (now - lastTypingSent.current > 1500 && e.target.value) {
      lastTypingSent.current = now
      channelRef.current?.send({ type: 'broadcast', event: 'typing', payload: { id: profile.id, name: profile.username } })
    }
  }

  async function send(e) {
    e?.preventDefault()
    const body = text.trim()
    if (!body) return
    const msg = {
      id: crypto.randomUUID(),
      room_id: room.id,
      user_id: profile.id,
      body,
      created_at: new Date().toISOString(),
      pending: true,
      fresh: true,
    }
    setText('')
    lastTypingSent.current = 0
    setMessages((cur) => [msg, ...cur])

    const { error } = await supabase.from('messages').insert({ id: msg.id, room_id: msg.room_id, body })
    setMessages((cur) =>
      cur.map((m) => (m.id === msg.id ? { ...m, pending: false, failed: !!error } : m)),
    )
  }

  function retry(msg) {
    setMessages((cur) => cur.filter((m) => m.id !== msg.id))
    setText(msg.body)
    inputRef.current?.focus()
  }

  function onKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault()
      send()
    }
  }

  const typers = Object.values(typing).map((t) => t.name)

  return (
    <section className="chat">
      <header>
        <button className="back" onClick={onBack} aria-label="Back">
          <svg viewBox="0 0 24 24" width="24" height="24"><path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </button>
        <h2>{room.name}</h2>
      </header>

      <div className="messages">
        <div className={typers.length ? 'typing show' : 'typing'}>
          <span className="dots"><i /><i /><i /></span>
          {typers.length > 0 && <span className="typing-name">{typers.join(', ')}</span>}
        </div>
        {messages.map((m, i) => {
          const newer = messages[i - 1]
          const older = messages[i + 1]
          const mine = m.user_id === profile.id
          const firstOfGroup = !older || older.user_id !== m.user_id || gap(older, m)
          const lastOfGroup = !newer || newer.user_id !== m.user_id || gap(m, newer)
          return (
            <Bubble
              key={m.id}
              m={m}
              mine={mine}
              name={!mine && firstOfGroup ? names[m.user_id] : null}
              tail={lastOfGroup}
              onRetry={retry}
            />
          )
        })}
        {loaded && messages.length === 0 && <p className="hint">Say hi</p>}
      </div>

      <form className="composer" onSubmit={send}>
        <textarea
          ref={inputRef}
          rows={1}
          placeholder="Message"
          value={text}
          onChange={onType}
          onKeyDown={onKeyDown}
          maxLength={4000}
        />
        <button
          className={text.trim() ? 'send ready' : 'send'}
          onPointerDown={(e) => e.preventDefault()}
          aria-label="Send"
        >
          <svg viewBox="0 0 24 24" width="18" height="18"><path d="M12 19V5M5 12l7-7 7 7" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </button>
      </form>
    </section>
  )
}

const Bubble = memo(function Bubble({ m, mine, name, tail, onRetry }) {
  return (
    <div className={`row ${mine ? 'mine' : 'theirs'}${tail ? ' tail' : ''}${m.fresh ? ' fresh' : ''}`}>
      {name && <span className="sender">{name}</span>}
      <div
        className={`bubble${m.pending ? ' pending' : ''}${m.failed ? ' failed' : ''}`}
        title={new Date(m.created_at).toLocaleString()}
      >
        {m.body}
      </div>
      {m.failed && (
        <button className="retry" onClick={() => onRetry(m)}>
          Not sent. Tap to edit
        </button>
      )}
    </div>
  )
})

function gap(a, b) {
  return Math.abs(new Date(b.created_at) - new Date(a.created_at)) > GROUP_MS
}

function mergeMessages(incoming, current) {
  const byId = new Map(current.map((m) => [m.id, m]))
  for (const m of incoming) {
    const existing = byId.get(m.id)
    byId.set(m.id, existing ? { ...existing, ...m, fresh: existing.fresh, pending: false, failed: false } : m)
  }
  return [...byId.values()].sort((a, b) => (a.created_at < b.created_at ? 1 : -1))
}
