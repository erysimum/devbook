import React, { useState } from 'react'

export default function Auth({ onAuthed, onBack }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  async function handleSubmit(e, endpoint) {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const res = await fetch(`/api/auth/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
        credentials: 'include' // important! keeps cookie
      })
      const data = await res.json()

      if (!res.ok) throw new Error(data.error || 'Auth failed')
      onAuthed(data.email) // triggers setEmail + setView('app')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen grid place-items-center bg-slate-950 text-white px-6">
      <div className="w-full max-w-md rounded-3xl border border-slate-800 bg-slate-900 p-6 shadow-2xl">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-semibold">Login / Signup</h2>
          <button onClick={onBack} className="text-slate-400 hover:text-white text-sm">← Back</button>
        </div>
        <form className="space-y-4">
          <div>
            <label className="block text-sm text-slate-400">Email</label>
            <input
              name="email" type="email" required value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 w-full rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500"
              placeholder="you@devbook.com"
            />
          </div>
          <div>
            <label className="block text-sm text-slate-400">Password</label>
            <input
              name="password" type="password" required value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500"
              placeholder="••••••••"
            />
          </div>

          {error && <p className="text-red-400 text-sm">{error}</p>}

          <div className="flex justify-between gap-3">
            <button
              disabled={loading}
              onClick={(e) => handleSubmit(e, 'login')}
              className="flex-1 px-4 py-2 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-black font-medium disabled:opacity-50"
            >
              {loading ? 'Loading...' : 'Login'}
            </button>
            <button
              disabled={loading}
              onClick={(e) => handleSubmit(e, 'signup')}
              className="flex-1 px-4 py-2 rounded-2xl bg-slate-700 hover:bg-slate-600 text-white font-medium disabled:opacity-50"
            >
              {loading ? 'Loading...' : 'Signup'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
