import { Router } from 'express'
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'



export default function authRoutes(prisma) {
  const r = Router()

 r.post('/signup', async (req, res) => {
  const { email, password } = req.body || {}

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' })
  }

  const existingUser = await prisma.user.findUnique({ where: { email } })
  if (existingUser) {
    return res.status(409).json({ error: 'Email already in use' })
  }

  const hashedPassword = await bcrypt.hash(password, 10)

  const newUser = await prisma.user.create({
    data: {
      email,
      password: hashedPassword
    }
  })

  const accessToken = jwt.sign(
    { sub: newUser.id, email: newUser.email },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: '15m' }
  )

//   const refreshToken = jwt.sign(
//     { sub: newUser.id },
//     process.env.REFRESH_TOKEN_SECRET,
//     { expiresIn: '7d' }
//   )

  // Store refresh token in DB
//   await prisma.user.update({
//     where: { id: newUser.id },
//     data: { refreshToken }
//   })

  // Send tokens in cookies
  res.cookie('accessToken', accessToken, {
    httpOnly: true,
    secure: false,
    sameSite: 'lax',
    maxAge: 15 * 60 * 1000 // 15 mins
  })

//   res.cookie('refreshToken', refreshToken, {
//     httpOnly: true,
//     secure: true,
//     sameSite: 'lax',
//     maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
//   })

  return res.status(201).json({ id: newUser.id, email: newUser.email })
})

r.post('/login', async (req, res) => {
  const { email, password } = req.body || {}

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' })
  }

  const user = await prisma.user.findUnique({ where: { email } })
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const isValid = await bcrypt.compare(password, user.password)
  if (!isValid) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const accessToken = jwt.sign(
    { sub: user.id, email: user.email },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: '15m' }
  )

//   const refreshToken = jwt.sign(
//     { sub: user.id },
//     process.env.REFRESH_TOKEN_SECRET,
//     { expiresIn: '7d' }
//   )

  // Save new refresh token in DB
//   await prisma.user.update({
//     where: { id: user.id },
//     data: { refreshToken }
//   })

  res.cookie('accessToken', accessToken, {
    httpOnly: true,
    secure: false,
    sameSite: 'lax',
    maxAge: 15 * 60 * 1000
  })

//   res.cookie('refreshToken', refreshToken, {
//     httpOnly: true,
//     secure: true,
//     sameSite: 'lax',
//     maxAge: 7 * 24 * 60 * 60 * 1000
//   })

  return res.json({ id: user.id, email: user.email })
})
return r
}