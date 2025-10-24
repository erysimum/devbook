import { Router } from 'express'
import { requireAuth } from './middleware.js'

export default function noteRoutes(prisma) {
  const r = Router()

  // List notes for current user
  r.get('/', requireAuth, async (req, res) => {
    const notes = await prisma.note.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    })
    res.json(notes)
  })

  // Create note
  r.post('/', requireAuth, async (req, res) => {
    const { title, content = '', tags = [] } = req.body || {}
    if (!title) return res.status(400).json({ error: 'title is required' })
    const note = await prisma.note.create({
      data: { title, content, tags, userId: req.user.id }
    })
    res.status(201).json(note)
  })

  return r
}
