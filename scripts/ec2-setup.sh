#!/bin/bash
# ===================================================================
# EC2 Instance Setup Script for Strapi Backend
# ===================================================================
# 🚀 Run this script on a fresh Ubuntu 22.04 EC2 instance
# 📦 Installs Node.js, PM2, Nginx, and configures the environment
# 🔒 Sets up security and SSL

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NODE_VERSION="22.12.0"
APP_USER="ubuntu"
APP_DIR="/home/ubuntu/stoic-backend"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BLUE}🚀 Starting EC2 Setup for Stoic Attitude Backend${NC}"
echo -e "${BLUE}====================================================================${NC}"

# ===================================================================
# SYSTEM UPDATE AND BASIC PACKAGES
# ===================================================================
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${YELLOW}📦 Installing essential packages...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    nginx \
    ufw \
    fail2ban \
    logrotate \
    certbot \
    python3-certbot-nginx

# ===================================================================
# NODE.JS INSTALLATION
# ===================================================================
echo -e "${YELLOW}🔧 Installing Node.js ${NODE_VERSION}...${NC}"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install and use Node.js
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION

# Verify installation
node --version
npm --version

# ===================================================================
# PM2 INSTALLATION
# ===================================================================
echo -e "${YELLOW}⚙️  Installing PM2 Process Manager...${NC}"
npm install -g pm2

# Configure PM2 startup
sudo env PATH=$PATH:/home/ubuntu/.nvm/versions/node/v${NODE_VERSION}/bin \
    /home/ubuntu/.nvm/versions/node/v${NODE_VERSION}/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# ===================================================================
# APPLICATION DIRECTORY SETUP
# ===================================================================
echo -e "${YELLOW}📁 Setting up application directories...${NC}"
mkdir -p $APP_DIR
mkdir -p $APP_DIR/logs
mkdir -p /home/ubuntu/backups

# Set proper permissions
chown -R $APP_USER:$APP_USER $APP_DIR
chmod 755 $APP_DIR

# ===================================================================
# NGINX CONFIGURATION
# ===================================================================
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"

# Create Nginx configuration for Strapi
sudo tee $NGINX_CONF_DIR/stoic-backend << 'EOF'
server {
    listen 80;
    server_name api.stoicattitude.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
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
    
    # Strapi backend
    location / {
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
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static files (uploads)
    location /uploads/ {
        alias /home/ubuntu/stoic-backend/current/public/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:1337/api/health;
        access_log off;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /\.(env|json)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the site
sudo ln -sf $NGINX_CONF_DIR/stoic-backend $NGINX_ENABLED_DIR/
sudo rm -f $NGINX_ENABLED_DIR/default

# Test Nginx configuration
sudo nginx -t

# ===================================================================
# FIREWALL CONFIGURATION
# ===================================================================
echo -e "${YELLOW}🔒 Configuring firewall...${NC}"

# Configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ===================================================================
# FAIL2BAN CONFIGURATION
# ===================================================================
echo -e "${YELLOW}🛡️  Configuring Fail2Ban...${NC}"

sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/*error.log
findtime = 600
bantime = 7200
maxretry = 10
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# ===================================================================
# LOG ROTATION SETUP
# ===================================================================
echo -e "${YELLOW}📝 Setting up log rotation...${NC}"

sudo tee /etc/logrotate.d/stoic-backend << 'EOF'
/home/ubuntu/stoic-backend/current/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 0640 ubuntu ubuntu
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
EOF

# ===================================================================
# ENVIRONMENT SETUP
# ===================================================================
echo -e "${YELLOW}⚙️  Setting up environment...${NC}"

# Create environment file template
tee /home/ubuntu/.env.production.template << 'EOF'
# ===================================================================
# PRODUCTION ENVIRONMENT TEMPLATE
# ===================================================================
# 🔒 Copy this to .env.production and fill in actual values
# 📝 NEVER commit the actual .env.production file

NODE_ENV=production
HOST=0.0.0.0
PORT=1337

# AWS RDS Database
DATABASE_CLIENT=postgres
DATABASE_HOST=database-1.cepui2meiura.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_NAME=stoicattitude_db
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=n8-w2Dd.TEFExuk
DATABASE_SSL=true
DATABASE_SSL_REJECT_UNAUTHORIZED=false

# GENERATE NEW SECRETS FOR PRODUCTION!
APP_KEYS=GENERATE_NEW_KEYS_HERE
API_TOKEN_SALT=GENERATE_NEW_SALT_HERE
ADMIN_JWT_SECRET=GENERATE_NEW_SECRET_HERE
TRANSFER_TOKEN_SALT=GENERATE_NEW_SALT_HERE
JWT_SECRET=GENERATE_NEW_SECRET_HERE

# Frontend URL (replace with your Vercel domain)
FRONTEND_URL=https://your-app.vercel.app
ADMIN_URL=https://your-app.vercel.app/admin
EOF

# ===================================================================
# MONITORING SETUP
# ===================================================================
echo -e "${YELLOW}📊 Setting up monitoring...${NC}"

# Create monitoring script
tee /home/ubuntu/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

echo "=== System Status ==="
date
echo ""

echo "=== CPU and Memory ==="
top -bn1 | head -n 5
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== PM2 Status ==="
pm2 status
echo ""

echo "=== Application Logs (last 20 lines) ==="
pm2 logs stoic-backend --lines 20 --nostream
echo ""

echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager -l
echo ""
EOF

chmod +x /home/ubuntu/monitor.sh

# Create daily monitoring cron job
(crontab -l 2>/dev/null; echo "0 8 * * * /home/ubuntu/monitor.sh > /home/ubuntu/daily-report.log 2>&1") | crontab -

# ===================================================================
# BACKUP SCRIPT
# ===================================================================
echo -e "${YELLOW}💾 Setting up backup system...${NC}"

tee /home/ubuntu/backup.sh << 'EOF'
#!/bin/bash
# Application backup script

BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/home/ubuntu/stoic-backend/current"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup application
if [ -d "$APP_DIR" ]; then
    echo "Creating application backup..."
    tar -czf "$BACKUP_DIR/app-backup-$DATE.tar.gz" -C "$APP_DIR" .
    echo "Application backup created: app-backup-$DATE.tar.gz"
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "app-backup-*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/ubuntu/backup.sh

# Schedule daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup.sh >> /home/ubuntu/backup.log 2>&1") | crontab -

# ===================================================================
# FINAL SETUP
# ===================================================================
echo -e "${YELLOW}🔧 Final setup steps...${NC}"

# Start services
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# Create deployment info
tee /home/ubuntu/deployment-info.txt << EOF
=== EC2 Instance Setup Completed ===
Date: $(date)
Node.js Version: $NODE_VERSION
PM2 Installed: Yes
Nginx Configured: Yes
Firewall Enabled: Yes
Fail2Ban Enabled: Yes

Next Steps:
1. Copy .env.production.template to .env.production and fill in values
2. Configure your domain in Nginx config
3. Setup SSL with: sudo certbot --nginx -d yourdomain.com
4. Deploy your application using GitHub Actions

Useful Commands:
- pm2 status (check application status)
- pm2 logs stoic-backend (view logs)
- sudo nginx -t (test nginx config)
- sudo systemctl status nginx (nginx status)
- ./monitor.sh (system monitoring)
- ./backup.sh (manual backup)

Configuration Files:
- Nginx: /etc/nginx/sites-available/stoic-backend
- Environment: /home/ubuntu/.env.production
- PM2 Logs: /home/ubuntu/stoic-backend/current/logs/
EOF

# ===================================================================
# COMPLETION
# ===================================================================
echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}✅ EC2 Setup Completed Successfully!${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Copy the environment template to production config:"
echo "   cp /home/ubuntu/.env.production.template /home/ubuntu/.env.production"
echo ""
echo "2. Edit the production environment file:"
echo "   nano /home/ubuntu/.env.production"
echo ""
echo "3. Generate new security keys:"
echo "   node -e \"console.log(require('crypto').randomBytes(64).toString('base64'))\""
echo ""
echo "4. Configure your domain in Nginx:"
echo "   sudo nano /etc/nginx/sites-available/stoic-backend"
echo ""
echo "5. Setup SSL certificate:"
echo "   sudo certbot --nginx -d yourdomain.com"
echo ""
echo "6. Setup GitHub Secrets for CI/CD:"
echo "   - EC2_HOST: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   - EC2_USERNAME: ubuntu"
echo "   - EC2_SSH_KEY: (your private SSH key)"
echo ""
echo -e "${BLUE}🔍 View setup details: cat /home/ubuntu/deployment-info.txt${NC}"
echo -e "${BLUE}📊 Monitor system: ./monitor.sh${NC}"
echo -e "${GREEN}🎉 Ready for deployment!${NC}"
