import React, { useState, useEffect, useMemo } from 'react'
import Panel from '../components/Panel.jsx'
import NoteForm from '../components/NoteForm.jsx'
import ProjectForm from '../components/ProjectForm.jsx'
import { id as cryptoId } from '../lib/cryptoId.js'

export default function Dashboard({ email, onLogout }) {
  const [notes, setNotes] = useState([])
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    async function loadData() {
      try {
        setLoading(true)
        const [notesRes, projectsRes] = await Promise.all([
          fetch('/api/notes', { credentials: 'include' }),
          fetch('/api/projects', { credentials: 'include' })
        ])
        const notesData = await notesRes.json()
        const projectsData = await projectsRes.json()
        setNotes(notesData)
        setProjects(projectsData)
      } catch (err) {
        setError('Failed to load data')
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  const stats = useMemo(() => ({
    noteCount: notes.length,
    projectCount: projects.length,
    publicProjects: projects.filter(p => p.visibility === 'public').length,
    tags: Array.from(new Set(notes.flatMap(n => n.tags))).length,
  }), [notes, projects])

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur">
        <div className="mx-auto max-w-6xl px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-2xl bg-emerald-500/90" />
            <div>
              <div className="font-semibold">Devbook</div>
              <div className="text-xs text-slate-400">React UI → Node API → DB</div>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-slate-300">{email}</span>
            <button onClick={onLogout} className="text-sm text-slate-400 hover:text-white">Logout</button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-8 grid lg:grid-cols-3 gap-6">
        <section className="lg:col-span-2 space-y-4">
          {loading ? (
            <p className="text-slate-400">Loading...</p>
          ) : error ? (
            <p className="text-red-400">{error}</p>
          ) : (
            <>
              <Panel title="Notes">
                <NoteForm onAdd={(n) => setNotes([n, ...notes])} />
                <div className="mt-4 grid md:grid-cols-2 gap-3">
                  {notes.map(n => (
                    <div key={n.id} className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
                      <div className="font-semibold">{n.title}</div>
                      <p className="mt-1 text-slate-300 text-sm leading-relaxed">{n.content}</p>
                      <div className="mt-2 flex flex-wrap gap-2">
                        {n.tags.map(t => <span key={t} className="text-xs px-2 py-0.5 rounded-full bg-slate-800 border border-slate-700 text-slate-300">#{t}</span>)}
                      </div>
                    </div>
                  ))}
                </div>
              </Panel>

              <Panel title="Projects">
                <ProjectForm onAdd={(p) => setProjects([p, ...projects])} />
                <div className="mt-4 grid md:grid-cols-2 gap-3">
                  {projects.map(p => (
                    <div key={p.id} className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
                      <div className="flex items-center justify-between">
                        <div className="font-semibold">{p.name}</div>
                        <span className="text-xs px-2 py-0.5 rounded-full border border-slate-700 bg-slate-800 text-slate-300">{p.visibility}</span>
                      </div>
                      <p className="mt-1 text-slate-300 text-sm leading-relaxed">{p.description}</p>
                      {p.links?.length > 0 && (
                        <div className="mt-2 text-sm space-y-1">
                          {p.links.map((l, i) => (
                            <a key={i} href={l} target="_blank" rel="noreferrer" className="block text-emerald-400 hover:underline truncate">{l}</a>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </Panel>
            </>
          )}
        </section>

        <aside className="space-y-4">
          <Panel title="Analytics (demo)">
            <ul className="text-sm text-slate-300 space-y-2">
              <li>Notes: <b>{stats.noteCount}</b></li>
              <li>Projects: <b>{stats.projectCount}</b></li>
              <li>Public projects: <b>{stats.publicProjects}</b></li>
              <li>Unique tags: <b>{stats.tags}</b></li>
            </ul>
          </Panel>
        </aside>
      </main>
    </div>
  )
}
