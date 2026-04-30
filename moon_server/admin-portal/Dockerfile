FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run build
ENV NODE_ENV production
ENV HOSTNAME 0.0.0.0
EXPOSE 3001
CMD ["npm", "start"]
