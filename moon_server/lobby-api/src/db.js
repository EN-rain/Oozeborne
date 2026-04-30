const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432'),
  user:     process.env.POSTGRES_USER     || 'moon',
  password: process.env.POSTGRES_PASSWORD || 'moonpass',
  database: process.env.POSTGRES_DB       || 'moondb',
});

module.exports = pool;
