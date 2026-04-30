const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db     = require('../db');
const redis  = require('../redis');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// ─── POST /chat/global ────────────────────────────────────────────────────
router.post('/global', requireAuth, async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content?.trim()) return res.status(400).json({ error: 'content required' });

    const message_id = uuidv4();
    await db.query(
      `INSERT INTO chat_messages (message_id, sender_id, channel_type, content)
       VALUES ($1, $2, 'global', $3)`,
      [message_id, req.user.user_id, content.trim()]
    );

    // Publish to Redis for real-time broadcast
    await redis.publish('global_chat', JSON.stringify({
      message_id,
      sender_id: req.user.user_id,
      content: content.trim(),
      sent_at: new Date().toISOString(),
    }));

    res.status(201).json({ ok: true, message_id });
  } catch (err) { next(err); }
});

// ─── GET /chat/global?limit=50 ───────────────────────────────────────────
router.get('/global', requireAuth, async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const { rows } = await db.query(
      `SELECT m.message_id, m.content, m.created_at, p.display_name, m.sender_id
       FROM chat_messages m
       JOIN profiles p ON p.user_id = m.sender_id
       WHERE m.channel_type = 'global'
       ORDER BY m.created_at DESC
       LIMIT $1`,
      [limit]
    );
    res.json({ messages: rows.reverse() });
  } catch (err) { next(err); }
});

// ─── POST /chat/friend ────────────────────────────────────────────────────
router.post('/friend', requireAuth, async (req, res, next) => {
  try {
    const { recipient_id, content } = req.body;
    if (!recipient_id || !content?.trim())
      return res.status(400).json({ error: 'recipient_id and content required' });

    const message_id = uuidv4();
    await db.query(
      `INSERT INTO chat_messages (message_id, sender_id, recipient_id, channel_type, content)
       VALUES ($1, $2, $3, 'friend', $4)`,
      [message_id, req.user.user_id, recipient_id, content.trim()]
    );

    // Deliver real-time via Redis to target user's channel
    await redis.publish(`user_messages:${recipient_id}`, JSON.stringify({
      message_id,
      sender_id: req.user.user_id,
      content: content.trim(),
      sent_at: new Date().toISOString(),
    }));

    res.status(201).json({ ok: true, message_id });
  } catch (err) { next(err); }
});

module.exports = router;
