# Dockerfile for Strapi Backend - Optimized for Fly.io
# Uses multi-stage build for production optimization

# Stage 1: Dependencies
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy all files
COPY . .

# Install all dependencies (including dev dependencies for build)
RUN npm ci

# Build admin panel (also compiles TS)
ENV NODE_ENV=production
RUN npm run build

# Stage 3: Runner
FROM node:18-alpine AS runner
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Add non-root user for security
RUN addgroup -g 1001 -S strapi
RUN adduser -S strapi -u 1001

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/favicon.png ./favicon.png
COPY --from=builder /app/.strapi ./.strapi

# Create uploads directory and set permissions
RUN mkdir -p /app/public/uploads && chown -R strapi:strapi /app

# Set user
USER strapi

# Expose port
EXPOSE 1337

# Set runtime environment variables
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=1337

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:1337/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); });"

# Start Strapi 
CMD ["npm", "start"]