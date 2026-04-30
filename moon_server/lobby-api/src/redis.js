const { createClient } = require('redis');

const client = createClient({
  url: `redis://${process.env.REDIS_ADDR || 'localhost:6379'}`,
});

client.on('error', (err) => console.error('[Redis]', err));

(async () => { await client.connect(); })();

module.exports = client;
