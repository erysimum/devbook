import { Router } from 'express'
import { requireAuth } from './middleware.js'

export default function projectRoutes(prisma) {
  const r = Router()

  // List projects for current user
  r.get('/', requireAuth, async (req, res) => {
    const projects = await prisma.project.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    })
    res.json(projects)
  })

  // Create project
  r.post('/', requireAuth, async (req, res) => {
    const { name, description = '', links = [], visibility = 'private' } = req.body || {}
    if (!name) return res.status(400).json({ error: 'name is required' })
    const project = await prisma.project.create({
      data: { name, description, links, visibility, userId: req.user.id }
    })
    res.status(201).json(project)
  })

  return r
}
