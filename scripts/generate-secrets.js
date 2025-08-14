#!/usr/bin/env node

// Script to generate secure secrets for Strapi production deployment
const crypto = require('crypto');

function generateSecret() {
    return crypto.randomBytes(32).toString('base64');
}

function generateAppKeys() {
    return Array.from({length: 4}, () => generateSecret()).join(',');
}

console.log('🔐 Generated Secrets for Strapi Production Deployment');
console.log('=' .repeat(60));
console.log('');
console.log('Copy these values to your .env file:');
console.log('');
console.log(`APP_KEYS=${generateAppKeys()}`);
console.log(`API_TOKEN_SALT=${generateSecret()}`);
console.log(`ADMIN_JWT_SECRET=${generateSecret()}`);
console.log(`TRANSFER_TOKEN_SALT=${generateSecret()}`);
console.log(`JWT_SECRET=${generateSecret()}`);
console.log('');
console.log('Database password (generate a strong one):');
console.log(`DATABASE_PASSWORD=${crypto.randomBytes(16).toString('hex')}`);
console.log('');
console.log('⚠️  Important: Keep these secrets secure and never commit them to version control!');
console.log('💡 Tip: Save these in a password manager or secure note-taking app.');
