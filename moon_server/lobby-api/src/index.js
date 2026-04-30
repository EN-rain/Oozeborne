require('dotenv').config();
const express    = require('express');
const helmet     = require('helmet');
const cors       = require('cors');
const morgan     = require('morgan');

const authRoutes    = require('./routes/auth');
const roomRoutes    = require('./routes/rooms');
const profileRoutes = require('./routes/profiles');
const adminRoutes   = require('./routes/admin');
const friendRoutes  = require('./routes/friends');
const chatRoutes    = require('./routes/chat');

const { authLimiter, apiLimiter, adminLimiter } = require('./middleware/rateLimiter');

const app  = express();
const PORT = process.env.PORT || 3000;

// ─── Security Headers (Helmet) ────────────────────────────────────────────
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc:  ["'self'"],
      objectSrc:  ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
  hsts: {
    maxAge: 31536000,           // 1 year
    includeSubDomains: true,
    preload: true,
  },
  referrerPolicy: { policy: 'no-referrer' },
  frameguard:    { action: 'deny' },
  noSniff:       true,
  xssFilter:     true,
}));

// ─── CORS (allowlist-based) ───────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3001,http://localhost:3000')
  .split(',')
  .map(o => o.trim());

app.use(cors({
  origin(origin, callback) {
    // Allow non-browser clients (Godot, curl)
    if (!origin) return callback(null, true);
    
    // Trust any origin on the same host (handles port 3001 vs 3000)
    const url = new URL(origin);
    const isSameHost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    
    if (allowedOrigins.includes(origin) || isSameHost || url.hostname.match(/^\d+\.\d+\.\d+\.\d+$/)) {
      return callback(null, true);
    }
    
    callback(new Error(`CORS: origin ${origin} not allowed`));
  },
  methods:          ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders:   ['Content-Type', 'Authorization'],
  credentials:      true,
  maxAge:           600, // preflight cache 10 minutes
}));

// ─── Body Parsing (size-limited) ──────────────────────────────────────────
app.use(express.json({ limit: '16kb' }));
app.use(express.urlencoded({ extended: false, limit: '16kb' }));

// ─── Logging (no sensitive data) ─────────────────────────────────────────
// 'combined' in production so logs don't include request body
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ─── Global API Rate Limiter ──────────────────────────────────────────────
app.use(apiLimiter);

// ─── Routes ───────────────────────────────────────────────────────────────
app.use('/auth',     authLimiter, authRoutes);      // tighter limiter on auth
app.use('/rooms',    roomRoutes);
app.use('/profiles', profileRoutes);
app.use('/admin',    adminLimiter, adminRoutes);    // admin-specific limiter
app.use('/friends',  friendRoutes);
app.use('/chat',     chatRoutes);
app.use('/saves',    require('./routes/saves'));

// ─── Health (no auth required) ────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'moon-lobby-api' });
});

// ─── 404 Handler ─────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ─── Global Error Handler ─────────────────────────────────────────────────
// IMPORTANT: Never expose stack traces or internal details in production
app.use((err, _req, res, _next) => {
  const isProd = process.env.NODE_ENV === 'production';

  // Log internally with full detail
  console.error('[ERROR]', {
    message: err.message,
    status:  err.status,
    stack:   isProd ? undefined : err.stack,
  });

  // Respond with minimal info to the client
  res.status(err.status || 500).json({
    error: isProd && !err.status
      ? 'An internal error occurred'   // hide unexpected errors in prod
      : err.message || 'Internal error',
  });
});

// ─── Start ────────────────────────────────────────────────────────────────
if (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'change_me_before_production') {
  if (process.env.NODE_ENV === 'production') {
    console.error('[FATAL] JWT_SECRET is not set or is using the default value.');
    process.exit(1);
  }
}

app.listen(PORT, () => {
  console.log(`🌙 Moon Lobby API running on :${PORT} [${process.env.NODE_ENV || 'development'}]`);
});
