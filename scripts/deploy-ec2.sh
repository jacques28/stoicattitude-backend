#!/bin/bash

# EC2 Deployment Script for Stoic Attitude Strapi Backend
# This script automates the deployment process on EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/stoic-webapp/app/stoicattitude-backend"
BACKUP_DIR="/opt/stoic-webapp/backups"
ENV_FILE="$APP_DIR/.env"

echo -e "${GREEN}🚀 Starting EC2 deployment for Stoic Attitude Backend${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as correct user
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run as root. Use ubuntu user."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
print_status "Creating application directories..."
sudo mkdir -p /opt/stoic-webapp/{app,postgres-data,uploads,backups}
sudo chown -R ubuntu:ubuntu /opt/stoic-webapp

# Navigate to application directory
cd $APP_DIR

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file not found at $ENV_FILE"
    print_warning "Please create .env file with required configurations"
    exit 1
fi

# Load environment variables
source $ENV_FILE

# Validate required environment variables
required_vars=("DATABASE_PASSWORD" "APP_KEYS" "API_TOKEN_SALT" "ADMIN_JWT_SECRET" "TRANSFER_TOKEN_SALT" "JWT_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set"
        exit 1
    fi
done

# Create backup before deployment
print_status "Creating backup before deployment..."
if docker ps | grep -q stoic-postgres; then
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p $BACKUP_DIR
    docker exec stoic-postgres pg_dump -U ${DATABASE_USERNAME:-strapi_user} ${DATABASE_NAME:-stoic_attitude} > $BACKUP_DIR/pre_deploy_backup_$timestamp.sql
    print_status "Database backup created: $BACKUP_DIR/pre_deploy_backup_$timestamp.sql"
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f docker-compose.ec2.yml down --remove-orphans

# Pull latest images
print_status "Pulling latest PostgreSQL image..."
docker pull postgres:15-alpine

# Build new Strapi image
print_status "Building Strapi application..."
docker build -f Dockerfile.ec2 -t stoic-strapi:latest .

# Start services
print_status "Starting services..."
docker-compose -f docker-compose.ec2.yml up -d

# Wait for services to be healthy
print_status "Waiting for services to start..."
sleep 30

# Check if PostgreSQL is running
max_attempts=12
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec stoic-postgres pg_isready -U ${DATABASE_USERNAME:-strapi_user} -d ${DATABASE_NAME:-stoic_attitude} &> /dev/null; then
        print_status "PostgreSQL is ready!"
        break
    fi
    print_warning "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
    sleep 10
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "PostgreSQL failed to start properly"
    exit 1
fi

# Check if Strapi is running
max_attempts=12
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:1337/api/health &> /dev/null; then
        print_status "Strapi is ready!"
        break
    fi
    print_warning "Waiting for Strapi... (attempt $attempt/$max_attempts)"
    sleep 15
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Strapi failed to start properly"
    print_warning "Check logs with: docker logs stoic-strapi"
    exit 1
fi

# Display service status
print_status "Deployment completed successfully! 🎉"
echo ""
echo "Service Status:"
docker-compose -f docker-compose.ec2.yml ps

echo ""
echo "Access URLs:"
echo "🌐 Strapi API: http://$(curl -s ifconfig.me):1337"
echo "🔧 Strapi Admin: http://$(curl -s ifconfig.me):1337/admin"

echo ""
echo "Useful commands:"
echo "📊 View logs: docker-compose -f docker-compose.ec2.yml logs -f"
echo "🔄 Restart: docker-compose -f docker-compose.ec2.yml restart"
echo "🛑 Stop: docker-compose -f docker-compose.ec2.yml down"

print_status "Deployment completed successfully!"
