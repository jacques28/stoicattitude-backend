#!/bin/bash

# EC2 Setup Script for Stoic Attitude
# This script sets up a fresh EC2 instance for Strapi deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${GREEN}🔧 Setting up EC2 instance for Stoic Attitude${NC}"

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y curl wget git htop unzip nginx ufw

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
rm get-docker.sh

# Install Docker Compose
print_status "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 1337

# Create application directories
print_status "Creating application directories..."
sudo mkdir -p /opt/stoic-webapp/{app,postgres-data,uploads,backups,logs}
sudo chown -R ubuntu:ubuntu /opt/stoic-webapp

# Setup log rotation for Docker
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    missingok
    notifempty
    sharedscripts
    compress
    delaycompress
}
EOF

# Setup monitoring script
print_status "Creating monitoring script..."
tee /opt/stoic-webapp/monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/opt/stoic-webapp/logs/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log with timestamp
log_message() {
    echo "[$DATE] $1" >> $LOG_FILE
}

# Check if containers are running
if ! docker ps | grep -q stoic-postgres; then
    log_message "WARNING: PostgreSQL container is down. Attempting restart..."
    docker start stoic-postgres
    if [ $? -eq 0 ]; then
        log_message "INFO: PostgreSQL container restarted successfully"
    else
        log_message "ERROR: Failed to restart PostgreSQL container"
    fi
fi

if ! docker ps | grep -q stoic-strapi; then
    log_message "WARNING: Strapi container is down. Attempting restart..."
    docker start stoic-strapi
    if [ $? -eq 0 ]; then
        log_message "INFO: Strapi container restarted successfully"
    else
        log_message "ERROR: Failed to restart Strapi container"
    fi
fi

# Check disk usage
DISK_USAGE=$(df /opt/stoic-webapp | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    log_message "WARNING: Disk usage is at ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ $MEMORY_USAGE -gt 85 ]; then
    log_message "WARNING: Memory usage is at ${MEMORY_USAGE}%"
fi

# Check if services are responding
if ! curl -sf http://localhost:1337/api/health > /dev/null; then
    log_message "WARNING: Strapi health check failed"
fi
EOF

chmod +x /opt/stoic-webapp/monitor.sh

# Setup backup script
print_status "Creating backup script..."
tee /opt/stoic-webapp/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/stoic-webapp/backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/opt/stoic-webapp/logs/backup.log"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log_message "Starting backup process..."

mkdir -p $BACKUP_DIR

# Backup PostgreSQL if container is running
if docker ps | grep -q stoic-postgres; then
    log_message "Backing up PostgreSQL database..."
    docker exec stoic-postgres pg_dump -U strapi_user stoic_attitude > $BACKUP_DIR/db_backup_$DATE.sql
    if [ $? -eq 0 ]; then
        log_message "Database backup completed successfully"
    else
        log_message "ERROR: Database backup failed"
    fi
else
    log_message "WARNING: PostgreSQL container not running, skipping database backup"
fi

# Backup uploads directory
if [ -d "/opt/stoic-webapp/uploads" ]; then
    log_message "Backing up uploads directory..."
    tar -czf $BACKUP_DIR/uploads_backup_$DATE.tar.gz -C /opt/stoic-webapp uploads
    if [ $? -eq 0 ]; then
        log_message "Uploads backup completed successfully"
    else
        log_message "ERROR: Uploads backup failed"
    fi
fi

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

log_message "Backup process completed"
EOF

chmod +x /opt/stoic-webapp/backup.sh

# Setup cleanup script
print_status "Creating cleanup script..."
tee /opt/stoic-webapp/cleanup.sh << 'EOF'
#!/bin/bash

LOG_FILE="/opt/stoic-webapp/logs/cleanup.log"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log_message "Starting cleanup process..."

# Clean up Docker resources
docker system prune -f
docker volume prune -f

# Clean up old log files
find /opt/stoic-webapp/logs -name "*.log" -mtime +30 -delete

log_message "Cleanup process completed"
EOF

chmod +x /opt/stoic-webapp/cleanup.sh

# Setup cron jobs
print_status "Setting up cron jobs..."
(crontab -l 2>/dev/null; echo "# Stoic Attitude monitoring and maintenance") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/stoic-webapp/monitor.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/stoic-webapp/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/stoic-webapp/cleanup.sh") | crontab -

# Configure Nginx (basic setup)
print_status "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/stoic-webapp << 'EOF'
server {
    listen 80;
    server_name _;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=admin:10m rate=5r/s;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Admin routes
    location /admin {
        limit_req zone=admin burst=10 nodelay;
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:1337;
        access_log off;
    }

    # Static files
    location /uploads/ {
        proxy_pass http://localhost:1337;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/stoic-webapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl enable nginx

# Create environment template
print_status "Creating environment template..."
tee /opt/stoic-webapp/app/.env.example << 'EOF'
# Server Configuration
NODE_ENV=production
HOST=0.0.0.0
PORT=1337

# Security Secrets (CHANGE THESE IN PRODUCTION!)
APP_KEYS=your_app_keys_here
API_TOKEN_SALT=your_api_token_salt_here
ADMIN_JWT_SECRET=your_admin_jwt_secret_here
TRANSFER_TOKEN_SALT=your_transfer_token_salt_here
JWT_SECRET=your_jwt_secret_here

# Database Configuration
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=stoic_attitude
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=your_secure_password_here
DATABASE_SSL=false
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Public URL (Replace with your domain or EC2 public IP)
STRAPI_URL=http://YOUR_INSTANCE_PUBLIC_IP:1337

# File Upload Configuration
UPLOAD_PROVIDER=local
UPLOAD_SIZE_LIMIT=10485760

# Security
ADMIN_PATH=/admin
EOF

# Setup system monitoring
print_status "Installing system monitoring tools..."
sudo apt install -y htop iotop nethogs

print_status "EC2 setup completed successfully! 🎉"
echo ""
echo "Next steps:"
echo "1. 📝 Create .env file in /opt/stoic-webapp/app/stoicattitude-backend/"
echo "2. 📋 Copy your application code to /opt/stoic-webapp/app/stoicattitude-backend/"
echo "3. 🚀 Run the deployment script: ./scripts/deploy-ec2.sh"
echo ""
echo "Useful paths:"
echo "📁 Application: /opt/stoic-webapp/app/stoicattitude-backend/"
echo "📁 Backups: /opt/stoic-webapp/backups/"
echo "📁 Logs: /opt/stoic-webapp/logs/"
echo "📁 Uploads: /opt/stoic-webapp/uploads/"
echo ""
echo "Important: Please logout and login again to apply Docker group permissions!"
print_warning "Remember to configure your security group to allow HTTP (80), HTTPS (443), and Strapi (1337) ports!"
