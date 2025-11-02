# 🚀 AWS Free Tier Deployment Checklist

## Pre-Deployment

### AWS Account Setup
- [ ] Create AWS account
- [ ] Enable MFA on root account
- [ ] Create IAM user with admin access
- [ ] Generate access key and secret key
- [ ] Install and configure AWS CLI: `aws configure`
- [ ] Create SSH key pair for EC2 access

### Local Preparation
- [ ] Test application locally (backend + worker + frontend)
- [ ] Ensure all environment variables documented in `.env.example`
- [ ] Commit and push all code to Git repository
- [ ] Tag release version: `git tag v1.0.0`

---

## Database Setup (RDS)

### Create RDS Instance
- [ ] Navigate to RDS → Create database
- [ ] Engine: PostgreSQL (latest version)
- [ ] Template: Free tier
- [ ] DB instance class: db.t3.micro
- [ ] Storage: 20 GB (max free tier)
- [ ] DB instance identifier: `streamsync-db`
- [ ] Master username: `postgres`
- [ ] Master password: (save securely)
- [ ] Public access: Yes (initial setup)
- [ ] VPC security group: Create new
- [ ] Database name: `streamsync`
- [ ] Backup retention: 7 days (free)
- [ ] Create database

### Configure RDS Security Group
- [ ] Note RDS security group ID
- [ ] Add inbound rule:
  - Type: PostgreSQL
  - Port: 5432
  - Source: EC2 security group (create next)

### Test RDS Connection
- [ ] Note RDS endpoint URL
- [ ] Test connection from local:
  ```bash
  psql -h <rds-endpoint> -U postgres -d streamsync
  ```
- [ ] Connection successful

---

## EC2 Setup

### Launch EC2 Instance
- [ ] Navigate to EC2 → Launch Instance
- [ ] Name: `streamsync-backend`
- [ ] AMI: Amazon Linux 2023 (free tier)
- [ ] Instance type: t2.micro
- [ ] Key pair: Create new or select existing
- [ ] Network settings: Default VPC
- [ ] Auto-assign public IP: Enable
- [ ] Security group: Create new
- [ ] Storage: 8 GB gp2
- [ ] Launch instance

### Configure EC2 Security Group
- [ ] Note EC2 security group ID
- [ ] Add inbound rules:
  - SSH (22) from Your IP
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0
  - Custom TCP (3000) from 0.0.0.0/0 (temporary)

### Update RDS Security Group
- [ ] Go back to RDS security group
- [ ] Add inbound rule source: EC2 security group ID

### Connect to EC2
- [ ] Download .pem key file
- [ ] Set permissions: `chmod 400 streamsync-key.pem`
- [ ] Connect: `ssh -i streamsync-key.pem ec2-user@<ec2-ip>`
- [ ] Connection successful

---

## Server Configuration

### Install Node.js
```bash
- [ ] sudo yum update -y
- [ ] curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
- [ ] sudo yum install -y nodejs
- [ ] node --version  # Verify v20.x
```

### Install PM2
```bash
- [ ] sudo npm install -g pm2
- [ ] pm2 --version
```

### Install NGINX
```bash
- [ ] sudo yum install -y nginx
- [ ] nginx -v
```

### Install Git
```bash
- [ ] sudo yum install -y git
- [ ] git --version
```

### Clone Repository
```bash
- [ ] sudo mkdir -p /var/www
- [ ] sudo chown ec2-user:ec2-user /var/www
- [ ] cd /var/www
- [ ] git clone <your-repo-url> streamsync
- [ ] cd streamsync/backend
- [ ] ls -la  # Verify files
```

---

## Application Setup

### Configure Environment Variables
```bash
- [ ] cd /var/www/streamsync/backend
- [ ] cp .env.example .env
- [ ] nano .env
```

Update these variables:
- [ ] `DATABASE_URL` - RDS connection string
- [ ] `DB_HOST` - RDS endpoint
- [ ] `DB_PASSWORD` - RDS password
- [ ] `JWT_SECRET` - Generate: `openssl rand -base64 32`
- [ ] `YOUTUBE_API_KEY` - From Google Cloud Console
- [ ] `YOUTUBE_CHANNEL_ID` - Default channel
- [ ] `FIREBASE_PROJECT_ID` - From Firebase Console
- [ ] `FIREBASE_CLIENT_EMAIL` - Service account email
- [ ] `FIREBASE_PRIVATE_KEY` - Service account key
- [ ] `NODE_ENV=production`

```bash
- [ ] chmod 600 .env  # Secure file permissions
```

### Install Dependencies
```bash
- [ ] cd /var/www/streamsync/backend
- [ ] npm install --production
```

### Build Application
```bash
- [ ] npm run build
- [ ] ls dist/  # Verify build output
```

### Run Migrations
```bash
- [ ] npm run typeorm:migration:run
```

---

## PM2 Configuration

### Create Log Directory
```bash
- [ ] sudo mkdir -p /var/log/streamsync
- [ ] sudo chown ec2-user:ec2-user /var/log/streamsync
```

### Verify Ecosystem Config
```bash
- [ ] cat ecosystem.config.js  # Should exist in repo
```

### Start Applications
```bash
- [ ] pm2 start ecosystem.config.js
- [ ] pm2 status  # Verify both API and Worker running
- [ ] pm2 logs --lines 50  # Check for errors
```

### Configure PM2 Startup
```bash
- [ ] pm2 save
- [ ] pm2 startup  # Copy and run the command it outputs
- [ ] sudo reboot  # Test auto-start
- [ ] # After reboot, reconnect and run:
- [ ] pm2 status  # Should show apps running
```

---

## NGINX Configuration

### Copy Configuration File
```bash
- [ ] sudo cp /var/www/streamsync/backend/nginx.conf /etc/nginx/conf.d/streamsync.conf
```

### Edit Configuration
```bash
- [ ] sudo nano /etc/nginx/conf.d/streamsync.conf
- [ ] # Replace 'your-domain.com' with EC2 IP or domain
```

### Test Configuration
```bash
- [ ] sudo nginx -t  # Should show "syntax is ok"
```

### Start NGINX
```bash
- [ ] sudo systemctl start nginx
- [ ] sudo systemctl enable nginx
- [ ] sudo systemctl status nginx  # Should be active
```

### Test Endpoints
```bash
- [ ] curl http://localhost/health  # Should return 200
- [ ] curl http://<ec2-ip>/health  # From local machine
```

---

## CloudWatch Setup

### Install CloudWatch Agent
```bash
- [ ] wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
- [ ] sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

### Configure CloudWatch (Optional - costs may apply)
```bash
- [ ] # Follow AWS CloudWatch Agent setup wizard
- [ ] # Or use configuration from AWS_DEPLOYMENT_GUIDE.md
```

---

## Security Hardening

### Firewall Rules
```bash
- [ ] # EC2 security group already configured
```

### File Permissions
```bash
- [ ] chmod 600 /var/www/streamsync/backend/.env
- [ ] chmod 700 /var/www/streamsync/backend
```

### Disable Root SSH (Optional)
```bash
- [ ] sudo nano /etc/ssh/sshd_config
- [ ] # Set: PermitRootLogin no
- [ ] sudo systemctl restart sshd
```

---

## Testing

### Health Check
```bash
- [ ] curl http://<ec2-ip>/health
- [ ] # Response: {"status":"ok"}
```

### API Endpoints
```bash
# Test registration
- [ ] curl -X POST http://<ec2-ip>/auth/register \
       -H "Content-Type: application/json" \
       -d '{"email":"test@example.com","name":"Test","password":"test123"}'

# Test videos
- [ ] curl http://<ec2-ip>/videos/latest?maxResults=10
```

### Worker Process
```bash
- [ ] pm2 logs streamsync-worker --lines 20
- [ ] # Should show polling messages every 5 seconds
```

### Database Connection
```bash
- [ ] psql -h <rds-endpoint> -U postgres -d streamsync -c "SELECT COUNT(*) FROM users;"
```

---

## Frontend Configuration

### Update API URL
```dart
- [ ] # Edit: frontend/lib/core/config/app_config.dart
- [ ] # Set apiBaseUrl = 'http://<ec2-ip>'
```

### Build APK
```bash
- [ ] cd frontend
- [ ] flutter build apk --release
- [ ] # APK: build/app/outputs/flutter-apk/app-release.apk
```

### Test on Device
- [ ] Install APK on Android device
- [ ] Test login/registration
- [ ] Test video feed
- [ ] Test test push notification
- [ ] Test all features

---

## Monitoring

### Set Up CloudWatch Alarms (AWS Console)
- [ ] CPU Utilization > 80%
- [ ] Memory Utilization > 85%
- [ ] RDS Storage < 2GB
- [ ] API Health Check Failed

### Test Monitoring
```bash
- [ ] pm2 monit  # Real-time monitoring
- [ ] pm2 logs
- [ ] sudo tail -f /var/log/nginx/streamsync-access.log
```

---

## Backup Strategy

### Database Backups
- [ ] RDS automated backups enabled (7 days retention)
- [ ] Test restore process (optional)

### Code Backups
- [ ] Git repository is source of truth
- [ ] Tag releases: `git tag v1.0.0`

### Configuration Backups
- [ ] Save .env file securely (not in repo)
- [ ] Document all AWS resources

---

## Documentation

### Update README
- [ ] Add deployment instructions
- [ ] Add API documentation
- [ ] Add architecture diagram

### Document Credentials
- [ ] RDS endpoint and credentials (secure location)
- [ ] EC2 IP address
- [ ] SSH key location
- [ ] YouTube API key
- [ ] Firebase credentials
- [ ] JWT secret

---

## Post-Deployment

### Verify All Services
- [ ] Backend API responding
- [ ] Worker processing jobs
- [ ] NGINX routing correctly
- [ ] Database connected
- [ ] Logs being written
- [ ] PM2 auto-restart working

### Performance Testing
- [ ] Load test API endpoints
- [ ] Monitor memory usage
- [ ] Monitor CPU usage
- [ ] Check response times

### Security Audit
- [ ] No secrets in Git repository
- [ ] Security groups properly configured
- [ ] File permissions correct
- [ ] NGINX security headers present
- [ ] Rate limiting working

---

## Maintenance Schedule

### Daily
- [ ] Check PM2 status: `pm2 status`
- [ ] Check logs for errors: `pm2 logs --lines 100`
- [ ] Monitor system resources: `top`, `df -h`

### Weekly
- [ ] Review CloudWatch logs
- [ ] Check RDS storage usage
- [ ] Review security group rules
- [ ] Check for system updates: `sudo yum update`

### Monthly
- [ ] Backup .env file
- [ ] Review and rotate secrets
- [ ] Check cost usage (should be $0)
- [ ] Test disaster recovery

---

## Rollback Plan

### If Deployment Fails
```bash
- [ ] pm2 stop all
- [ ] cd /var/www/streamsync
- [ ] git reset --hard <previous-commit>
- [ ] cd backend
- [ ] npm install --production
- [ ] npm run build
- [ ] pm2 start ecosystem.config.js
```

---

## Success Criteria

- [ ] ✅ All PM2 processes running
- [ ] ✅ Health endpoint returns 200
- [ ] ✅ API endpoints responding
- [ ] ✅ Worker processing jobs
- [ ] ✅ Database accessible
- [ ] ✅ NGINX routing correctly
- [ ] ✅ Frontend app working
- [ ] ✅ Notifications delivered
- [ ] ✅ No errors in logs
- [ ] ✅ Cost = $0 (Free Tier)

---

## 🎉 Deployment Complete!

**Production URL**: `http://<your-ec2-ip>`  
**API Documentation**: `http://<your-ec2-ip>/api`  
**Health Check**: `http://<your-ec2-ip>/health`

---

## Support

- **AWS Deployment Guide**: See `AWS_DEPLOYMENT_GUIDE.md`
- **Troubleshooting**: Check PM2 logs: `pm2 logs`
- **Backend Logs**: `/var/log/streamsync/`
- **NGINX Logs**: `/var/log/nginx/`

---

**Estimated Deployment Time**: 2-3 hours  
**Cost**: $0/month (Free Tier Year 1)  
**Maintenance**: ~15 minutes/week
