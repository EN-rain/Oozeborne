const express = require('express');
const bcrypt  = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db      = require('../db');
const { signToken } = require('../middleware/auth');
const { validate, registerRules, loginRules } = require('../middleware/validate');

const router = express.Router();

// ─── POST /auth/register ──────────────────────────────────────────────────
router.post('/register', registerRules, validate, async (req, res, next) => {
  try {
    const { username, email, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: 'username and password required' });

    const hash = await bcrypt.hash(password, 12);
    const { rows } = await db.query(
      `INSERT INTO players (user_id, username, email, password_hash)
       VALUES ($1, $2, $3, $4)
       RETURNING user_id, username`,
      [uuidv4(), username, email || null, hash]
    );
    const player = rows[0];

    // Create default profile & progression rows
    await db.query(`INSERT INTO profiles (user_id, display_name) VALUES ($1, $2)`, [player.user_id, username]);
    await db.query(`INSERT INTO progression (user_id) VALUES ($1)`, [player.user_id]);
    await db.query(`INSERT INTO user_roles (user_id, role_level) VALUES ($1, 0)`, [player.user_id]);

    const token = signToken({ user_id: player.user_id, username: player.username, role_level: 0 });
    res.status(201).json({ token, user_id: player.user_id, username: player.username });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Username or email already exists' });
    next(err);
  }
});

// ─── POST /auth/login ─────────────────────────────────────────────────────
router.post('/login', loginRules, validate, async (req, res, next) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: 'username and password required' });

    const { rows } = await db.query(
      `SELECT p.user_id, p.username, p.password_hash, r.role_level
       FROM players p
       JOIN user_roles r ON r.user_id = p.user_id
       WHERE p.username = $1`,
      [username]
    );
    const player = rows[0];
    if (!player) return res.status(401).json({ error: 'Invalid credentials' });

    // Check ban
    const { rows: bans } = await db.query(
      `SELECT ban_id FROM bans WHERE user_id = $1 AND (expires_at IS NULL OR expires_at > NOW())`,
      [player.user_id]
    );
    if (bans.length > 0) return res.status(403).json({ error: 'Account is banned' });

    const ok = await bcrypt.compare(password, player.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    const token = signToken({
      user_id:    player.user_id,
      username:   player.username,
      role_level: player.role_level,
    });
    res.json({ token, user_id: player.user_id, username: player.username, role_level: player.role_level });
  } catch (err) { next(err); }
});

module.exports = router;
