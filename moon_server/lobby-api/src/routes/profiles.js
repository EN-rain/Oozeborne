const express = require('express');
const db      = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// ─── GET /profiles/me ─────────────────────────────────────────────────────
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT p.display_name, p.slime_variant, p.class_id, p.cosmetics,
              pr.level, pr.xp, pr.coins
       FROM profiles p
       JOIN progression pr ON pr.user_id = p.user_id
       WHERE p.user_id = $1`,
      [req.user.user_id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Profile not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// ─── PATCH /profiles/me ───────────────────────────────────────────────────
router.patch('/me', requireAuth, async (req, res, next) => {
  try {
    const { display_name, slime_variant, class_id } = req.body;
    await db.query(
      `UPDATE profiles
       SET display_name  = COALESCE($1, display_name),
           slime_variant = COALESCE($2, slime_variant),
           class_id      = COALESCE($3, class_id),
           updated_at    = NOW()
       WHERE user_id = $4`,
      [display_name, slime_variant, class_id, req.user.user_id]
    );
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// ─── GET /profiles/:user_id ───────────────────────────────────────────────
router.get('/:user_id', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT p.display_name, p.slime_variant, p.class_id,
              pr.level, pr.xp, pr.coins
       FROM profiles p
       JOIN progression pr ON pr.user_id = p.user_id
       WHERE p.user_id = $1`,
      [req.params.user_id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

module.exports = router;
