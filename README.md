# Stoic Attitude Backend

A Strapi v5.2.0 backend application providing content management and API services for the Stoic Attitude project.

## 🚀 Features

- **Content Management**: Article and Category content types
- **User Authentication**: Extended users-permissions with custom auth
- **File Uploads**: Cloudinary integration for media management
- **Database Support**: SQLite (development), PostgreSQL/MongoDB (production)
- **Health Monitoring**: Built-in health check endpoints
- **Custom APIs**: Mongo authentication services
- **Docker Ready**: Containerized deployment support

## 📋 Prerequisites

- **Node.js**: v18.0.0 - v22.x.x
- **npm**: v6.0.0+
- **Docker**: (Optional, for containerized deployment)
- **Database**: PostgreSQL or MongoDB (for production)

## 🛠 Local Development Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd stoicattitude-backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Copy the example environment file and configure your settings:

```bash
cp example.env .env
```

Edit `.env` with your configuration:

```env
# Server Configuration
HOST=0.0.0.0
PORT=1337

# Security Keys (Generate new ones for production!)
APP_KEYS=your-app-key-1,your-app-key-2,your-app-key-3,your-app-key-4
API_TOKEN_SALT=your-api-token-salt
ADMIN_JWT_SECRET=your-admin-jwt-secret
TRANSFER_TOKEN_SALT=your-transfer-token-salt
JWT_SECRET=your-jwt-secret

# Database Configuration
# For local development (SQLite)
DATABASE_CLIENT=sqlite
DATABASE_FILENAME=.tmp/data.db

# For production (PostgreSQL)
# DATABASE_CLIENT=postgres
# DATABASE_HOST=your-db-host
# DATABASE_PORT=5432
# DATABASE_NAME=your-db-name
# DATABASE_USERNAME=your-db-user
# DATABASE_PASSWORD=your-db-password
# DATABASE_SSL=false

# Cloudinary (for file uploads)
CLOUDINARY_NAME=your-cloudinary-name
CLOUDINARY_KEY=your-cloudinary-key
CLOUDINARY_SECRET=your-cloudinary-secret
```

### 4. Start Development Server

```bash
npm run develop
```

Your Strapi application will be available at:
- **API**: http://localhost:1337
- **Admin Panel**: http://localhost:1337/admin

### 5. Create Admin User

On first run, visit the admin panel and create your first administrator account.

## 🚀 Production Deployment

### Docker Deployment

#### 1. Build Docker Image

```bash
docker build -t stoicattitude-backend .
```

#### 2. Run with Docker

```bash
# Create production environment file
cp .env.production .env

# Run container
docker run -d \
  --name stoicattitude-backend \
  -p 1337:1337 \
  --env-file .env \
  stoicattitude-backend
```

#### 3. Docker Compose (Recommended)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  strapi:
    build: .
    ports:
      - "1337:1337"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    volumes:
      - ./public/uploads:/app/public/uploads
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: strapi
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: your-secure-password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

Run with:

```bash
docker-compose up -d
```

### Cloud Deployment Options

#### Heroku
1. Install Heroku CLI
2. Create Heroku app: `heroku create your-app-name`
3. Add PostgreSQL addon: `heroku addons:create heroku-postgresql:mini`
4. Set environment variables: `heroku config:set KEY=value`
5. Deploy: `git push heroku main`

#### Railway
1. Connect your GitHub repository
2. Set environment variables in Railway dashboard
3. Deploy automatically on push

#### AWS Deployment (Free Tier Available! 🆓)

##### 🎯 COMPLETELY FREE Setup Guide (12 months)

**What you get for FREE:**
- **EC2 t2.micro**: 750 hours/month (24/7 operation)
- **RDS db.t2.micro**: 750 hours/month + 20GB storage
- **S3**: 5GB storage + file uploads
- **SSL Certificate**: Free via Let's Encrypt or AWS Certificate Manager
- **Total monthly cost**: $0 for first 12 months!

**Quick Free Deployment Steps:**

**🤖 AUTOMATED (Easiest):**
```bash
# One-command deployment script
./scripts/aws-free-deploy.sh
```

**📖 MANUAL (Step-by-step):**
1. [Jump to EC2 Setup](#option-3-aws-ec2-with-docker-free-tier---recommended) (Free tier)
2. [Configure RDS](#database-setup-rds---free-tier-available) or use SQLite
3. [Setup S3](#file-storage-s3---free-tier-available) for uploads
4. [Configure domain and SSL](#ssl-certificate-https)

---

##### Option 1: AWS App Runner (⚠️ Not Free - Skip for free deployment)

1. **Prepare your repository:**
   ```bash
   # Ensure your code is pushed to GitHub
   git add .
   git commit -m "Prepare for AWS deployment"
   git push origin main
   ```

2. **Create App Runner service:**
   - Go to AWS App Runner console
   - Click "Create service"
   - Choose "Source code repository" → Connect to GitHub
   - Select your repository and branch
   - Configure build settings:
     ```yaml
     # Add apprunner.yaml to your project root
     version: 1.0
     runtime: nodejs18
     build:
       commands:
         build:
           - npm ci
           - npm run build
     run:
       runtime-version: 18
       command: npm start
       network:
         port: 1337
         env: PORT
       env:
         - name: NODE_ENV
           value: production
     ```

3. **Configure environment variables in App Runner:**
   - Add all your production environment variables
   - Include database connection details

##### Option 2: AWS ECS with Fargate (⚠️ Not Free - Skip for free deployment)

1. **Push Docker image to ECR:**
   ```bash
   # Create ECR repository
   aws ecr create-repository --repository-name stoicattitude-backend

   # Get login token
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

   # Build and tag image
   docker build -t stoicattitude-backend .
   docker tag stoicattitude-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/stoicattitude-backend:latest

   # Push image
   docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/stoicattitude-backend:latest
   ```

2. **Create ECS Task Definition:**
   ```json
   {
     "family": "stoicattitude-backend",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT:role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "strapi",
         "image": "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/stoicattitude-backend:latest",
         "portMappings": [
           {
             "containerPort": 1337,
             "protocol": "tcp"
           }
         ],
         "environment": [
           {
             "name": "NODE_ENV",
             "value": "production"
           }
         ],
         "secrets": [
           {
             "name": "DATABASE_URL",
             "valueFrom": "arn:aws:ssm:us-east-1:YOUR_ACCOUNT:parameter/strapi/database-url"
           }
         ],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/stoicattitude-backend",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs"
           }
         }
       }
     ]
   }
   ```

3. **Create ECS Service with Load Balancer**

##### Option 3: AWS EC2 with Docker (🆓 FREE TIER - RECOMMENDED!)

**Free Tier Details:**
- **EC2**: 750 hours/month of t2.micro instance (enough for 24/7 operation)
- **EBS**: 30 GB of General Purpose SSD storage
- **Data Transfer**: 15 GB outbound per month
- **Valid for**: 12 months from account creation

1. **Launch FREE EC2 instance:**
   - Choose **Amazon Linux 2 AMI** (Free tier eligible)
   - Instance type: **t2.micro** (Free tier only - don't choose t3.micro!)
   - Storage: 30 GB GP2 (free tier limit)
   - Configure security group to allow HTTP (80), HTTPS (443), SSH (22)

2. **Connect and setup:**
   ```bash
   # Connect to your EC2 instance
   ssh -i your-key.pem ec2-user@your-instance-ip

   # Install Docker
   sudo yum update -y
   sudo yum install -y docker
   sudo service docker start
   sudo usermod -a -G docker ec2-user

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Clone your repository
   git clone https://github.com/your-username/stoicattitude-backend.git
   cd stoicattitude-backend
   ```

3. **Setup environment and deploy:**
   ```bash
   # Create production environment file
   nano .env.production

   # Run with Docker Compose
   docker-compose -f docker-compose.prod.yml up -d
   ```

4. **Setup Nginx reverse proxy:**
   ```bash
   # Install Nginx
   sudo yum install -y nginx

   # Configure Nginx
   sudo nano /etc/nginx/conf.d/strapi.conf
   ```

   Add this configuration:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

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
       }
   }
   ```

   ```bash
   # Start Nginx
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

##### Database Setup (RDS) - 🆓 FREE TIER AVAILABLE!

**Free Tier Details:**
- **RDS**: 750 hours/month of db.t2.micro instance
- **Storage**: 20 GB General Purpose SSD storage
- **Backup**: 20 GB backup storage
- **Valid for**: 12 months from account creation

**Option A: FREE RDS PostgreSQL (Recommended for production):**
1. **Create FREE RDS PostgreSQL instance:**
   ```bash
   # Using AWS CLI
   aws rds create-db-instance \
     --db-instance-identifier strapi-db \
     --db-instance-class db.t2.micro \
     --engine postgres \
     --master-username strapiuser \
     --master-user-password your-secure-password \
     --allocated-storage 20 \
     --vpc-security-group-ids sg-your-security-group \
     --db-subnet-group-name your-subnet-group
   ```

**Option B: SQLite on EC2 (Completely free, simpler setup):**
For development or small projects, you can use SQLite directly on your EC2 instance:
```env
# Use SQLite (no additional database server needed)
DATABASE_CLIENT=sqlite
DATABASE_FILENAME=.tmp/data.db
```

2. **Configure environment variables for RDS:**
   ```env
   DATABASE_CLIENT=postgres
   DATABASE_HOST=your-rds-endpoint.region.rds.amazonaws.com
   DATABASE_PORT=5432
   DATABASE_NAME=strapi
   DATABASE_USERNAME=strapiuser
   DATABASE_PASSWORD=your-secure-password
   DATABASE_SSL=true
   ```

##### File Storage (S3) - 🆓 FREE TIER AVAILABLE!

**Free Tier Details:**
- **Storage**: 5 GB Standard storage
- **Requests**: 20,000 GET requests and 2,000 PUT/POST requests per month
- **Data Transfer**: 15 GB outbound per month
- **Valid for**: 12 months from account creation

1. **Create FREE S3 bucket:**
   ```bash
   aws s3 mb s3://your-strapi-uploads-bucket
   ```

2. **Configure Strapi for S3:**
   ```bash
   npm install @strapi/provider-upload-aws-s3
   ```

   Update `config/plugins.ts`:
   ```typescript
   export default {
     upload: {
       config: {
         provider: 'aws-s3',
         providerOptions: {
           s3Options: {
             accessKeyId: process.env.AWS_ACCESS_KEY_ID,
             secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
             region: process.env.AWS_REGION,
             params: {
               ACL: process.env.AWS_ACL || 'public-read',
               signedUrlExpires: process.env.AWS_SIGNED_URL_EXPIRES || 15 * 60,
               Bucket: process.env.AWS_BUCKET,
             },
           },
         },
       },
     },
   };
   ```

3. **Add S3 environment variables:**
   ```env
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-east-1
   AWS_BUCKET=your-strapi-uploads-bucket
   AWS_ACL=public-read
   ```

##### Environment Variables Management

**Using AWS Systems Manager Parameter Store:**
```bash
# Store sensitive variables
aws ssm put-parameter \
  --name "/strapi/database-password" \
  --value "your-secure-password" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/strapi/jwt-secret" \
  --value "your-jwt-secret" \
  --type "SecureString"
```

**Using AWS Secrets Manager:**
```bash
# Create secret
aws secretsmanager create-secret \
  --name "strapi/production" \
  --description "Strapi production environment variables" \
  --secret-string '{
    "DATABASE_PASSWORD": "your-secure-password",
    "JWT_SECRET": "your-jwt-secret",
    "API_TOKEN_SALT": "your-api-token-salt"
  }'
```

##### SSL Certificate (HTTPS)

**Using AWS Certificate Manager:**
1. Request certificate in ACM
2. Configure your load balancer or CloudFront to use the certificate
3. Update your domain DNS to point to AWS resources

##### Monitoring and Logging

**CloudWatch setup:**
```bash
# Install CloudWatch agent on EC2
wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

**Docker Compose with logging:**
```yaml
version: '3.8'
services:
  strapi:
    build: .
    ports:
      - "1337:1337"
    env_file:
      - .env.production
    logging:
      driver: awslogs
      options:
        awslogs-group: strapi-logs
        awslogs-region: us-east-1
        awslogs-stream-prefix: strapi
```

##### 💰 FREE TIER OPTIMIZATION & MONITORING

**Stay Within Free Limits:**
- **EC2**: Use only `t2.micro` (t3.micro is NOT free tier)
- **RDS**: Use `db.t2.micro` with max 20GB storage
- **S3**: Monitor storage usage (5GB limit)
- **Data Transfer**: Keep under 15GB/month outbound

**Essential Monitoring Setup:**
```bash
# Set up billing alerts to avoid charges
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "Free-Tier-Alert",
    "BudgetLimit": {
      "Amount": "1.00",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

**Free Tier Usage Dashboard:**
- Go to AWS Console → Billing → Free Tier
- Monitor your usage daily for first month
- Set up alerts when approaching limits

**After 12 months (when free tier expires):**
- Monthly cost: ~$10-15 for t2.micro + db.t2.micro
- Scale down to t2.nano ($3.50/month) if low traffic
- Consider migrating to always-free services like Railway/Heroku

##### 🤖 AUTOMATED FREE DEPLOYMENT

Use the included script for one-command deployment:

```bash
# Prerequisites: AWS CLI installed and configured
aws configure  # Set up your AWS credentials

# Run the automated deployment
./scripts/aws-free-deploy.sh
```

**What the script does:**
- ✅ Creates EC2 t2.micro instance (FREE TIER)
- ✅ Sets up security groups for web access
- ✅ Generates SSH key pair
- ✅ Installs Docker, Node.js, and dependencies
- ✅ Provides connection details and next steps
- ✅ Stays within all free tier limits

**After script completes:**
1. SSH into your server: `ssh -i strapi-key.pem ec2-user@YOUR_IP`
2. Clone your repo and deploy as shown in script output
3. Your Strapi will be accessible at `http://YOUR_IP:1337`

#### DigitalOcean
Use the provided Dockerfile with DigitalOcean App Platform or Droplets.

## 🔗 Connecting to Frontend (Vercel)

### Frontend Environment Variables

In your Vercel frontend project, add these environment variables:

```env
# In your frontend .env.local or Vercel dashboard
NEXT_PUBLIC_STRAPI_API_URL=https://your-backend-domain.com
STRAPI_API_TOKEN=your-api-token
```

### Generate API Token

1. Go to Settings → API Tokens in your Strapi admin
2. Create a new token with appropriate permissions
3. Copy the token to your frontend environment variables

### CORS Configuration

Update `config/middlewares.ts` to allow your frontend domain:

```typescript
export default [
  'strapi::cors',
  {
    name: 'strapi::cors',
    config: {
      origin: ['http://localhost:3000', 'https://your-vercel-app.vercel.app'],
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'],
      headers: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
      keepHeaderOnError: true,
    },
  },
  // ... other middlewares
];
```

### Frontend API Integration Example

```javascript
// lib/strapi.js
const STRAPI_URL = process.env.NEXT_PUBLIC_STRAPI_API_URL;
const API_TOKEN = process.env.STRAPI_API_TOKEN;

export async function fetchArticles() {
  const response = await fetch(`${STRAPI_URL}/api/articles?populate=*`, {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
    },
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch articles');
  }
  
  return response.json();
}

export async function fetchCategories() {
  const response = await fetch(`${STRAPI_URL}/api/categories`, {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
    },
  });
  
  return response.json();
}
```

## 📡 API Endpoints

### Health Check
- `GET /_health` - Application health status

### Content API
- `GET /api/articles` - Get all articles
- `GET /api/articles/:id` - Get specific article
- `GET /api/categories` - Get all categories
- `GET /api/categories/:id` - Get specific category

### Authentication
- `POST /api/auth/local` - Login
- `POST /api/auth/local/register` - Register
- Custom mongo-auth endpoints available

### File Uploads
- `POST /api/upload` - Upload files (configured with Cloudinary)

## 🔧 Available Scripts

```bash
# Development
npm run develop        # Start development server with auto-reload
npm run start         # Start production server
npm run build         # Build for production

# Database
npm run db:migrate    # Run database migrations

# Strapi CLI
npm run strapi        # Access Strapi CLI commands
```

## 🗂 Project Structure

```
stoicattitude-backend/
├── config/           # Strapi configuration files
├── src/
│   ├── api/         # API endpoints and business logic
│   │   ├── article/ # Article content type
│   │   ├── category/# Category content type
│   │   ├── health/  # Health check endpoints
│   │   └── mongo-auth/ # Custom authentication
│   ├── components/  # Reusable components
│   └── extensions/  # Plugin extensions
├── scripts/         # Deployment scripts
├── public/          # Static files
└── types/           # TypeScript definitions
```

## 🐛 Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Kill process on port 1337
lsof -ti:1337 | xargs kill -9
```

**Database connection errors:**
- Verify database credentials in `.env`
- Ensure database server is running
- Check network connectivity

**Build failures:**
- Clear node_modules: `rm -rf node_modules && npm install`
- Clear Strapi cache: `rm -rf .cache build`

**CORS errors:**
- Update `config/middlewares.ts` with your frontend domain
- Verify API token permissions

### Environment-Specific Files

- `.env.local` - Local development
- `.env.production` - Production deployment
- `.env.prod` - Production environment variables

### Logs and Debugging

```bash
# View Docker logs
docker logs stoicattitude-backend

# Enable debug mode
DEBUG=strapi:* npm run develop
```

## 📚 Documentation

- [Strapi Documentation](https://docs.strapi.io/)
- [Strapi v5 Migration Guide](https://docs.strapi.io/dev-docs/migration/v4-to-v5)
- [Deployment Guide](https://docs.strapi.io/dev-docs/deployment)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is private and proprietary.

---

For questions or support, please contact the development team.
