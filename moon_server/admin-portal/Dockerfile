FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN ./node_modules/.bin/next build
ENV NODE_ENV production
ENV HOSTNAME 0.0.0.0
EXPOSE 3001
CMD ["./node_modules/.bin/next", "start", "-p", "3001"]
