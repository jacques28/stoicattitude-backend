#!/usr/bin/env node
// ===================================================================
// Security Keys Generator for Strapi Production
// ===================================================================
// 🔐 Generates cryptographically secure keys for production deployment
// 🚀 Run: node scripts/generate-secrets.js

const crypto = require('crypto');

console.log('🔐 Generating Strapi Production Security Keys');
console.log('='.repeat(60));

// Generate multiple keys for APP_KEYS (Strapi requires 4)
const appKeys = [];
for (let i = 0; i < 4; i++) {
    appKeys.push(crypto.randomBytes(32).toString('base64'));
}

const secrets = {
    APP_KEYS: appKeys.join(','),
    API_TOKEN_SALT: crypto.randomBytes(32).toString('base64'),
    ADMIN_JWT_SECRET: crypto.randomBytes(32).toString('base64'),
    TRANSFER_TOKEN_SALT: crypto.randomBytes(32).toString('base64'),
    JWT_SECRET: crypto.randomBytes(32).toString('base64'),
    NEXTAUTH_SECRET: crypto.randomBytes(32).toString('base64') // For frontend
};

console.log('📋 Copy these values to your .env.production file:');
console.log('');

Object.entries(secrets).forEach(([key, value]) => {
    console.log(`${key}=${value}`);
});

console.log('');
console.log('⚠️  SECURITY WARNINGS:');
console.log('❌ NEVER commit these keys to version control');
console.log('❌ NEVER share these keys publicly');
console.log('❌ NEVER use these keys in development');
console.log('✅ Store these keys securely');
console.log('✅ Use different keys for each environment');
console.log('');
console.log('🔒 These keys are cryptographically secure and unique.');
console.log('💾 Save them in a secure password manager.');
console.log('');

// Also generate a sample .env.production file
const envContent = `# ===================================================================
# PRODUCTION ENVIRONMENT - GENERATED KEYS
# ===================================================================
# 🔒 SECURE: This file contains production secrets
# 📝 NEVER commit this file to version control

# ===================================================================
# SERVER CONFIGURATION
# ===================================================================
NODE_ENV=production
HOST=0.0.0.0
PORT=1337

# ===================================================================
# AWS RDS POSTGRESQL DATABASE
# ===================================================================
DATABASE_CLIENT=postgres
DATABASE_HOST=database-1.cepui2meiura.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_NAME=stoicattitude_db
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=n8-w2Dd.TEFExuk
DATABASE_SSL=true
DATABASE_SSL_REJECT_UNAUTHORIZED=false
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10
DATABASE_CONNECTION_TIMEOUT=60000
DATABASE_IDLE_TIMEOUT=30000

# ===================================================================
# SECURITY KEYS - GENERATED FOR PRODUCTION
# ===================================================================
${Object.entries(secrets).slice(0, 5).map(([key, value]) => `${key}=${value}`).join('\n')}

# ===================================================================
# CORS AND SECURITY
# ===================================================================
FRONTEND_URL=https://stoicattitude.com
ADMIN_URL=https://api.stoicattitude.com/admin

# Admin panel configuration
ADMIN_HOST=0.0.0.0
ADMIN_PORT=1337
SERVE_ADMIN=true

# API domain configuration
API_URL=https://api.stoicattitude.com
PUBLIC_URL=https://api.stoicattitude.com

# ===================================================================
# FILE UPLOAD CONFIGURATION
# ===================================================================
UPLOAD_PROVIDER=local
UPLOAD_SIZE_LIMIT=10485760
UPLOAD_PATH=./public/uploads

# ===================================================================
# MONITORING AND LOGGING
# ===================================================================
LOG_LEVEL=info
ENABLE_PERFORMANCE_MONITORING=true

# ===================================================================
# HEALTH CHECK CONFIGURATION
# ===================================================================
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_PATH=/api/health

# ===================================================================
# DEPLOYMENT METADATA
# ===================================================================
DEPLOYMENT_ENV=production
DEPLOYMENT_REGION=us-east-1
DEPLOYMENT_DATE=${new Date().toISOString()}
`;

// Write the environment file template
require('fs').writeFileSync('.env.production.generated', envContent);

console.log('📄 Generated .env.production.generated file with these keys.');
console.log('📋 Copy this file to .env.production on your EC2 instance.');
console.log('✏️  Update the FRONTEND_URL with your actual Vercel domain.');
console.log('');
console.log('✅ Security keys generation completed!');
