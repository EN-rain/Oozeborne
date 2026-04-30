/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        moon: {
          bg:      '#0a0c14',
          surface: '#111827',
          accent:  '#6366f1',
          accent2: '#8b5cf6',
        },
      },
    },
  },
  plugins: [],
};
