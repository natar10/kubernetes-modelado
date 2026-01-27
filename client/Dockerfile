# =============================================================================
# DOCKERFILE - Cliente React
# =============================================================================
# Multi-stage build para optimizar el tamaño de la imagen
# =============================================================================

# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Production
FROM nginx:1.25-alpine
# Copiar build de React
COPY --from=builder /app/dist /usr/share/nginx/html
# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/nginx.conf
# Script para inyectar variables de entorno en runtime
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
