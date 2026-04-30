const rateLimit = require('express-rate-limit');

/**
 * Auth rate limiter — prevents brute-force on login/register
 * 10 attempts per 15 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Try again later.' },
});

/**
 * API rate limiter — general protection for all routes
 * 100 requests per minute per IP
 */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Rate limit exceeded.' },
});

/**
 * Admin rate limiter — tighter limit on admin endpoints
 * 30 requests per minute per IP
 */
const adminLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Admin rate limit exceeded.' },
});

module.exports = { authLimiter, apiLimiter, adminLimiter };
