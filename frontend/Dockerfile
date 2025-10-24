# --- build stage ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- serve stage ---
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy built frontend
COPY --from=build /app/dist ./

# Copy nginx config file (no heredoc anymore)
COPY default.conf /etc/nginx/conf.d/default.conf
