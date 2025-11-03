# StreamSync Lite - AWS Deployment Guide

## Prerequisites
- AWS Account (Free Tier eligible)
- AWS CLI installed and configured
- Git installed locally

## Architecture
- **Backend**: EC2 t2.micro with PM2 + NGINX reverse proxy (Free Tier)
- **Database**: RDS PostgreSQL db.t3.micro (Free Tier)
- **Frontend**: Android APK (uses YouTube embed and Firebase for push)
- **Monitoring**: CloudWatch for logs, /health endpoint for uptime checks
- **Secrets**: AWS Systems Manager Parameter Store (no secrets in repo)

## Step 1: Create RDS PostgreSQL Database

### Using AWS Console:
1. Go to AWS RDS Console
2. Click **Create Database**
3. Choose:
   - **Engine**: PostgreSQL 15
   - **Templates**: Free tier
   - **DB instance identifier**: streamsync-db
   - **Master username**: postgres
   - **Master password**: [Your secure password]
   - **DB instance class**: db.t3.micro (Free Tier)
   - **Storage**: 20 GB (Free Tier limit)
   - **VPC**: Default VPC
   - **Public access**: Yes (for testing)
   - **VPC security group**: Create new (streamsync-db-sg)
4. Click **Create database**
5. Wait ~5 minutes for database to be available
6. Note down the **Endpoint** (e.g., `streamsync-db.xxxxxxx.us-east-1.rds.amazonaws.com`)

### Using AWS CLI:
```bash
aws rds create-db-instance \
    --db-instance-identifier streamsync-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.3 \
    --master-username postgres \
    --master-password YourSecurePassword123! \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-xxxxxxxx \
    --publicly-accessible
```

## Step 2: Configure Security Groups

### RDS Security Group (streamsync-db-sg):
**Inbound Rules:**
- Type: PostgreSQL
- Protocol: TCP
- Port: 5432
- Source: EC2 Security Group ID (create in Step 3)

### EC2 Security Group (streamsync-api-sg):
**Inbound Rules:**
- Type: HTTP, Port: 80, Source: 0.0.0.0/0
- Type: HTTPS, Port: 443, Source: 0.0.0.0/0
- Type: Custom TCP, Port: 3000, Source: 0.0.0.0/0
- Type: SSH, Port: 22, Source: Your IP (for management)

**Outbound Rules:**
- All traffic (default)

## Step 3: Launch EC2 Instance

### Using AWS Console:
1. Go to EC2 Console
2. Click **Launch Instance**
3. Configure:
   - **Name**: streamsync-api
   - **AMI**: Amazon Linux 2023
   - **Instance type**: t2.micro (Free Tier)
   - **Key pair**: Create new or select existing
   - **Network settings**: 
     - VPC: Default
     - Auto-assign public IP: Enable
     - Security group: streamsync-api-sg (created above)
   - **Storage**: 8 GB gp3 (Free Tier)
4. Click **Launch instance**
5. Note down the **Public IP address**

### Using AWS CLI:
```bash
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t2.micro \
    --key-name your-key-pair \
    --security-group-ids sg-xxxxxxxx \
    --subnet-id subnet-xxxxxxxx \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=streamsync-api}]'
```

## Step 4: Connect to EC2 and Install Dependencies

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Update system
sudo yum update -y

# Install Node.js 18 LTS (from NodeSource)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version  # Should show v18.x.x
npm --version

# Install PM2 globally (process manager)
sudo npm install -g pm2

# Install NGINX (reverse proxy)
sudo yum install -y nginx

# Install Git
sudo yum install -y git

# Install AWS CLI (for Parameter Store)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install -y unzip
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure PM2 to start on boot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
# Copy and run the command PM2 outputs
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user
```

## Step 5: Store Secrets in AWS Systems Manager Parameter Store

```bash
# Create parameters (do this from your local machine with AWS CLI configured)
aws ssm put-parameter \
  --name "/streamsync/production/DATABASE_PASSWORD" \
  --value "YourSecurePassword123!" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/JWT_SECRET" \
  --value "your-super-secret-jwt-key-change-this" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/JWT_REFRESH_SECRET" \
  --value "your-refresh-secret-change-this" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/FIREBASE_PRIVATE_KEY" \
  --value "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/YOUTUBE_API_KEY" \
  --value "AIzaSyAo9PdNWl5fPr57VhRVZWJu8rmTAh8Noo4" \
  --type "SecureString" \
  --region us-east-1
```

**Note**: Attach IAM role to EC2 instance with `AmazonSSMReadOnlyAccess` policy to read these parameters.

## Step 6: Deploy Application

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Clone your repository
cd ~
git clone https://github.com/Bhima-Chetan/streamsync-lite.git
cd streamsync-lite/backend

# Install dependencies
npm ci --only=production

# Build the application
npm run build

# Create environment configuration script (fetches from Parameter Store)
cat > load-env.sh << 'EOF'
#!/bin/bash
export NODE_ENV=production
export PORT=3000

# Non-secret configuration
export DATABASE_HOST=your-rds-endpoint.rds.amazonaws.com
export DATABASE_PORT=5432
export DATABASE_USER=postgres
export DATABASE_NAME=streamsync
export JWT_EXPIRES_IN=24h
export JWT_REFRESH_EXPIRES_IN=7d
export FIREBASE_PROJECT_ID=streamsync-dccc1
export FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@streamsync-dccc1.iam.gserviceaccount.com
export RATE_LIMIT_TTL=60
export RATE_LIMIT_MAX=100

# Fetch secrets from Parameter Store
export DATABASE_PASSWORD=$(aws ssm get-parameter --name "/streamsync/production/DATABASE_PASSWORD" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export JWT_SECRET=$(aws ssm get-parameter --name "/streamsync/production/JWT_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export JWT_REFRESH_SECRET=$(aws ssm get-parameter --name "/streamsync/production/JWT_REFRESH_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export FIREBASE_PRIVATE_KEY=$(aws ssm get-parameter --name "/streamsync/production/FIREBASE_PRIVATE_KEY" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export YOUTUBE_API_KEY=$(aws ssm get-parameter --name "/streamsync/production/YOUTUBE_API_KEY" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
EOF

chmod +x load-env.sh

# Start application with PM2
source ./load-env.sh
pm2 start dist/main.js --name streamsync-api

# Save PM2 configuration
pm2 save

# Check status
pm2 status
pm2 logs streamsync-api --lines 50
```

## Step 7: Configure NGINX Reverse Proxy

```bash
# Configure NGINX
sudo tee /etc/nginx/conf.d/streamsync.conf > /dev/null << 'EOF'
# Upstream Node.js backend
upstream nodejs_backend {
    server localhost:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name _;  # Replace with your domain or EC2 public IP

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Access logs
    access_log /var/log/nginx/streamsync-access.log;
    error_log /var/log/nginx/streamsync-error.log;

    # Health check endpoint (for monitoring)
    location /health {
        proxy_pass http://nodejs_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        access_log off;
    }

    # API endpoints
    location / {
        proxy_pass http://nodejs_backend;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering off;
        proxy_cache_bypass $http_upgrade;
    }

    # Rate limiting (optional)
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;
}
EOF

# Test NGINX configuration
sudo nginx -t

# Start and enable NGINX
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# View NGINX logs
sudo tail -f /var/log/nginx/streamsync-error.log
```

## Step 8: Configure CloudWatch Logging

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch config
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json > /dev/null << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ec2-user/.pm2/logs/streamsync-api-out.log",
            "log_group_name": "/aws/ec2/streamsync/application",
            "log_stream_name": "{instance_id}/stdout",
            "timezone": "UTC"
          },
          {
            "file_path": "/home/ec2-user/.pm2/logs/streamsync-api-error.log",
            "log_group_name": "/aws/ec2/streamsync/application",
            "log_stream_name": "{instance_id}/stderr",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/streamsync-access.log",
            "log_group_name": "/aws/ec2/streamsync/nginx",
            "log_stream_name": "{instance_id}/access",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/streamsync-error.log",
            "log_group_name": "/aws/ec2/streamsync/nginx",
            "log_stream_name": "{instance_id}/error",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Enable on boot
sudo systemctl enable amazon-cloudwatch-agent
```

**Note**: Attach IAM role to EC2 with `CloudWatchAgentServerPolicy` for log shipping.

## Step 9: Update Frontend to Use AWS Backend

In your Flutter app, update the API base URL:

```dart
// frontend/lib/data/remote/api_client.dart
// Change line 15 from localhost to your EC2 public IP or domain
static const String baseUrl = 'http://YOUR-EC2-PUBLIC-IP';
```

Build and test the APK with the new backend URL.

## Step 10: Set Up CloudWatch Alarms (Uptime Monitoring)

```bash
# Create CloudWatch alarm for health check (from local machine)
aws cloudwatch put-metric-alarm \
  --alarm-name streamsync-health-check \
  --alarm-description "Alert if /health endpoint fails" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --region us-east-1

# Or use a simple cron job for health checks
# On EC2 instance:
crontab -e

# Add this line (checks every 5 minutes)
*/5 * * * * curl -f http://localhost:3000/health || pm2 restart streamsync-api
```

## Monitoring and Maintenance

### Check Application Status:
```bash
# PM2 status
pm2 status
pm2 logs streamsync-api --lines 100

# NGINX status
sudo systemctl status nginx
sudo tail -f /var/log/nginx/streamsync-access.log

# Health endpoint
curl http://localhost:3000/health
```

### View CloudWatch Logs:
1. Go to AWS CloudWatch Console
2. Navigate to "Log groups"
3. Select `/aws/ec2/streamsync/application` or `/aws/ec2/streamsync/nginx`
4. View real-time logs

### Update Application:
```bash
cd ~/streamsync-lite/backend
git pull origin main
npm ci --only=production
npm run build

# Reload environment and restart
source ./load-env.sh
pm2 restart streamsync-api

# Or zero-downtime reload
pm2 reload streamsync-api

# Check logs
pm2 logs streamsync-api --lines 50
```

### Database Backup (RDS):
- Automatic backups enabled by default (7-day retention)
- Manual snapshots available in RDS console

### PM2 Management Commands:
```bash
pm2 list                    # List all processes
pm2 restart streamsync-api  # Restart app
pm2 reload streamsync-api   # Zero-downtime reload
pm2 stop streamsync-api     # Stop app
pm2 delete streamsync-api   # Remove from PM2
pm2 logs streamsync-api     # View logs
pm2 monit                   # Monitor CPU/Memory
```

## Cost Optimization (Free Tier)

✅ **Free Tier Eligible** (12 months):
- EC2 t2.micro: 750 hours/month
- RDS db.t3.micro: 750 hours/month
- 20 GB RDS storage
- 30 GB EBS storage

⚠️ **Monitor Usage**:
- CloudWatch: Set billing alarms
- AWS Cost Explorer: Track spending

## Troubleshooting

### Cannot connect to database:
- Check security group allows EC2 → RDS on port 5432
- Verify RDS endpoint in load-env.sh
- Test connection: `psql -h your-rds-endpoint -U postgres -d streamsync`

### Application not starting:
```bash
pm2 logs streamsync-api --lines 100
pm2 describe streamsync-api
```

### NGINX errors:
```bash
sudo nginx -t  # Test configuration
sudo tail -f /var/log/nginx/streamsync-error.log
```

### Secrets not loading from Parameter Store:
- Check EC2 IAM role has `AmazonSSMReadOnlyAccess`
- Verify parameter names match in load-env.sh
- Test manually: `aws ssm get-parameter --name "/streamsync/production/DATABASE_PASSWORD" --with-decryption --region us-east-1`

### High memory usage:
```bash
pm2 monit  # Monitor resources
pm2 restart streamsync-api  # Restart if needed
```

### Update EC2 public IP in frontend:
- Use **Elastic IP** for permanent IP address (free if attached to running instance)
- Or use Route 53 with domain name

---

## IAM Roles and Policies Required

### EC2 Instance Role:
Attach these policies to the EC2 instance role:

1. **AmazonSSMReadOnlyAccess** (for Parameter Store)
2. **CloudWatchAgentServerPolicy** (for CloudWatch logs)

Create IAM role:
```bash
# Create trust policy
cat > ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name StreamSyncEC2Role \
  --assume-role-policy-document file://ec2-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name StreamSyncEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess

aws iam attach-role-policy \
  --role-name StreamSyncEC2Role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name StreamSyncEC2Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name StreamSyncEC2Profile \
  --role-name StreamSyncEC2Role

# Attach to EC2 instance (replace i-xxxxxx with your instance ID)
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxxx \
  --iam-instance-profile Name=StreamSyncEC2Profile
```
