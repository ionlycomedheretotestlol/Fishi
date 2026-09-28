import { useEffect, useState } from 'react'
import { supabase } from './supabase'

export default function Rooms({ profile, active, onSelect }) {
  const [rooms, setRooms] = useState([])
  const [name, setName] = useState('')

  useEffect(() => {
    supabase
      .from('rooms')
      .select('*')
      .order('created_at', { ascending: false })
      .then(({ data }) => data && setRooms(data))

    const channel = supabase
      .channel('rooms')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'rooms' }, ({ new: room }) =>
        setRooms((list) => (list.some((r) => r.id === room.id) ? list : [room, ...list])),
      )
      .subscribe()
    return () => supabase.removeChannel(channel)
  }, [])

  async function create(e) {
    e.preventDefault()
    const n = name.trim()
    if (!n) return
    const room = { id: crypto.randomUUID(), name: n, created_by: profile.id, created_at: new Date().toISOString() }
    setName('')
    setRooms((list) => [room, ...list])
    onSelect(room)
    const { error } = await supabase.from('rooms').insert({ id: room.id, name: room.name })
    if (error) setRooms((list) => list.filter((r) => r.id !== room.id))
  }

  return (
    <aside className="rooms">
      <header>
        <h2>Chats</h2>
        <span className="me">{profile.username}</span>
      </header>
      <form className="new-room" onSubmit={create}>
        <input placeholder="New chat" maxLength={48} value={name} onChange={(e) => setName(e.target.value)} />
      </form>
      <ul>
        {rooms.map((r) => (
          <li key={r.id}>
            <button className={active?.id === r.id ? 'room active' : 'room'} onClick={() => onSelect(r)}>
              <span className="avatar">{r.name[0].toUpperCase()}</span>
              <span className="room-name">{r.name}</span>
            </button>
          </li>
        ))}
      </ul>
    </aside>
  )
}
