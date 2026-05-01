const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db     = require('../db');
const redis  = require('../redis');
const { requireAuth, requireAdmin, requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();

// All admin routes require at least Admin role
router.use(requireAuth, requireAdmin);

// ─── GET /admin/players/search?q=name ────────────────────────────────────
router.get('/players/search', async (req, res, next) => {
  try {
    const q = `%${req.query.q || ''}%`;
    const { rows } = await db.query(
      `SELECT p.user_id, p.username, p.email, p.created_at,
              pr.display_name, r.role_level,
              (SELECT COUNT(*) FROM bans b WHERE b.user_id = p.user_id
                AND (b.expires_at IS NULL OR b.expires_at > NOW())) AS active_bans
       FROM players p
       JOIN profiles pr ON pr.user_id = p.user_id
       JOIN user_roles r ON r.user_id = p.user_id
       WHERE p.username ILIKE $1 OR p.email ILIKE $1 OR pr.display_name ILIKE $1
       LIMIT 50`,
      [q]
    );
    // Check online presence in Redis for each player
    const players = await Promise.all(rows.map(async (row) => {
      const online = await redis.exists(`presence:${row.user_id}`);
      return { ...row, is_online: online === 1 };
    }));
    res.json({ players });
  } catch (err) { next(err); }
});

// ─── GET /admin/players/:user_id — Deep Dive ─────────────────────────────
router.get('/players/:user_id', async (req, res, next) => {
  try {
    const uid = req.params.user_id;
    const [player, bans, results, logs] = await Promise.all([
      db.query(`SELECT p.*, pr.display_name, r.role_level
                FROM players p
                JOIN profiles pr ON pr.user_id = p.user_id
                JOIN user_roles r ON r.user_id = p.user_id
                WHERE p.user_id = $1`, [uid]),
      db.query(`SELECT * FROM bans WHERE user_id = $1 ORDER BY created_at DESC`, [uid]),
      db.query(`SELECT mr.*, ms.wave_reached, ms.started_at
                FROM match_results mr
                JOIN match_sessions ms ON ms.match_id = mr.match_id
                WHERE mr.user_id = $1 ORDER BY ms.started_at DESC LIMIT 10`, [uid]),
      db.query(`SELECT * FROM staff_logs WHERE target_id = $1 ORDER BY created_at DESC LIMIT 20`, [uid]),
    ]);

    const online = await redis.exists(`presence:${uid}`);
    res.json({
      player: player.rows[0],
      bans:   bans.rows,
      match_history: results.rows,
      staff_actions: logs.rows,
      is_online: online === 1,
    });
  } catch (err) { next(err); }
});

// ─── POST /admin/ban ──────────────────────────────────────────────────────
router.post('/ban', async (req, res, next) => {
  try {
    const { user_id, reason, expires_at } = req.body;
    if (!user_id) return res.status(400).json({ error: 'user_id required' });

    await db.query(
      `INSERT INTO bans (ban_id, user_id, reason, banned_by, expires_at)
       VALUES ($1, $2, $3, $4, $5)`,
      [uuidv4(), user_id, reason, req.user.user_id, expires_at || null]
    );
    // Invalidate session in Redis
    await redis.del(`session:${user_id}`);

    await logAction(db, req.user.user_id, 'ban', user_id, { reason, expires_at });
    res.status(201).json({ ok: true });
  } catch (err) { next(err); }
});

// ─── POST /admin/kick ─────────────────────────────────────────────────────
router.post('/kick', async (req, res, next) => {
  try {
    const { user_id, room_id } = req.body;
    // Publish kick command to game-server via Redis
    await redis.publish('admin_commands', JSON.stringify({
      cmd: 'kick', user_id, room_id, by: req.user.user_id,
    }));
    await logAction(db, req.user.user_id, 'kick', user_id, { room_id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// Broadcast endpoint removed at user request

// ─── POST /admin/maintenance ──────────────────────────────────────────────
router.post('/maintenance', async (req, res, next) => {
  try {
    const { enabled } = req.body;
    await redis.set('maintenance_mode', enabled ? '1' : '0');
    await logAction(db, req.user.user_id, 'maintenance', null, { enabled });
    res.json({ ok: true, maintenance: enabled });
  } catch (err) { next(err); }
});

// ─── POST /admin/spawn_mob — Remote mob spawn into a lobby ───────────────
router.post('/spawn_mob', async (req, res, next) => {
  try {
    const { room_id, mob_type, count = 1 } = req.body;
    await redis.publish('admin_commands', JSON.stringify({
      cmd: 'spawn_mob', room_id, mob_type, count, by: req.user.user_id,
    }));
    await logAction(db, req.user.user_id, 'spawn_mob', null, { room_id, mob_type, count });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── POST /admin/player_action — God Mode Live Manipulation ──────────────
router.post('/player_action', async (req, res, next) => {
  try {
    const { user_id, action, payload } = req.body;
    await redis.publish('admin_commands', JSON.stringify({
      cmd: 'player_action', target_user_id: user_id, action, payload, by: req.user.user_id,
    }));
    await logAction(db, req.user.user_id, 'player_action', user_id, { action, payload });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── POST /admin/players/:user_id/wipe — Reset Account Progression ───────
router.post('/players/:user_id/wipe', async (req, res, next) => {
  try {
    const uid = req.params.user_id;
    await db.query(
      `UPDATE progression SET level=1, xp=0, coins=0 WHERE user_id = $1`,
      [uid]
    );
    await logAction(db, req.user.user_id, 'wipe_account', uid, {});
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /admin/mobs/:mob_type — Fetch current mob stats ─────────────────────
router.get('/mobs/:mob_type', async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT health, speed, damage, xp_reward, gold_reward, attributes 
       FROM mob_configs WHERE mob_type = $1`,
      [req.params.mob_type]
    );
    res.json({ mob: rows[0] || null });
  } catch (err) { next(err); }
});

// ─── PATCH /admin/mobs/:mob_type — Live mob stat tuning ──────────────────
router.patch('/mobs/:mob_type', async (req, res, next) => {
  try {
    const { health, speed, damage, xp_reward, gold_reward, attributes } = req.body;
    await db.query(
      `UPDATE mob_configs SET
         health      = COALESCE($1, health),
         speed       = COALESCE($2, speed),
         damage      = COALESCE($3, damage),
         xp_reward   = COALESCE($4, xp_reward),
         gold_reward = COALESCE($5, gold_reward),
         attributes  = COALESCE($6, attributes),
         updated_at  = NOW()
       WHERE mob_type = $7`,
      [health, speed, damage, xp_reward, gold_reward, attributes ? JSON.stringify(attributes) : null, req.params.mob_type]
    );
    // Broadcast live stat update to all game-server instances
    await redis.publish('config_updates', JSON.stringify({
      type: 'mob_config', mob_type: req.params.mob_type,
      health, speed, damage, xp_reward, gold_reward, attributes
    }));
    await logAction(db, req.user.user_id, 'mob_tune', null, { mob_type: req.params.mob_type, health, speed, damage });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /admin/items — Fetch all item configs ─────────────────────────────
router.get('/items', async (req, res, next) => {
  try {
    const { rows } = await db.query(`SELECT * FROM item_configs ORDER BY category, price`);
    res.json({ items: rows });
  } catch (err) { next(err); }
});

// ─── PATCH /admin/items/:item_id — Tune item stats ─────────────────────────
router.patch('/items/:item_id', async (req, res, next) => {
  try {
    const { display_name, description, price, stat_type, stat_value, instant_heal, duration } = req.body;
    await db.query(
      `UPDATE item_configs SET
         display_name = COALESCE($1, display_name),
         description  = COALESCE($2, description),
         price        = COALESCE($3, price),
         stat_type    = COALESCE($4, stat_type),
         stat_value   = COALESCE($5, stat_value),
         instant_heal = COALESCE($6, instant_heal),
         duration     = COALESCE($7, duration),
         updated_at   = NOW()
       WHERE item_id = $8`,
      [display_name, description, price, stat_type, stat_value, instant_heal, duration, req.params.item_id]
    );
    await redis.publish('config_updates', JSON.stringify({ type: 'item_config', item_id: req.params.item_id }));
    await logAction(db, req.user.user_id, 'item_tune', null, { item_id: req.params.item_id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /admin/classes/:class_id — Fetch class stats ──────────────────────
router.get('/classes/:class_id', async (req, res, next) => {
  try {
    const { rows } = await db.query(`SELECT * FROM class_configs WHERE class_id = $1`, [req.params.class_id]);
    res.json({ class: rows[0] || null });
  } catch (err) { next(err); }
});

// ─── PATCH /admin/classes/:class_id — Tune class stats ─────────────────────
router.patch('/classes/:class_id', async (req, res, next) => {
  try {
    const { 
      base_max_health, base_speed, base_attack_damage, base_crit_chance, 
      base_max_mana, health_per_level, damage_per_level, skills 
    } = req.body;
    await db.query(
      `UPDATE class_configs SET
         base_max_health    = COALESCE($1, base_max_health),
         base_speed         = COALESCE($2, base_speed),
         base_attack_damage = COALESCE($3, base_attack_damage),
         base_crit_chance   = COALESCE($4, base_crit_chance),
         base_max_mana      = COALESCE($5, base_max_mana),
         health_per_level   = COALESCE($6, health_per_level),
         damage_per_level   = COALESCE($7, damage_per_level),
         skills             = COALESCE($8, skills),
         updated_at         = NOW()
       WHERE class_id = $9`,
      [
        base_max_health, base_speed, base_attack_damage, base_crit_chance, 
        base_max_mana, health_per_level, damage_per_level, 
        skills ? JSON.stringify(skills) : null, 
        req.params.class_id
      ]
    );
    await redis.publish('config_updates', JSON.stringify({ type: 'class_config', class_id: req.params.class_id }));
    await logAction(db, req.user.user_id, 'class_tune', null, { class_id: req.params.class_id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── SuperAdmin: Set role ──────────────────────────────────────────────────
router.patch('/players/:user_id/role', requireSuperAdmin, async (req, res, next) => {
  try {
    const { role_level } = req.body;
    if (role_level === undefined) return res.status(400).json({ error: 'role_level required' });
    await db.query(
      `UPDATE user_roles SET role_level = $1 WHERE user_id = $2`,
      [role_level, req.params.user_id]
    );
    await logAction(db, req.user.user_id, 'role_change', req.params.user_id, { role_level });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── SuperAdmin: Change admin/superadmin password ─────────────────────────
router.patch('/account/password', requireSuperAdmin, async (req, res, next) => {
  try {
    const bcrypt = require('bcryptjs');
    const { user_id, new_password } = req.body;
    if (!user_id || !new_password) return res.status(400).json({ error: 'user_id and new_password required' });
    const hash = await bcrypt.hash(new_password, 12);
    await db.query(`UPDATE players SET password_hash = $1 WHERE user_id = $2`, [hash, user_id]);
    await logAction(db, req.user.user_id, 'password_change', user_id, {});
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── SuperAdmin: List all Staff ───────────────────────────────────────────
router.get('/staff', requireSuperAdmin, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT p.user_id, p.username, p.email, r.role_level
       FROM players p
       JOIN user_roles r ON r.user_id = p.user_id
       WHERE r.role_level > 0
       ORDER BY r.role_level DESC`
    );
    res.json({ staff: rows });
  } catch (err) { next(err); }
});

// ─── SuperAdmin: Create new Staff ─────────────────────────────────────────
router.post('/staff', requireSuperAdmin, async (req, res, next) => {
  try {
    const bcrypt = require('bcryptjs');
    const { username, password, role_level = 1 } = req.body;
    if (!username || !password) return res.status(400).json({ error: 'Username and password required' });
    
    const userId = uuidv4();
    const hash = await bcrypt.hash(password, 12);
    
    await db.query(`INSERT INTO players (user_id, username, password_hash) VALUES ($1, $2, $3)`, [userId, username, hash]);
    await db.query(`INSERT INTO user_roles (user_id, role_level) VALUES ($1, $2)`, [userId, role_level]);
    await db.query(`INSERT INTO profiles (user_id, display_name) VALUES ($1, $2)`, [userId, username]);
    
    await logAction(db, req.user.user_id, 'staff_create', userId, { username, role_level });
    res.status(201).json({ ok: true });
  } catch (err) { next(err); }
});

// ─── SuperAdmin: Delete Staff ──────────────────────────────────────────────
router.delete('/staff/:user_id', requireSuperAdmin, async (req, res, next) => {
  try {
    await db.query(`DELETE FROM players WHERE user_id = $1`, [req.params.user_id]);
    await logAction(db, req.user.user_id, 'staff_delete', req.params.user_id, {});
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /admin/rooms — Live room list ───────────────────────────────────
router.get('/rooms', async (req, res, next) => {
  try {
    const keys = await redis.keys('room:*');
    const rooms = [];
    for (const key of keys) {
      const r = await redis.hGetAll(key);
      if (r?.room_id) rooms.push(r);
    }
    const os = require('os');
    res.json({ 
      rooms, 
      process_uptime: process.uptime(),
      system_uptime: os.uptime(),
      load_avg: os.loadavg()[0],
      memory_usage: process.memoryUsage().heapUsed / 1024 / 1024
    });
  } catch (err) { next(err); }
});

// ─── GET /admin/rooms/:room_id/stats — Real-time room telemetry ──────────
router.get('/rooms/:room_id/stats', async (req, res, next) => {
  try {
    const roomId = req.params.room_id;
    // Attempt to get cached stats from Redis (pushed by game-server)
    const stats = await redis.get(`room_stats:${roomId}`);
    if (stats) return res.json(JSON.parse(stats));

    // Fallback: get basic info from registry
    const keys = await redis.keys(`room:*`);
    for (const k of keys) {
      const r = await redis.hGetAll(k);
      if (r.room_id === roomId) {
        return res.json({
          room_id: r.room_id,
          room_code: k.split(':')[1],
          players: [], // empty if game-server hasn't pushed stats yet
          wave: 0
        });
      }
    }
    res.status(404).json({ error: 'Room stats not found' });
  } catch (err) { next(err); }
});

// ─── DELETE /admin/rooms/:room_code — Kill a live room ───────────────────
router.delete('/rooms/:room_code', async (req, res, next) => {
  try {
    const code = req.params.room_code;
    const room = await redis.hGetAll(`room:${code}`);
    if (!room || !room.room_id) return res.status(404).json({ error: 'Room not found' });

    await redis.del(`room:${code}`);
    // Also notify game-server to kill the room if active
    await redis.publish('admin_commands', JSON.stringify({
      cmd: 'kill_room', room_id: room.room_id, by: req.user.user_id,
    }));

    await logAction(db, req.user.user_id, 'kill_room', null, { room_code: code, room_id: room.room_id });
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── Utility: write audit log ────────────────────────────────────────────
async function logAction(db, admin_id, action_type, target_id, payload) {
  await db.query(
    `INSERT INTO staff_logs (log_id, admin_id, action_type, target_id, payload)
     VALUES ($1, $2, $3, $4, $5)`,
    [uuidv4(), admin_id, action_type, target_id || null, JSON.stringify(payload)]
  );
}

module.exports = router;
