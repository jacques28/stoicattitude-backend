# 🌐 DOMAIN SETUP GUIDE
## Stoic Attitude - API & Admin Panel Configuration

This guide explains how to configure your domain structure for the Stoic Attitude project with separate frontend and API domains.

---

## 🎯 DOMAIN ARCHITECTURE

### Recommended Domain Structure:
```
📱 Frontend (Next.js):     https://stoicattitude.com
🔧 API & Admin (Strapi):   https://api.stoicattitude.com
📊 Admin Panel:            https://api.stoicattitude.com/admin
```

### Alternative Structure (if preferred):
```
📱 Frontend:               https://www.stoicattitude.com  
🔧 API & Admin:           https://api.stoicattitude.com
📊 Admin Panel:            https://api.stoicattitude.com/admin
```

---

## 🔧 DNS CONFIGURATION

### Required DNS Records:

#### For your domain registrar (Namecheap, GoDaddy, etc.):

```dns
# Main domain pointing to Vercel (Frontend)
Type: CNAME
Name: @
Value: cname.vercel-dns.com

# API subdomain pointing to your EC2 instance
Type: A
Name: api
Value: YOUR_EC2_PUBLIC_IP_ADDRESS

# Optional: www subdomain
Type: CNAME
Name: www
Value: stoicattitude.com
```

### Example DNS Configuration:
```
A     @     76.76.19.123          # Main domain → Vercel
A     api   54.123.45.67          # API subdomain → EC2
CNAME www   stoicattitude.com     # www → main domain
```

---

## 🚀 DEPLOYMENT CONFIGURATION

### 1. EC2 Instance Setup

#### Update your EC2 security group:
```bash
Inbound Rules:
- SSH (22) from your IP
- HTTP (80) from anywhere (0.0.0.0/0)
- HTTPS (443) from anywhere (0.0.0.0/0)
- Custom TCP (1337) from anywhere (for direct API access)
```

#### SSL Certificate for api.stoicattitude.com:
```bash
# After domain is pointing to your EC2 IP:
sudo certbot --nginx -d api.stoicattitude.com

# Verify certificate
sudo certbot certificates

# Test auto-renewal
sudo certbot renew --dry-run
```

### 2. Strapi Configuration (Already Done ✅)

Your Strapi backend is already configured for:
- **Production API**: `https://api.stoicattitude.com`
- **Admin Panel**: `https://api.stoicattitude.com/admin`
- **CORS**: Properly configured for your frontend domain

### 3. Frontend Configuration

Update your frontend environment variables:

#### Vercel Environment Variables:
```bash
NEXT_PUBLIC_STRAPI_URL=https://api.stoicattitude.com
NEXT_PUBLIC_SITE_URL=https://stoicattitude.com
NEXTAUTH_URL=https://stoicattitude.com
```

#### Frontend API calls should use:
```typescript
// In your frontend code:
const API_BASE_URL = process.env.NEXT_PUBLIC_STRAPI_URL; // https://api.stoicattitude.com
```

---

## 🔒 SECURITY CONFIGURATION

### HTTPS/SSL Setup

#### 1. Automatic Certificate (Recommended):
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Install certificate for api.stoicattitude.com
sudo certbot --nginx -d api.stoicattitude.com

# Certificate will auto-renew every 90 days
```

#### 2. Nginx Configuration (Already Configured ✅):
The Nginx config is already set up for `api.stoicattitude.com` with:
- SSL termination
- Security headers
- Proxy to Strapi on port 1337
- Static file serving for uploads

### CORS Security
Your Strapi is configured to accept requests from:
- `https://stoicattitude.com` (your main domain)
- `https://www.stoicattitude.com` (www subdomain)
- `http://localhost:3000` (development)

---

## 🧪 TESTING YOUR SETUP

### 1. Test Domain Resolution:
```bash
# Test API domain resolves to your EC2 IP
nslookup api.stoicattitude.com

# Test main domain resolves to Vercel
nslookup stoicattitude.com
```

### 2. Test API Endpoints:
```bash
# Test health endpoint
curl https://api.stoicattitude.com/api/health

# Test admin panel (should redirect to login)
curl -I https://api.stoicattitude.com/admin
```

### 3. Test Admin Panel Access:
1. Go to: `https://api.stoicattitude.com/admin`
2. You should see the Strapi admin login page
3. Create your first admin user
4. Login and verify you can manage content

### 4. Test Frontend API Communication:
```javascript
// In your frontend, test API calls:
fetch('https://api.stoicattitude.com/api/articles')
  .then(response => response.json())
  .then(data => console.log('API working:', data));
```

---

## 👤 ADMIN USER SETUP

### Creating Your First Admin User:

#### Method 1: Through Admin Panel (Recommended)
1. Visit: `https://api.stoicattitude.com/admin`
2. Fill out the admin registration form:
   - First Name: Your first name
   - Last Name: Your last name
   - Email: your-email@example.com
   - Password: Strong password (8+ chars, numbers, symbols)
3. Click "Let's start"

#### Method 2: Command Line (Alternative)
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Navigate to your app
cd /home/ubuntu/stoic-backend/current

# Create admin user
npm run strapi admin:create-user \
  --firstname="Your Name" \
  --lastname="Last Name" \
  --email="your-email@example.com" \
  --password="YourStrongPassword123!"
```

---

## 📱 FRONTEND INTEGRATION

### API Integration in Your Next.js App:

#### 1. Update Environment Variables:
```bash
# .env.local (development)
NEXT_PUBLIC_STRAPI_URL=http://localhost:1337

# .env.production (production - set in Vercel)
NEXT_PUBLIC_STRAPI_URL=https://api.stoicattitude.com
```

#### 2. Update API Client:
```typescript
// lib/api-client.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';

export const strapiApi = {
  async getArticles() {
    const response = await fetch(`${API_BASE_URL}/api/articles?populate=*`);
    return response.json();
  },
  
  async getArticle(slug: string) {
    const response = await fetch(
      `${API_BASE_URL}/api/articles?filters[slug][$eq]=${slug}&populate=*`
    );
    return response.json();
  }
};
```

#### 3. Content Management Workflow:
1. **Content Creation**: Use `https://api.stoicattitude.com/admin`
2. **Content Publishing**: Publish articles through admin panel
3. **Frontend Display**: Your Next.js app fetches from `https://api.stoicattitude.com/api/*`

---

## 🔧 TROUBLESHOOTING

### Common Issues:

#### 1. Admin Panel Not Accessible
```bash
# Check if Strapi is running
pm2 status

# Check logs
pm2 logs stoic-backend

# Restart if needed
pm2 restart stoic-backend
```

#### 2. CORS Errors
- Verify your frontend domain is in the CORS configuration
- Check browser network tab for exact error
- Ensure HTTPS is used in production

#### 3. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew if needed
sudo certbot renew

# Check Nginx config
sudo nginx -t
sudo systemctl reload nginx
```

#### 4. Domain Not Resolving
- Verify DNS records are correct
- Allow 24-48 hours for DNS propagation
- Use online DNS checker tools

### Log Locations:
```bash
# Application logs
pm2 logs stoic-backend

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# SSL certificate logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

---

## 📋 DEPLOYMENT CHECKLIST

### Domain Setup:
- [ ] DNS A record: `api.stoicattitude.com` → EC2 IP
- [ ] DNS CNAME: `stoicattitude.com` → Vercel
- [ ] SSL certificate installed for api.stoicattitude.com
- [ ] Nginx configuration updated
- [ ] Domain propagation complete (24-48 hours)

### Strapi Configuration:
- [ ] Environment variables updated with correct domains
- [ ] CORS configured for frontend domain
- [ ] Admin panel accessible at api.stoicattitude.com/admin
- [ ] First admin user created
- [ ] API endpoints responding correctly

### Frontend Integration:
- [ ] Vercel environment variables updated
- [ ] API client configured for production domain
- [ ] CORS working between frontend and API
- [ ] Content fetching from Strapi working

### Security:
- [ ] HTTPS enabled for both domains
- [ ] SSL certificates auto-renewing
- [ ] Firewall configured correctly
- [ ] Admin panel secured with strong password

---

## 🎉 FINAL VERIFICATION

Once everything is set up, you should have:

### ✅ Working URLs:
- **Frontend**: `https://stoicattitude.com` (Next.js app)
- **API**: `https://api.stoicattitude.com/api/health` (Health check)
- **Admin**: `https://api.stoicattitude.com/admin` (Content management)
- **Articles**: `https://api.stoicattitude.com/api/articles` (Content API)

### ✅ Admin Panel Features:
- Create and edit articles
- Manage content types
- User management
- Media library
- Settings configuration

### ✅ API Features:
- RESTful API endpoints
- Content filtering and pagination
- Media file serving
- Authentication endpoints

Your Stoic Attitude project is now ready for professional content management! 🚀



