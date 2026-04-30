const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db     = require('../db');
const redis  = require('../redis');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// ─── POST /friends/request ────────────────────────────────────────────────
router.post('/request', requireAuth, async (req, res, next) => {
  try {
    const { target_user_id } = req.body;
    if (!target_user_id) return res.status(400).json({ error: 'target_user_id required' });
    if (target_user_id === req.user.user_id)
      return res.status(400).json({ error: 'Cannot add yourself' });

    await db.query(
      `INSERT INTO friends (id, user_a, user_b, status)
       VALUES ($1, $2, $3, 'pending')
       ON CONFLICT (user_a, user_b) DO NOTHING`,
      [uuidv4(), req.user.user_id, target_user_id]
    );
    res.status(201).json({ ok: true });
  } catch (err) { next(err); }
});

// ─── POST /friends/accept ─────────────────────────────────────────────────
router.post('/accept', requireAuth, async (req, res, next) => {
  try {
    const { requester_id } = req.body;
    await db.query(
      `UPDATE friends SET status = 'accepted'
       WHERE user_a = $1 AND user_b = $2 AND status = 'pending'`,
      [requester_id, req.user.user_id]
    );
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /friends/list ────────────────────────────────────────────────────
// Returns accepted friends with online status from Redis presence
router.get('/list', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT
         CASE WHEN f.user_a = $1 THEN f.user_b ELSE f.user_a END AS friend_id,
         p.display_name, p2.username
       FROM friends f
       JOIN profiles p  ON p.user_id  = CASE WHEN f.user_a = $1 THEN f.user_b ELSE f.user_a END
       JOIN players p2  ON p2.user_id = CASE WHEN f.user_a = $1 THEN f.user_b ELSE f.user_a END
       WHERE (f.user_a = $1 OR f.user_b = $1) AND f.status = 'accepted'`,
      [req.user.user_id]
    );

    // Enrich with Redis online status
    const friends = await Promise.all(rows.map(async (f) => {
      const online = await redis.exists(`presence:${f.friend_id}`);
      return { ...f, online: online === 1 };
    }));

    res.json({ friends });
  } catch (err) { next(err); }
});

module.exports = router;
