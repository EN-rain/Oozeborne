/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  env: {
    NEXT_PUBLIC_LOBBY_API_URL: process.env.NEXT_PUBLIC_LOBBY_API_URL,
    NEXT_PUBLIC_GAME_SERVER_URL: process.env.NEXT_PUBLIC_GAME_SERVER_URL,
  },
};

module.exports = nextConfig;
