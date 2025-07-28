# Use the official Node.js 18 Alpine image for smaller size
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++ bash

# Copy package files first for better layer caching
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove dev dependencies to reduce image size
RUN npm prune --production

# Make start script executable
RUN chmod +x scripts/start.sh

# Expose the port
EXPOSE 1337

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001

# Change ownership of the app directory
RUN chown -R strapi:nodejs /app
USER strapi

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:1337/_health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Start the application using our script
CMD ["./scripts/start.sh"] 