import React, { useState } from 'react'
import { id as cryptoId } from '../lib/cryptoId.js'

export default function NoteForm({ onAdd }) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  async function submit(e) {
    e.preventDefault()
    const fd = new FormData(e.currentTarget)
    const title = String(fd.get('title') || '').trim()
    const content = String(fd.get('content') || '').trim()
    const tags = String(fd.get('tags') || '').split(',').map(s => s.trim()).filter(Boolean)
    if (!title) return

    const tempNote = { id: cryptoId(), title, content, tags }
    onAdd(tempNote) // optimistic update

    try {
      setLoading(true)
      setError(null)
      const res = await fetch('/api/notes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ title, content, tags })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || 'Failed to add note')
      // optionally refresh list or reconcile IDs
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
      e.currentTarget.reset()
    }
  }

  return (
    <form onSubmit={submit} className="grid md:grid-cols-5 gap-2 mt-2">
      <input name="title" placeholder="Note title"
        className="md:col-span-1 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />
      <input name="content" placeholder="What’s on your mind?"
        className="md:col-span-3 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />
      <input name="tags" placeholder="tags: demo, ideas"
        className="md:col-span-1 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />

      <div className="md:col-span-5 flex justify-end">
        <button
          disabled={loading}
          className="px-4 py-2 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-black font-medium disabled:opacity-50"
        >
          {loading ? 'Adding...' : 'Add note'}
        </button>
      </div>

      {error && <p className="text-red-400 text-sm md:col-span-5">{error}</p>}
    </form>
  )
}
