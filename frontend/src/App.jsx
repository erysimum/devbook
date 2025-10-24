import React, { useState } from 'react'
import Landing from './pages/Landing.jsx'
import Auth from './pages/Auth.jsx'
import Dashboard from './pages/Dashboard.jsx'

export default function App(){
  const [view, setView] = useState('landing') // 'landing' | 'auth' | 'app'
  const [email, setEmail] = useState(null)

  if (view === 'landing') return (
    <Landing onGetStarted={()=>setView('auth')} onLoginLink={()=>setView('auth')} />
  )
  if (view === 'auth') return (
    <Auth onAuthed={(e)=>{ setEmail(e); setView('app') }} onBack={()=>setView('landing')} />
  )
  return <Dashboard email={email} onLogout={()=>{ setEmail(null); setView('landing') }} />
}
