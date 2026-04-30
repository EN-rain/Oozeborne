const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'change_me';

/**
 * Express middleware — validates player JWT.
 * Sets req.user = { user_id, role_level }
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Middleware — requires Admin role (level >= 2) or SuperAdmin (level 3).
 */
function requireAdmin(req, res, next) {
  if (!req.user || req.user.role_level < 2) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

/**
 * Middleware — requires SuperAdmin role (level 3).
 */
function requireSuperAdmin(req, res, next) {
  if (!req.user || req.user.role_level < 3) {
    return res.status(403).json({ error: 'SuperAdmin access required' });
  }
  next();
}

function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
}

module.exports = { requireAuth, requireAdmin, requireSuperAdmin, signToken };
