import React, { useState } from 'react'
import { id as cryptoId } from '../lib/cryptoId.js'

export default function ProjectForm({ onAdd }) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  async function submit(e) {
    e.preventDefault()
    const fd = new FormData(e.currentTarget)
    const name = String(fd.get('name') || '').trim()
    const description = String(fd.get('description') || '').trim()
    const links = String(fd.get('links') || '').split(',').map(s => s.trim()).filter(Boolean)
    const visibility = String(fd.get('visibility') || 'private')
    if (!name) return

    const tempProject = { id: cryptoId(), name, description, links, visibility }
    onAdd(tempProject) // optimistic UI

    try {
      setLoading(true)
      setError(null)
      const res = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ name, description, links, visibility })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || 'Failed to add project')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
      e.currentTarget.reset()
    }
  }

  return (
    <form onSubmit={submit} className="grid md:grid-cols-5 gap-2 mt-2">
      <input name="name" placeholder="Project name"
        className="md:col-span-1 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />
      <input name="description" placeholder="Short description"
        className="md:col-span-2 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />
      <input name="links" placeholder="Links (comma-separated)"
        className="md:col-span-1 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500" />
      <select name="visibility"
        className="md:col-span-1 rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 outline-none focus:ring-2 focus:ring-emerald-500">
        <option value="private">private</option>
        <option value="public">public</option>
      </select>

      <div className="md:col-span-5 flex justify-end">
        <button
          disabled={loading}
          className="px-4 py-2 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-black font-medium disabled:opacity-50"
        >
          {loading ? 'Adding...' : 'Add project'}
        </button>
      </div>

      {error && <p className="text-red-400 text-sm md:col-span-5">{error}</p>}
    </form>
  )
}
