#!/bin/bash

# AWS Free Tier Deployment Script for Strapi Backend
# This script helps deploy your Strapi app using only FREE AWS services

set -e

echo "🚀 AWS Free Tier Deployment Script for Strapi"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first:${NC}"
    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if user is logged in
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ Not logged into AWS. Please run: aws configure${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI configured${NC}"

# Variables
REGION="us-east-1"
KEY_NAME="strapi-key"
SECURITY_GROUP="strapi-sg"
INSTANCE_NAME="strapi-backend"

echo ""
echo -e "${BLUE}📋 This script will create:${NC}"
echo "• EC2 t2.micro instance (FREE TIER)"
echo "• Security group for web traffic"
echo "• SSH key pair for access"
echo "• All within AWS Free Tier limits"
echo ""

read -p "🤔 Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}🔑 Step 1: Creating SSH Key Pair...${NC}"

# Create key pair if it doesn't exist
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${GREEN}✅ Key pair '$KEY_NAME' already exists${NC}"
else
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --region "$REGION" \
        --query 'KeyMaterial' \
        --output text > "${KEY_NAME}.pem"
    
    chmod 400 "${KEY_NAME}.pem"
    echo -e "${GREEN}✅ Key pair created: ${KEY_NAME}.pem${NC}"
fi

echo ""
echo -e "${YELLOW}🔒 Step 2: Creating Security Group...${NC}"

# Get default VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region "$REGION" --query 'Vpcs[0].VpcId' --output text)

# Create security group if it doesn't exist
if aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" --region "$REGION" &> /dev/null; then
    echo -e "${GREEN}✅ Security group '$SECURITY_GROUP' already exists${NC}"
    SG_ID=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
else
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP" \
        --description "Security group for Strapi backend" \
        --vpc-id "$VPC_ID" \
        --region "$REGION" \
        --query 'GroupId' \
        --output text)

    # Add rules
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region "$REGION"

    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region "$REGION"

    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region "$REGION"

    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 1337 \
        --cidr 0.0.0.0/0 \
        --region "$REGION"

    echo -e "${GREEN}✅ Security group created with web access rules${NC}"
fi

echo ""
echo -e "${YELLOW}🖥️  Step 3: Launching EC2 Instance (t2.micro - FREE TIER)...${NC}"

# User data script for automated setup
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker git

# Start Docker
service docker start
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js 18
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18

echo "🎉 Server setup completed!" > /home/ec2-user/setup-complete.txt
EOF
)

# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --region "$REGION" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

echo "Using AMI: $AMI_ID"

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type t2.micro \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --user-data "$USER_DATA" \
    --region "$REGION" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}✅ Instance launched: $INSTANCE_ID${NC}"

echo ""
echo -e "${YELLOW}⏳ Step 4: Waiting for instance to be ready...${NC}"

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}✅ Instance is running!${NC}"
echo ""
echo -e "${BLUE}📋 DEPLOYMENT COMPLETE!${NC}"
echo "========================"
echo ""
echo -e "${GREEN}🎯 Your Strapi server details:${NC}"
echo "• Instance ID: $INSTANCE_ID"
echo "• Public IP: $PUBLIC_IP"
echo "• SSH Key: ${KEY_NAME}.pem"
echo ""
echo -e "${YELLOW}🔗 Next Steps:${NC}"
echo "1. Wait 2-3 minutes for automatic setup to complete"
echo "2. Connect to your server:"
echo "   ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo ""
echo "3. Clone and deploy your Strapi app:"
echo "   git clone https://github.com/your-username/stoicattitude-backend.git"
echo "   cd stoicattitude-backend"
echo "   cp example.env .env"
echo "   # Edit .env with your settings"
echo "   npm install"
echo "   npm run build"
echo "   npm start"
echo ""
echo "4. Access your app:"
echo "   http://$PUBLIC_IP:1337"
echo "   http://$PUBLIC_IP:1337/admin"
echo ""
echo -e "${GREEN}💰 FREE TIER USAGE:${NC}"
echo "• This uses t2.micro (750 hours/month FREE)"
echo "• Monitor usage in AWS Console → Billing → Free Tier"
echo "• Set up billing alerts to avoid charges"
echo ""
echo -e "${BLUE}🔧 For production setup with domain/SSL, see README.md${NC}" 