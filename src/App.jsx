import { useEffect, useState } from 'react'
import { supabase } from './supabase'
import Login from './Login'
import Rooms from './Rooms'
import Chat from './Chat'

export default function App() {
  const [session, setSession] = useState(undefined)
  const [profile, setProfile] = useState(undefined)
  const [room, setRoom] = useState(null)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data } = supabase.auth.onAuthStateChange((_e, s) => setSession(s))
    return () => data.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!session) {
      setProfile(session === null ? null : undefined)
      return
    }
    supabase
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .maybeSingle()
      .then(({ data }) => setProfile(data))
  }, [session])

  if (session === undefined || profile === undefined) return <div className="splash" />
  if (!session || !profile) return <Login session={session} onDone={setProfile} />

  return (
    <div className={open ? 'app in-room' : 'app'}>
      <Rooms
        profile={profile}
        active={room}
        onSelect={(r) => {
          setRoom(r)
          setOpen(true)
        }}
      />
      {room ? (
        <Chat key={room.id} room={room} profile={profile} onBack={() => setOpen(false)} />
      ) : (
        <div className="empty-pane">Pick a chat</div>
      )}
    </div>
  )
}
