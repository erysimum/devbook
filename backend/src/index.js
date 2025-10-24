import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import cookieParser from 'cookie-parser'
import { PrismaClient } from '@prisma/client'
import authRoutes from './auth.js'
import noteRoutes from './notes.js'
import projectRoutes from './projects.js'

const prisma = new PrismaClient()
const app = express()

app.use(cors({ origin: true, credentials: true }))
app.use(cookieParser())
app.use(express.json())

console.log('Starting server...')

app.get('/api/health', (_req, res) => res.json({ ok: true }))
app.get('/api/test', (_req, res) => res.json({ message: 'Test route works without Prisma' }))

app.use('/api/auth', authRoutes(prisma))
app.use('/api/notes', noteRoutes(prisma))
app.use('/api/projects', projectRoutes(prisma))

const port = process.env.PORT || 3000
app.listen(port, () => console.log(`API listening on http://localhost:${port}`))
