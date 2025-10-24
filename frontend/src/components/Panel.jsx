import React from 'react'
export default function Panel({ title, children }){
  return (
    <section className="rounded-3xl border border-slate-800 bg-slate-900/60 backdrop-blur p-5">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">{title}</h3>
      </div>
      {children}
    </section>
  )
}
