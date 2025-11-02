# 🚀 AWS Free Tier Deployment Guide - StreamSync

## 📋 Overview

This guide walks you through deploying StreamSync on **AWS Free Tier** with zero cost for the first year.

### Architecture
- **Compute**: EC2 t2.micro (750 hours/month free)
- **Database**: RDS PostgreSQL db.t3.micro (750 hours/month free)
- **Monitoring**: CloudWatch (free tier limits)
- **Process Manager**: PM2
- **Reverse Proxy**: NGINX
- **Push Notifications**: Firebase (free)
- **Video Streaming**: YouTube Embed (free)

---

## 🎯 Prerequisites

### AWS Account Setup
1. Create AWS account: https://aws.amazon.com/free/
2. Enable MFA on root account
3. Create IAM user with appropriate permissions
4. Install AWS CLI: `aws configure`

### Required Credentials
- AWS Access Key ID
- AWS Secret Access Key
- SSH Key Pair (for EC2 access)

---

## 📦 Phase 1: Database Setup (RDS PostgreSQL)

### Step 1: Create RDS Instance

```bash
# Via AWS Console:
1. Go to RDS → Create database
2. Choose: PostgreSQL
3. Template: Free tier
4. DB Instance: db.t3.micro
5. Storage: 20 GB (max free tier)
6. DB name: streamsync
7. Master username: postgres
8. Master password: <strong-password>
9. Public access: Yes (for initial setup)
10. Security group: Create new (allow port 5432 from your IP)
```

### Step 2: Configure Security Group

```bash
# RDS Security Group Inbound Rules:
Type: PostgreSQL
Protocol: TCP
Port: 5432
Source: <EC2-Security-Group-ID>  # Will create this next
Description: Allow EC2 to access RDS
```

### Step 3: Test Connection

```bash
# From local machine (replace with your RDS endpoint)
psql -h streamsync.xxxxxx.us-east-1.rds.amazonaws.com -U postgres -d streamsync

# Create tables (run migrations)
npm run typeorm:migration:run
```

---

## 💻 Phase 2: EC2 Setup

### Step 1: Launch EC2 Instance

```bash
# Via AWS Console:
1. Go to EC2 → Launch Instance
2. Name: streamsync-backend
3. AMI: Amazon Linux 2023 (free tier eligible)
4. Instance type: t2.micro
5. Key pair: Create new or use existing
6. Network: Default VPC
7. Auto-assign public IP: Enable
8. Storage: 8 GB gp2 (free tier)
9. Launch instance
```

### Step 2: Configure Security Group

```bash
# EC2 Security Group Inbound Rules:
Type: SSH
Port: 22
Source: Your IP
Description: SSH access

Type: HTTP
Port: 80
Source: 0.0.0.0/0
Description: HTTP traffic

Type: HTTPS
Port: 443
Source: 0.0.0.0/0
Description: HTTPS traffic (future SSL)

Type: Custom TCP
Port: 3000
Source: 0.0.0.0/0
Description: Backend API (temporary - will use NGINX)
```

### Step 3: Connect to EC2

```bash
# Download your .pem key file
chmod 400 streamsync-key.pem

# Connect via SSH
ssh -i streamsync-key.pem ec2-user@<EC2-PUBLIC-IP>
```

---

## 🛠️ Phase 3: Server Configuration

### Step 1: Install Node.js and Dependencies

```bash
# Update system
sudo yum update -y

# Install Node.js 20.x (LTS)
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version  # Should be v20.x
npm --version

# Install PM2 globally
sudo npm install -g pm2

# Install NGINX
sudo yum install -y nginx

# Install Git
sudo yum install -y git
```

### Step 2: Clone Repository

```bash
# Create app directory
sudo mkdir -p /var/www
sudo chown ec2-user:ec2-user /var/www
cd /var/www

# Clone your repository
git clone https://github.com/yourusername/streamsync.git
cd streamsync/backend

# Install dependencies
npm install --production
```

### Step 3: Configure Environment Variables

```bash
# Create production .env file
cat > /var/www/streamsync/backend/.env << 'EOF'
# Database
DATABASE_URL=postgresql://postgres:<password>@<rds-endpoint>:5432/streamsync
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<your-rds-password>
DB_DATABASE=streamsync

# JWT
JWT_SECRET=<generate-strong-random-secret>
JWT_EXPIRES_IN=7d
REFRESH_TOKEN_EXPIRES_IN=30d

# YouTube API
YOUTUBE_API_KEY=<your-youtube-api-key>
YOUTUBE_CHANNEL_ID=<default-channel-id>
YOUTUBE_CACHE_TTL=600

# Firebase Admin SDK
FIREBASE_PROJECT_ID=<your-firebase-project-id>
FIREBASE_CLIENT_EMAIL=<firebase-service-account-email>
FIREBASE_PRIVATE_KEY=<firebase-private-key>

# Worker
WORKER_POLL_INTERVAL=5000

# Server
NODE_ENV=production
PORT=3000

# CORS
CORS_ORIGIN=*
EOF

# Secure the .env file
chmod 600 /var/www/streamsync/backend/.env
```

### Step 4: Build Backend

```bash
cd /var/www/streamsync/backend
npm run build
```

---

## 🔧 Phase 4: PM2 Process Manager

### Step 1: Create PM2 Ecosystem File

```bash
cat > /var/www/streamsync/backend/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'streamsync-api',
      script: 'dist/main.js',
      instances: 1,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
      },
      error_file: '/var/log/streamsync/api-error.log',
      out_file: '/var/log/streamsync/api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '500M',
    },
    {
      name: 'streamsync-worker',
      script: 'dist/worker.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
      error_file: '/var/log/streamsync/worker-error.log',
      out_file: '/var/log/streamsync/worker-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '300M',
    },
  ],
};
EOF
```

### Step 2: Create Log Directory

```bash
sudo mkdir -p /var/log/streamsync
sudo chown ec2-user:ec2-user /var/log/streamsync
```

### Step 3: Start Applications with PM2

```bash
cd /var/www/streamsync/backend

# Start both API and Worker
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup script (runs on server reboot)
pm2 startup
# Copy and run the command it outputs

# Check status
pm2 status
pm2 logs

# Monitor in real-time
pm2 monit
```

### PM2 Useful Commands

```bash
# View logs
pm2 logs streamsync-api
pm2 logs streamsync-worker

# Restart apps
pm2 restart streamsync-api
pm2 restart streamsync-worker
pm2 restart all

# Stop apps
pm2 stop streamsync-api
pm2 stop all

# Delete apps
pm2 delete streamsync-api
pm2 delete all

# Reload (zero-downtime restart)
pm2 reload streamsync-api
```

---

## 🌐 Phase 5: NGINX Reverse Proxy

### Step 1: Configure NGINX

```bash
# Create NGINX config
sudo tee /etc/nginx/conf.d/streamsync.conf > /dev/null << 'EOF'
upstream backend {
    server 127.0.0.1:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name <your-ec2-public-ip-or-domain>;

    # API endpoints
    location /api/ {
        rewrite ^/api/(.*) /$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint (direct)
    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }

    # Static files (if any)
    location / {
        root /var/www/html;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # Logging
    access_log /var/log/nginx/streamsync-access.log;
    error_log /var/log/nginx/streamsync-error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 256;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF
```

### Step 2: Test and Start NGINX

```bash
# Test configuration
sudo nginx -t

# Start NGINX
sudo systemctl start nginx

# Enable on boot
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# Restart NGINX
sudo systemctl restart nginx
```

---

## 📊 Phase 6: CloudWatch Monitoring

### Step 1: Install CloudWatch Agent

```bash
# Download CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

# Install
sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

### Step 2: Configure CloudWatch Agent

```bash
# Create configuration file
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json > /dev/null << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/streamsync/api-error.log",
            "log_group_name": "/aws/ec2/streamsync/api-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/streamsync/api-out.log",
            "log_group_name": "/aws/ec2/streamsync/api-out",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/streamsync/worker-error.log",
            "log_group_name": "/aws/ec2/streamsync/worker-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/streamsync-error.log",
            "log_group_name": "/aws/ec2/streamsync/nginx-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "StreamSync",
    "metrics_collected": {
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
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
```

### Step 3: Create CloudWatch Alarms (via AWS Console)

```yaml
Alarms to Create:
1. High CPU Usage
   - Metric: CPUUtilization
   - Threshold: > 80% for 5 minutes
   - Action: Send SNS notification

2. High Memory Usage
   - Metric: MemoryUtilization
   - Threshold: > 85% for 5 minutes
   - Action: Send SNS notification

3. API Health Check Failed
   - Metric: Custom health check
   - Threshold: Failed for 2 consecutive checks
   - Action: Send SNS notification

4. RDS Storage Low
   - Metric: FreeStorageSpace
   - Threshold: < 2GB
   - Action: Send SNS notification
```

---

## 🔒 Phase 7: Security & Secrets Management

### Option 1: Environment Variables (Current)

```bash
# Already configured in .env file
# Ensure file permissions are restrictive
chmod 600 /var/www/streamsync/backend/.env
```

### Option 2: AWS Systems Manager Parameter Store (Recommended)

```bash
# Store secrets in Parameter Store
aws ssm put-parameter \
  --name "/streamsync/production/db-password" \
  --value "<your-db-password>" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/jwt-secret" \
  --value "<your-jwt-secret>" \
  --type "SecureString" \
  --region us-east-1

aws ssm put-parameter \
  --name "/streamsync/production/youtube-api-key" \
  --value "<your-youtube-key>" \
  --type "SecureString" \
  --region us-east-1

# Retrieve in application code:
# Install AWS SDK: npm install aws-sdk
# Use in NestJS: import { SSM } from 'aws-sdk';
```

### Step 1: Update IAM Role for EC2

```yaml
# Attach IAM role to EC2 with these permissions:
PolicyName: StreamSyncParameterStoreAccess
Permissions:
  - ssm:GetParameter
  - ssm:GetParameters
  - ssm:GetParametersByPath
  - kms:Decrypt (for SecureString)
Resources:
  - arn:aws:ssm:us-east-1:*:parameter/streamsync/production/*
```

---

## 🚀 Phase 8: Deployment Script

### Create Deployment Script

```bash
cat > /home/ec2-user/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Pull latest code
cd /var/www/streamsync
git pull origin main

# Install dependencies
cd backend
npm install --production

# Build
npm run build

# Run migrations
npm run typeorm:migration:run

# Reload PM2 (zero-downtime)
pm2 reload ecosystem.config.js

echo "✅ Deployment complete!"
echo "📊 Checking status..."
pm2 status
EOF

chmod +x /home/ec2-user/deploy.sh
```

### Usage

```bash
# Deploy updates
./deploy.sh
```

---

## 📱 Phase 9: Frontend Configuration

### Update Flutter App Config

```dart
// frontend/lib/core/config/app_config.dart
class AppConfig {
  // Update for production
  static const String apiBaseUrl = 'http://<EC2-PUBLIC-IP>/api';
  // OR with domain: 'https://api.yourdomain.com'
  
  static const String appName = 'StreamSync';
}
```

### Build APK

```bash
cd frontend

# Update version in pubspec.yaml
# version: 1.0.0+1

# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ Phase 10: Testing & Verification

### Step 1: Test Health Endpoint

```bash
# Direct backend
curl http://<EC2-IP>:3000/health

# Through NGINX
curl http://<EC2-IP>/api/health
```

### Step 2: Test API Endpoints

```bash
# Test registration
curl -X POST http://<EC2-IP>/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test","password":"test123"}'

# Test videos endpoint
curl http://<EC2-IP>/api/videos/latest?maxResults=10
```

### Step 3: Test Worker Process

```bash
# Check worker logs
pm2 logs streamsync-worker

# Send test push and verify it's processed
```

### Step 4: Monitor Logs

```bash
# Real-time logs
pm2 logs

# NGINX logs
sudo tail -f /var/log/nginx/streamsync-access.log
sudo tail -f /var/log/nginx/streamsync-error.log

# CloudWatch Logs (via AWS Console)
# Navigate to CloudWatch → Log groups
```

---

## 💰 Cost Estimation (Free Tier)

| Service | Free Tier | Usage | Cost |
|---------|-----------|-------|------|
| EC2 t2.micro | 750 hrs/month | 24/7 | $0 |
| RDS db.t3.micro | 750 hrs/month | 24/7 | $0 |
| RDS Storage | 20 GB | 10 GB | $0 |
| Data Transfer | 15 GB/month | ~5 GB | $0 |
| CloudWatch | 10 metrics, 1M API calls | Normal | $0 |
| **Total** | | | **$0/month** (Year 1) |

### After Free Tier (Year 2+)
- EC2 t2.micro: ~$8.50/month
- RDS db.t3.micro: ~$12/month
- Storage & Transfer: ~$2/month
- **Total**: ~$22-25/month

---

## 🔄 Maintenance & Operations

### Daily Tasks
```bash
# Check application status
pm2 status
pm2 logs --lines 100

# Check system resources
top
df -h
free -h
```

### Weekly Tasks
```bash
# Update system packages
sudo yum update -y

# Check disk space
df -h

# Review CloudWatch metrics
# (via AWS Console)

# Backup database (via RDS automated backups)
```

### Monthly Tasks
```bash
# Review CloudWatch logs for errors
# Analyze API usage patterns
# Check RDS storage usage
# Review security group rules
```

---

## 🆘 Troubleshooting

### Application Won't Start
```bash
# Check PM2 logs
pm2 logs streamsync-api --lines 50

# Check environment variables
cat /var/www/streamsync/backend/.env

# Test database connection
psql -h <rds-endpoint> -U postgres -d streamsync

# Check if port 3000 is listening
sudo netstat -tulpn | grep 3000
```

### NGINX Issues
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Restart NGINX
sudo systemctl restart nginx
```

### Database Connection Issues
```bash
# Check RDS security group
# Ensure EC2 security group is allowed

# Test from EC2
telnet <rds-endpoint> 5432

# Check RDS status (AWS Console)
```

### High Memory Usage
```bash
# Check memory
free -h

# Identify memory hogs
top
pm2 monit

# Restart applications
pm2 restart all
```

---

## 🎯 Production Checklist

- [ ] RDS instance created and accessible
- [ ] EC2 instance launched and configured
- [ ] Security groups properly configured
- [ ] Node.js and dependencies installed
- [ ] Code deployed and built
- [ ] Environment variables configured
- [ ] PM2 processes running (API + Worker)
- [ ] PM2 startup configured
- [ ] NGINX configured and running
- [ ] CloudWatch agent installed and running
- [ ] Health endpoint responding
- [ ] API endpoints tested
- [ ] Worker processing jobs
- [ ] Logs being written to CloudWatch
- [ ] Alarms configured
- [ ] SSL certificate installed (optional)
- [ ] Domain configured (optional)
- [ ] Flutter app updated with production URL
- [ ] APK built and tested

---

## 🔐 Security Best Practices

1. **Never commit secrets** to repository
2. **Use IAM roles** instead of access keys when possible
3. **Restrict security groups** to minimum required access
4. **Enable MFA** on AWS account
5. **Regular updates** of system packages
6. **Monitor logs** for suspicious activity
7. **Use SSL/TLS** for production (Let's Encrypt is free)
8. **Regular backups** of database
9. **Restrict SSH access** to your IP only
10. **Use Parameter Store** for sensitive configuration

---

## 📞 Support Resources

- **AWS Free Tier**: https://aws.amazon.com/free/
- **PM2 Documentation**: https://pm2.keymetrics.io/docs/
- **NGINX Documentation**: https://nginx.org/en/docs/
- **CloudWatch Documentation**: https://docs.aws.amazon.com/cloudwatch/
- **RDS Documentation**: https://docs.aws.amazon.com/rds/

---

**🎉 Congratulations! StreamSync is now deployed on AWS Free Tier!**
