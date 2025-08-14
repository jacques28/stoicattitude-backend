#!/bin/bash
# Deploy Strapi backend to Fly.io

set -e

echo "🚀 Deploying Stoic Attitude Backend to Fly.io..."

# Check if logged in to Fly
if ! flyctl auth whoami >/dev/null 2>&1; then
    echo "❌ Not logged in to Fly.io. Please run: flyctl auth login"
    exit 1
fi

# Generate secure keys if not provided
if [ -z "$APP_KEYS" ]; then
    echo "🔐 Generating secure APP_KEYS..."
    APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32)
fi

if [ -z "$API_TOKEN_SALT" ]; then
    echo "🔐 Generating secure API_TOKEN_SALT..."
    API_TOKEN_SALT=$(openssl rand -base64 32)
fi

if [ -z "$ADMIN_JWT_SECRET" ]; then
    echo "🔐 Generating secure ADMIN_JWT_SECRET..."
    ADMIN_JWT_SECRET=$(openssl rand -base64 32)
fi

if [ -z "$JWT_SECRET" ]; then
    echo "🔐 Generating secure JWT_SECRET..."
    JWT_SECRET=$(openssl rand -base64 32)
fi

# Set environment variables
echo "📝 Setting secrets..."

# Database
flyctl secrets set DATABASE_URL="$DATABASE_URL" --app stoic-attitude-backend

# Strapi configuration
flyctl secrets set APP_KEYS="$APP_KEYS" --app stoic-attitude-backend
flyctl secrets set API_TOKEN_SALT="$API_TOKEN_SALT" --app stoic-attitude-backend
flyctl secrets set ADMIN_JWT_SECRET="$ADMIN_JWT_SECRET" --app stoic-attitude-backend
flyctl secrets set JWT_SECRET="$JWT_SECRET" --app stoic-attitude-backend

# Frontend URL for CORS
flyctl secrets set CLIENT_URL="https://stoic-attitude-frontend.fly.dev" --app stoic-attitude-backend

echo "✅ Secrets configured"

# Create volume for uploads if it doesn't exist
echo "📦 Creating persistent volume for uploads..."
flyctl volumes create strapi_uploads --region iad --size 10 --app stoic-attitude-backend || true

# Deploy
echo "🚀 Deploying application..."
flyctl deploy --app stoic-attitude-backend

echo "✅ Deployment complete!"
echo "🌐 Your app is available at: https://stoic-attitude-backend.fly.dev"

# Check deployment status
echo "📊 Checking deployment status..."
flyctl status --app stoic-attitude-backend

# Save the generated keys
echo ""
echo "⚠️  IMPORTANT: Save these generated keys securely!"
echo "APP_KEYS=$APP_KEYS"
echo "API_TOKEN_SALT=$API_TOKEN_SALT"
echo "ADMIN_JWT_SECRET=$ADMIN_JWT_SECRET"
echo "JWT_SECRET=$JWT_SECRET"
