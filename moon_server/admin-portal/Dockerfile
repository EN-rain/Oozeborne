FROM node:20-alpine
WORKDIR /app

# 1. Install dependencies
COPY package*.json ./
RUN npm install --legacy-peer-deps

# 2. Copy source and build
COPY . .
RUN npm run build

# 3. Set environment and start
ENV NODE_ENV=production
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

EXPOSE 3001

# Using 'npm start' instead of standalone 'server.js'
CMD ["npm", "start"]
