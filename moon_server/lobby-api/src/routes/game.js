const express = require('express');
const router = express.Router();

// ─── GET /game/config — Fetch all game configuration (Mobs, Items, Classes) ───
// This is used by the game-server on startup and for sync
router.get('/config', async (req, res, next) => {
  const db = req.app.get('db');
  try {
    const [mobs, items, classes] = await Promise.all([
      db.query('SELECT * FROM mob_configs'),
      db.query('SELECT * FROM item_configs'),
      db.query('SELECT * FROM class_configs')
    ]);

    res.json({
      mobs: mobs.rows,
      items: items.rows,
      classes: classes.rows
    });
  } catch (err) { next(err); }
});

module.exports = router;
