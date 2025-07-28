#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Strapi application..."

# Wait for database to be ready (if using external database)
echo "⏳ Waiting for database connection..."

# Run database migrations
echo "📊 Running database migrations..."
npm run strapi db:migrate

# Start the application
echo "✅ Starting Strapi server..."
exec npm start 