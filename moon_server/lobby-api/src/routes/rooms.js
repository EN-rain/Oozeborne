const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db     = require('../db');
const redis  = require('../redis');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Helper — generate a 6-char alphanumeric room code
function genCode() {
  return Math.random().toString(36).slice(2, 8).toUpperCase();
}

// ─── POST /rooms/create ───────────────────────────────────────────────────
router.post('/create', requireAuth, async (req, res, next) => {
  try {
    const { title = 'Moon Room', max_players = 4 } = req.body;
    const room_id   = uuidv4();
    const room_code = genCode();

    // Store in Redis (durable room registry)
    await redis.hSet(`room:${room_code}`, {
      room_id,
      room_code,
      host_id: req.user.user_id,
      title,
      max_players: String(max_players),
      player_count: '0',
      created_at: new Date().toISOString(),
    });
    await redis.expire(`room:${room_code}`, 60 * 60 * 6); // 6h TTL

    const game_server_url = process.env.GAME_SERVER_WS_URL || 'ws://localhost:8080';

    res.status(201).json({
      room_id,
      room_code,
      ws_url: `${game_server_url}/ws?room_id=${room_id}&room_code=${room_code}`,
    });
  } catch (err) { next(err); }
});

// ─── POST /rooms/join ─────────────────────────────────────────────────────
router.post('/join', requireAuth, async (req, res, next) => {
  try {
    const { room_code } = req.body;
    if (!room_code) return res.status(400).json({ error: 'room_code required' });

    const room = await redis.hGetAll(`room:${room_code}`);
    if (!room || !room.room_id) return res.status(404).json({ error: 'Room not found' });

    const game_server_url = process.env.GAME_SERVER_WS_URL || 'ws://localhost:8080';

    res.json({
      room_id:   room.room_id,
      room_code: room.room_code,
      host_id:   room.host_id,
      title:     room.title,
      ws_url: `${game_server_url}/ws?room_id=${room.room_id}&room_code=${room_code}`,
    });
  } catch (err) { next(err); }
});

// ─── GET /rooms/:room_code — Room info + invite link ─────────────────────
router.get('/:room_code', requireAuth, async (req, res, next) => {
  try {
    const room = await redis.hGetAll(`room:${req.params.room_code}`);
    if (!room || !room.room_id) return res.status(404).json({ error: 'Room not found' });

    const base = process.env.CLIENT_BASE_URL || 'http://localhost';
    res.json({
      ...room,
      invite_url: `${base}/join?code=${req.params.room_code}`,
    });
  } catch (err) { next(err); }
});

// ─── GET /rooms — List all active rooms (admin-visible) ──────────────────
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const keys = await redis.keys('room:*');
    const rooms = [];
    for (const key of keys) {
      const r = await redis.hGetAll(key);
      if (r && r.room_id) rooms.push(r);
    }
    res.json({ rooms });
  } catch (err) { next(err); }
});

module.exports = router;
