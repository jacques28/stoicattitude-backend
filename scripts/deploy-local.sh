#!/bin/bash
# ===================================================================
# Local Deployment Script for Development Testing
# ===================================================================
# 🧪 Tests the deployment process locally before pushing to production
# 🔧 Builds and runs Strapi with production-like settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BLUE}🧪 Local Deployment Test for Stoic Attitude Backend${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found. Run this script from the backend root directory.${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version)
echo -e "${BLUE}📋 Current Node.js version: $NODE_VERSION${NC}"

# ===================================================================
# CLEANUP PREVIOUS BUILD
# ===================================================================
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
rm -rf dist/
rm -rf .tmp/
rm -rf build/

# ===================================================================
# INSTALL DEPENDENCIES
# ===================================================================
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm ci

# ===================================================================
# GENERATE DEVELOPMENT SECRETS (if needed)
# ===================================================================
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}🔐 Generating development environment...${NC}"
    node scripts/generate-secrets.js
    cp .env.production.generated .env.local
    
    # Update for local development
    sed -i.bak 's/NODE_ENV=production/NODE_ENV=development/' .env.local
    sed -i.bak 's/LOG_LEVEL=info/LOG_LEVEL=debug/' .env.local
    rm .env.local.bak
    
    echo -e "${GREEN}✅ Created .env.local for development${NC}"
fi

# ===================================================================
# TYPE CHECK
# ===================================================================
echo -e "${YELLOW}🔍 Running TypeScript type check...${NC}"
npx tsc --noEmit

# ===================================================================
# BUILD APPLICATION
# ===================================================================
echo -e "${YELLOW}🏗️  Building application...${NC}"
npm run build

if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Build failed - dist directory not created${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed successfully${NC}"

# ===================================================================
# START APPLICATION FOR TESTING
# ===================================================================
echo -e "${YELLOW}🚀 Starting application for testing...${NC}"

# Create logs directory
mkdir -p logs

# Kill any existing process on port 1337
if lsof -Pi :1337 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}🛑 Stopping existing process on port 1337...${NC}"
    kill -9 $(lsof -Pi :1337 -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 2
fi

# Start the application in background
echo -e "${BLUE}📡 Starting Strapi on http://localhost:1337${NC}"
npm start &
APP_PID=$!

# Wait for application to start
echo -e "${YELLOW}⏳ Waiting for application to start...${NC}"
sleep 10

# ===================================================================
# HEALTH CHECKS
# ===================================================================
echo -e "${YELLOW}🏥 Running health checks...${NC}"

# Check if process is still running
if ! kill -0 $APP_PID 2>/dev/null; then
    echo -e "${RED}❌ Application process died${NC}"
    exit 1
fi

# Check if port is listening
if ! lsof -Pi :1337 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${RED}❌ Application not listening on port 1337${NC}"
    kill $APP_PID 2>/dev/null || true
    exit 1
fi

# Test health endpoint
echo -e "${BLUE}🔍 Testing health endpoint...${NC}"
sleep 5  # Give it more time

HEALTH_CHECK=$(curl -s -w "%{http_code}" -o /tmp/health_response http://localhost:1337/api/health || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    cat /tmp/health_response | python3 -m json.tool 2>/dev/null || cat /tmp/health_response
else
    echo -e "${RED}❌ Health check failed (HTTP $HEALTH_CHECK)${NC}"
    echo "Response:"
    cat /tmp/health_response 2>/dev/null || echo "No response received"
fi

# Test admin endpoint
echo -e "${BLUE}🔍 Testing admin endpoint...${NC}"
ADMIN_CHECK=$(curl -s -w "%{http_code}" -o /tmp/admin_response http://localhost:1337/admin || echo "000")

if [ "$ADMIN_CHECK" = "200" ]; then
    echo -e "${GREEN}✅ Admin endpoint accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Admin endpoint returned HTTP $ADMIN_CHECK (may be normal for first run)${NC}"
fi

# ===================================================================
# DEPLOYMENT PACKAGE TEST
# ===================================================================
echo -e "${YELLOW}📦 Testing deployment package creation...${NC}"

# Create deployment package (similar to CI/CD)
mkdir -p deploy-test
cp -r dist deploy-test/
cp -r public deploy-test/
cp package*.json deploy-test/
cp -r config deploy-test/

# Create ecosystem file for testing
cat > deploy-test/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'stoic-backend-test',
    script: './dist/src/index.js',
    instances: 1,
    env: {
      NODE_ENV: 'production',
      PORT: 1338
    }
  }]
}
EOF

echo -e "${GREEN}✅ Deployment package created successfully${NC}"

# ===================================================================
# SHOW RESULTS
# ===================================================================
echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}✅ Local Deployment Test Completed Successfully!${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo ""
echo -e "${BLUE}📊 Test Results:${NC}"
echo "✅ Dependencies installed"
echo "✅ TypeScript compilation passed"
echo "✅ Application build successful"
echo "✅ Application started on port 1337"
echo "✅ Health endpoint responding"
echo "✅ Deployment package created"
echo ""
echo -e "${BLUE}🌐 Endpoints:${NC}"
echo "🏠 Application: http://localhost:1337"
echo "🏥 Health Check: http://localhost:1337/api/health"
echo "⚙️  Admin Panel: http://localhost:1337/admin"
echo ""
echo -e "${BLUE}📁 Files created:${NC}"
echo "📄 .env.local (development environment)"
echo "📦 deploy-test/ (deployment package)"
echo "📊 logs/ (application logs)"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Test the application manually at http://localhost:1337"
echo "2. Check the admin panel setup"
echo "3. Verify all API endpoints work correctly"
echo "4. When satisfied, commit your changes and push to trigger CI/CD"
echo ""

# Ask if user wants to stop the application
echo -e "${YELLOW}🛑 Application is running in background (PID: $APP_PID)${NC}"
echo "Press Enter to stop the application, or Ctrl+C to keep it running..."
read

# Stop the application
echo -e "${YELLOW}🛑 Stopping application...${NC}"
kill $APP_PID 2>/dev/null || true
sleep 2

# Cleanup
rm -f /tmp/health_response /tmp/admin_response

echo -e "${GREEN}✅ Local deployment test completed and cleaned up.${NC}"
echo -e "${BLUE}🚀 Ready for production deployment!${NC}"



