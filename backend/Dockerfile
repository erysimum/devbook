# --- build stage ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY prisma ./prisma
# Prisma client generation depends on schema & env at runtime, but generate now for faster start
RUN npx prisma generate
COPY src ./src

# --- run stage ---
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
# env (DATABASE_URL, JWT_SECRET, PORT) will be injected by compose/K8s
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/src ./src
EXPOSE 3000
CMD ["node", "src/index.js"]
