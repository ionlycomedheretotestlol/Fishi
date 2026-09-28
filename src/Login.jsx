import { useState } from 'react'
import { supabase } from './supabase'

export default function Login({ session, onDone }) {
  const [name, setName] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  async function submit(e) {
    e.preventDefault()
    const username = name.trim()
    if (!username || busy) return
    setBusy(true)
    setError('')

    let user = session?.user
    if (!user) {
      const { data, error } = await supabase.auth.signInAnonymously()
      if (error) {
        setError(error.message)
        setBusy(false)
        return
      }
      user = data.user
    }

    const { data, error } = await supabase
      .from('profiles')
      .upsert({ id: user.id, username })
      .select()
      .single()

    if (error) {
      setError(error.message)
      setBusy(false)
      return
    }
    onDone(data)
  }

  return (
    <form className="login" onSubmit={submit}>
      <h1>Fishi</h1>
      <input
        autoFocus
        maxLength={32}
        placeholder="Your name"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <button disabled={!name.trim() || busy}>{busy ? 'Joining' : 'Continue'}</button>
      {error && <p className="error">{error}</p>}
    </form>
  )
}
