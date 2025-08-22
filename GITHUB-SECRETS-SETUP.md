# 🔐 GitHub Secrets Setup Guide
## Configuring CI/CD for Automatic Deployment

This guide explains how to configure GitHub Secrets for automatic deployment to your EC2 instance.

---

## 📋 Required GitHub Secrets

You need to configure these secrets in your GitHub repository:

### 1. **EC2_HOST**
- **Description**: Your EC2 instance public IP address or domain
- **Value**: `YOUR_EC2_PUBLIC_IP` (e.g., `54.123.45.67`)
- **How to find**: 
  ```bash
  # On your EC2 instance, run:
  curl -s http://169.254.169.254/latest/meta-data/public-ipv4
  ```

### 2. **EC2_USERNAME**
- **Description**: SSH username for your EC2 instance
- **Value**: `ubuntu` (for Ubuntu instances)

### 3. **EC2_SSH_KEY**
- **Description**: Private SSH key to access your EC2 instance
- **Value**: Your entire private SSH key (the one you downloaded from AWS)
- **Format**: 
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  ...your key content...
  -----END RSA PRIVATE KEY-----
  ```

---

## 🛠️ Step-by-Step Setup

### Step 1: Access GitHub Secrets
1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret**

### Step 2: Add EC2_HOST Secret
1. **Name**: `EC2_HOST`
2. **Secret**: Your EC2 public IP address
3. Click **Add secret**

### Step 3: Add EC2_USERNAME Secret
1. **Name**: `EC2_USERNAME`
2. **Secret**: `ubuntu`
3. Click **Add secret**

### Step 4: Add EC2_SSH_KEY Secret
1. **Name**: `EC2_SSH_KEY`
2. **Secret**: Copy your entire private SSH key file content
3. **Important**: Include the header and footer lines
4. Click **Add secret**

---

## 🔍 How to Get Your SSH Private Key

### If you have the .pem file from AWS:
```bash
# Display the key content
cat your-key-name.pem

# Copy the entire output including the BEGIN/END lines
```

### If you created your own SSH key:
```bash
# Display your private key
cat ~/.ssh/id_rsa

# Or if you used a different name:
cat ~/.ssh/your-key-name
```

---

## 🧪 Testing the Setup

### 1. Manual SSH Test
Before configuring GitHub Secrets, test SSH access manually:

```bash
# Test SSH connection
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# If successful, you should see:
# Welcome to Ubuntu 22.04.x LTS
```

### 2. GitHub Actions Test
After setting up secrets:

1. Make any change to your backend code
2. Commit and push to the `main` branch
3. Go to **Actions** tab in GitHub
4. Watch the deployment workflow run

---

## 🚨 Security Best Practices

### ✅ DO:
- Use unique SSH keys for each environment
- Regularly rotate SSH keys
- Monitor GitHub Actions logs for security issues
- Keep your EC2 security groups restrictive

### ❌ DON'T:
- Never share your SSH private keys
- Never commit SSH keys to version control
- Never use the same SSH key for multiple servers
- Never leave SSH keys in plain text files

---

## 🔧 EC2 Security Group Configuration

Make sure your EC2 security group allows:

```
Inbound Rules:
- SSH (22) from your IP address only
- HTTP (80) from anywhere (0.0.0.0/0)
- HTTPS (443) from anywhere (0.0.0.0/0)
- Custom TCP (1337) from anywhere (for Strapi API)

Outbound Rules:
- All traffic to anywhere (for updates and external services)
```

---

## 📊 Monitoring Deployment

### GitHub Actions Logs
- View real-time deployment progress
- Check for errors and warnings
- Monitor performance metrics

### EC2 Instance Monitoring
```bash
# Check application status
pm2 status

# View application logs
pm2 logs stoic-backend

# Monitor system resources
htop

# Check nginx status
sudo systemctl status nginx
```

---

## 🆘 Troubleshooting

### Common Issues:

#### 1. SSH Connection Failed
```
Error: Permission denied (publickey)
```
**Solution**: 
- Verify EC2_SSH_KEY contains the complete private key
- Check EC2_HOST is correct
- Ensure security group allows SSH from GitHub Actions IPs

#### 2. Deployment Timeout
```
Error: Timeout waiting for deployment
```
**Solution**:
- Check EC2 instance has enough resources
- Verify Strapi is starting correctly
- Check application logs with `pm2 logs`

#### 3. Environment Variables Missing
```
Error: Missing required environment variable
```
**Solution**:
- Ensure `.env.production` file exists on EC2
- Verify all required variables are set
- Check file permissions and ownership

---

## 🎯 Verification Checklist

After setup, verify:

- [ ] SSH connection works manually
- [ ] GitHub Secrets are configured correctly
- [ ] EC2 security group allows necessary ports
- [ ] `.env.production` file exists on EC2
- [ ] PM2 and Nginx are installed on EC2
- [ ] GitHub Actions workflow triggers on push to main
- [ ] Deployment completes successfully
- [ ] Application is accessible via browser
- [ ] Health check endpoint responds correctly

---

## 📞 Support

If you encounter issues:

1. Check GitHub Actions logs for detailed error messages
2. SSH into your EC2 instance and check application logs
3. Verify all secrets are configured correctly
4. Ensure EC2 instance meets system requirements

Remember: The first deployment might take longer as it sets up the environment. Subsequent deployments will be faster!



