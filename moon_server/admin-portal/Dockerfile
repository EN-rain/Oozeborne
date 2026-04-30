FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3001

# Copy the entire standalone folder
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# BULLETPROOF FIX: Find where server.js is and move everything to /app root
RUN FILE=$(find . -name "server.js" | head -n 1) && \
    DIR=$(dirname "$FILE") && \
    cp -r "$DIR"/. . 

EXPOSE 3001
CMD ["node", "server.js"]
