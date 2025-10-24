import React from 'react'

export default function Landing({ onGetStarted, onLoginLink }){
  return (
    <div className="min-h-screen grid place-items-center bg-slate-950 text-white px-6">
      <div className="w-full max-w-5xl grid md:grid-cols-2 gap-8 items-center">
        <div className="space-y-4">
          <h1 className="text-4xl md:text-5xl font-bold">Devbook</h1>
          <p className="text-slate-300 leading-relaxed">
            A clean three-tier demo: <b>React UI</b> → <b>Node.js API</b> → <b>Database</b>.
            Sign up, jot notes, and showcase projects. Add an analytics worker later for event-driven insights.
          </p>
          <div className="flex gap-3">
            <button onClick={onGetStarted} className="px-4 py-2 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-black font-medium shadow">Get started</button>
            <button onClick={onLoginLink} className="px-4 py-2 rounded-2xl bg-slate-700 hover:bg-slate-600 font-medium">I have an account</button>
          </div>
          <ul className="text-slate-400 text-sm list-disc pl-6 space-y-1 pt-2">
            <li>Zero-downtime rollouts</li>
            <li>Hardened pods (non-root, read-only FS, no caps)</li>
            <li>ALB Ingress, TLS via ACM, NetworkPolicies</li>
            <li>HPA + Karpenter for scale, Argo for GitOps</li>
          </ul>
        </div>

        <div className="rounded-3xl border border-slate-700/60 bg-slate-900/60 backdrop-blur p-6 shadow-xl">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-2xl bg-emerald-500/90" />
            <div>
              <div className="font-semibold">Devbook</div>
              <div className="text-xs text-slate-400">Minimal demo preview</div>
            </div>
          </div>
          <div className="mt-3 text-sm text-slate-300">
            Sign up to create notes & projects, then wire a Node.js API + DB.
          </div>
          <div className="mt-3 flex gap-2">
            <span className="px-2 py-1 text-xs rounded-full bg-slate-900 border border-slate-700">Zero-downtime</span>
            <span className="px-2 py-1 text-xs rounded-full bg-slate-900 border border-slate-700">PSS restricted</span>
            <span className="px-2 py-1 text-xs rounded-full bg-slate-900 border border-slate-700">HPA-ready</span>
          </div>
        </div>
      </div>
    </div>
  )
}
