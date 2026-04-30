FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .

# Pass build args to env for Next.js build
ARG NEXT_PUBLIC_LOBBY_API_URL
ENV NEXT_PUBLIC_LOBBY_API_URL=$NEXT_PUBLIC_LOBBY_API_URL

RUN npm run build

# ─── Runtime stage ───────────────────────────────────────────────────────────
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.js ./

ENV NODE_ENV production
ENV HOSTNAME 0.0.0.0
EXPOSE 3001
CMD ["npm", "start"]
