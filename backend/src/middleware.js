// ESM-style import
import jwt from 'jsonwebtoken'

// Middleware to protect routes
export function requireAuth(req, res, next) {
  const token = req.cookies?.accessToken // Match your cookie name
  if (!token) return res.status(401).json({ error: 'Unauthorized' })

  try {
    const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET)
    req.user = {
      id: decoded.sub,
      email: decoded.email
    } // Save user info in request
    next()
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' })
  }
}
