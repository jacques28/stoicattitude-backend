# 🔧 FIXING AWS RDS POSTGRESQL CONNECTION

## 🚨 Current Issue
- **Error**: Connection timeout to RDS instance
- **Cause**: RDS Security Group blocking local connections
- **Solution**: Update security group to allow your IP

---

## 🛠️ IMMEDIATE FIXES REQUIRED

### **1. AWS RDS Security Group Configuration**

#### Go to AWS Console:
1. **Navigate**: AWS Console → RDS → Databases
2. **Select**: Click on `database-1`
3. **Security**: Click on "Connectivity & security" tab
4. **Security Group**: Click on the security group link

#### Update Inbound Rules:
```
Type: PostgreSQL
Protocol: TCP
Port: 5432
Source: My IP (will auto-detect your current IP)
Description: Local development access
```

### **2. Test Connection Manually**
```bash
# Test if RDS is reachable
telnet database-1.cepui2meiura.us-east-1.rds.amazonaws.com 5432

# If telnet works, test PostgreSQL connection
psql -h database-1.cepui2meiura.us-east-1.rds.amazonaws.com \
     -p 5432 \
     -U postgres \
     -d stoicattitude_db \
     -c "SELECT version();"
```

### **3. Alternative Username Test**
Your RDS might use a different master username:
```bash
# Try these usernames in order:
DATABASE_USERNAME=postgres
DATABASE_USERNAME=dbadmin
DATABASE_USERNAME=root
DATABASE_USERNAME=stoicattitude
```

---

## 🔧 QUICK VERIFICATION STEPS

### Step 1: Get Your Current IP
```bash
curl ifconfig.me
# Note this IP address
```

### Step 2: Update RDS Security Group
- Add your IP to PostgreSQL (port 5432) inbound rules
- Save the security group changes

### Step 3: Test Connection
```bash
# Should work after security group update
psql -h database-1.cepui2meiura.us-east-1.rds.amazonaws.com \
     -p 5432 \
     -U postgres \
     -d stoicattitude_db
```

---

## ⚠️ IMPORTANT NOTES

1. **Security**: Only add your specific IP, not 0.0.0.0/0
2. **Dynamic IP**: If your IP changes, update the security group
3. **VPN**: If using VPN, add VPN exit IP instead
4. **Production**: EC2 will be in same VPC, no security group changes needed

---

## ✅ AFTER FIX VERIFICATION

Once security group is updated:
```bash
# 1. Test direct connection
psql -h database-1.cepui2meiura.us-east-1.rds.amazonaws.com -p 5432 -U postgres -d stoicattitude_db

# 2. Start Strapi
npm run develop

# 3. Should see successful connection
# ✔ Building build context
# ✔ Creating admin
# ✔ Loading Strapi
# ⭐ Server started on http://localhost:1337
```



