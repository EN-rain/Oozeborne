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

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Handle nested standalone output if project is in a subdirectory
# Note: Next.js reflects the source path in the standalone folder
RUN if [ -d "moon_server/admin-portal" ]; then cp -r moon_server/admin-portal/. . && rm -rf moon_server; fi

EXPOSE 3001
CMD ["node", "server.js"]
