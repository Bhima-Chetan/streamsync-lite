# StreamSync Lite - Quick Deployment Guide

## 🚀 Quick Start (5 Steps)

### Step 1: Create AWS Resources (15 minutes)

#### A. Create RDS PostgreSQL Database
```bash
aws rds create-db-instance \
    --db-instance-identifier streamsync-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.3 \
    --master-username postgres \
    --master-password YourSecurePassword123! \
    --allocated-storage 20 \
    --publicly-accessible \
    --region us-east-1
```

Wait ~5 minutes, then get endpoint:
```bash
aws rds describe-db-instances \
    --db-instance-identifier streamsync-db \
    --query "DBInstances[0].Endpoint.Address" \
    --output text
```

#### B. Create EC2 Instance
```bash
# Create security group
aws ec2 create-security-group \
    --group-name streamsync-api-sg \
    --description "StreamSync API Security Group"

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups --group-names streamsync-api-sg --query "SecurityGroups[0].GroupId" --output text)

# Add inbound rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Launch EC2 instance (use your key pair name)
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t2.micro \
    --key-name your-key-pair \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=streamsync-api}]'
```

Get instance IP:
```bash
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=streamsync-api" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text
```

### Step 2: Configure IAM Role for EC2

```powershell
# Run from your local machine (PowerShell)
# Create IAM role
aws iam create-role --role-name StreamSyncEC2Role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Attach policies
aws iam attach-role-policy --role-name StreamSyncEC2Role --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
aws iam attach-role-policy --role-name StreamSyncEC2Role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Create instance profile
aws iam create-instance-profile --instance-profile-name StreamSyncEC2Profile
aws iam add-role-to-instance-profile --instance-profile-name StreamSyncEC2Profile --role-name StreamSyncEC2Role

# Attach to EC2 (get instance ID from Step 1)
$INSTANCE_ID = "i-xxxxxxxxx"  # Replace with your instance ID
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID --iam-instance-profile Name=StreamSyncEC2Profile
```

### Step 3: Store Secrets in Parameter Store

```powershell
# Run this interactive script
.\setup-secrets.ps1 -Region "us-east-1"
```

This will prompt you for:
- RDS database password
- JWT secret (random string)
- JWT refresh secret (random string)
- Firebase private key (auto-detected from backend\.env)
- YouTube API key (default provided)

### Step 4: Install Dependencies on EC2

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@YOUR-EC2-IP

# Run installation script
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs nginx git unzip
sudo npm install -g pm2

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure PM2 startup
pm2 startup systemd -u ec2-user --hp /home/ec2-user
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

# Configure NGINX
sudo tee /etc/nginx/conf.d/streamsync.conf > /dev/null << 'EOF'
upstream nodejs_backend {
    server localhost:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://nodejs_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

sudo systemctl start nginx
sudo systemctl enable nginx

# Update RDS security group to allow EC2 access
# Get EC2 security group ID
EC2_SG=$(aws ec2 describe-instances --instance-ids $(ec2-metadata --instance-id | cut -d " " -f 2) --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)

# Add inbound rule to RDS security group (run from local machine)
exit  # Exit SSH first
```

From your local machine:
```bash
# Get RDS security group
RDS_SG=$(aws rds describe-db-instances --db-instance-identifier streamsync-db --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" --output text)

# Add rule allowing EC2 to access RDS
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG \
    --protocol tcp \
    --port 5432 \
    --source-group $EC2_SG
```

### Step 5: Deploy Application

```powershell
# From your local machine (Windows PowerShell)
.\deploy.ps1 -EC2IP "YOUR-EC2-IP" -KeyFile "path\to\your-key.pem" -RDSEndpoint "your-rds-endpoint.rds.amazonaws.com"
```

This script will:
1. Clone the repository on EC2
2. Install dependencies
3. Build the application
4. Create environment loader (fetches secrets from Parameter Store)
5. Start with PM2
6. Configure auto-restart

---

## 📱 Update Flutter App

After successful deployment, update the API base URL:

```dart
// frontend/lib/data/remote/api_client.dart
// Line ~15
static const String baseUrl = 'http://YOUR-EC2-IP';
```

Build APK:
```bash
cd frontend
flutter build apk --release
```

Test the app with your deployed backend!

---

## ✅ Verification Checklist

- [ ] RDS database created and accessible
- [ ] EC2 instance running
- [ ] IAM role attached to EC2 with SSM and CloudWatch permissions
- [ ] Secrets stored in Parameter Store
- [ ] Node.js, PM2, NGINX installed on EC2
- [ ] Application deployed with PM2
- [ ] NGINX reverse proxy configured
- [ ] Health endpoint working: `curl http://YOUR-EC2-IP/health`
- [ ] Flutter app updated with new API URL
- [ ] Push notifications working (logout/login to register FCM token)

---

## 🔧 Useful Commands

### On EC2 (via SSH):
```bash
# Check PM2 status
pm2 status
pm2 logs streamsync-api
pm2 monit

# Restart app
pm2 restart streamsync-api

# Check NGINX
sudo systemctl status nginx
sudo tail -f /var/log/nginx/streamsync-error.log

# Test health endpoint
curl http://localhost:3000/health

# View secrets (should work if IAM role attached)
aws ssm get-parameter --name "/streamsync/production/DATABASE_PASSWORD" --with-decryption --region us-east-1
```

### From Local Machine:
```powershell
# View CloudWatch logs
aws logs tail /aws/ec2/streamsync/application --follow --region us-east-1

# Check RDS status
aws rds describe-db-instances --db-instance-identifier streamsync-db

# SSH into EC2
ssh -i your-key.pem ec2-user@YOUR-EC2-IP
```

---

## 💰 Cost Estimate (AWS Free Tier)

**Free for 12 months:**
- EC2 t2.micro: 750 hours/month (1 instance = FREE)
- RDS db.t3.micro: 750 hours/month (FREE)
- 20 GB RDS storage (FREE)
- 30 GB EBS storage (FREE)
- Data transfer: 15 GB/month out (FREE)
- CloudWatch: Basic monitoring (FREE)

**After 12 months:**
- ~$8-10/month for EC2 t2.micro
- ~$15-18/month for RDS db.t3.micro
- **Total: ~$23-28/month**

**To minimize costs:**
- Use Elastic IP (free when attached to running instance)
- Stop instances when not needed (hackathon demo only)
- Enable RDS automated backups (included)

---

## 🚨 Troubleshooting

### Application not starting:
```bash
pm2 logs streamsync-api --lines 100
# Check if secrets are loading from Parameter Store
```

### Can't connect to RDS:
```bash
# Test connection
psql -h your-rds-endpoint -U postgres -d streamsync
# If fails, check security group rules
```

### NGINX errors:
```bash
sudo nginx -t  # Test config
sudo systemctl restart nginx
```

### Secrets not loading:
```bash
# Check IAM role attached
aws sts get-caller-identity

# Test parameter access
aws ssm get-parameter --name "/streamsync/production/DATABASE_PASSWORD" --with-decryption
```

### Push notifications not working:
- Logout and login again in the app (to re-register FCM token with new backend)
- Check backend logs: `pm2 logs streamsync-api | grep "🔔"`
- Verify Firebase project ID matches in backend and android app

---

## 📖 Full Documentation

For detailed step-by-step instructions, see [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)
