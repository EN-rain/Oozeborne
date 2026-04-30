const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('./db');

async function seed() {
  try {
    const username = 'admin';
    const password = 'moonadmin123';
    const userId = uuidv4();
    const hash = await bcrypt.hash(password, 12);

    console.log('Seeding admin user...');

    // 1. Create player
    await db.query(
      `INSERT INTO players (user_id, username, password_hash)
       VALUES ($1, $2, $3)
       ON CONFLICT (username) DO NOTHING`,
      [userId, username, hash]
    );

    // 2. Get the actual user_id (in case it already existed)
    const { rows } = await db.query('SELECT user_id FROM players WHERE username = $1', [username]);
    const actualId = rows[0].user_id;

    // 3. Set Admin Role (Level 2)
    await db.query(
      `INSERT INTO user_roles (user_id, role_level)
       VALUES ($1, 2)
       ON CONFLICT (user_id) DO UPDATE SET role_level = 2`,
      [actualId]
    );

    // 4. Create Profile
    await db.query(
      `INSERT INTO profiles (user_id, display_name)
       VALUES ($1, $2)
       ON CONFLICT (user_id) DO NOTHING`,
      [actualId, 'Admin']
    );

    console.log('✅ Admin user created successfully!');
    console.log('Username: admin');
    console.log('Password: moonadmin123');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
}

seed();
