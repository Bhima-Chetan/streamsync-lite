# StreamSync Production Deployment Setup

## ✅ Completed

### 1. CloudWatch Agent Installation
- ✅ Installed Amazon CloudWatch Agent on EC2
- ✅ Created configuration to monitor:
  - Application logs (`/home/ec2-user/.pm2/logs/streamsync-api-*.log`)
  - NGINX logs (`/var/log/nginx/*.log`)
  - System metrics (CPU, Memory, Disk)
- ✅ Agent is running and active

### 2. PM2 Auto-Start
- ✅ PM2 process saved
- ✅ Systemd service created (`pm2-ec2-user.service`)
- ✅ Service enabled to start on boot
- Your app will automatically restart after server reboots

### 3. Application Fixes
- ✅ YouTube API null safety issues resolved
- ✅ FCM token registration on signup/login
- ✅ Firebase private key parsing fixed
- ✅ Push notifications working

## 🔧 Required: IAM Role Configuration

**The EC2 instance needs CloudWatch permissions to send logs and metrics.**

### Steps to Complete in AWS Console:

1. **Go to IAM Console** → Roles
2. **Create a new role** or modify existing EC2 role with these permissions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents",
           "logs:DescribeLogStreams",
           "cloudwatch:PutMetricData"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

3. **Attach the role to your EC2 instance:**
   - EC2 Console → Instances
   - Select your instance (3.85.120.15)
   - Actions → Security → Modify IAM role
   - Attach the CloudWatch role
   - **Restart CloudWatch agent:** `sudo systemctl restart amazon-cloudwatch-agent`

### After IAM Role is Attached:

**CloudWatch Log Groups will be created automatically:**
- `/aws/ec2/streamsync/app` - Application logs (out & error)
- `/aws/ec2/streamsync/nginx` - NGINX logs (access & error)

**Custom Metrics in CloudWatch:**
- Namespace: `StreamSync`
- Metrics: CPU_IDLE, CPU_IOWAIT, DISK_USED, MEM_USED
- Collection interval: 60 seconds
- Retention: 7 days

## 📋 Next Steps

### 1. RDS Migration (High Priority)
**Current:** Local PostgreSQL on EC2  
**Target:** AWS RDS PostgreSQL

**Benefits:**
- Automated backups
- High availability
- Better performance
- Managed updates

**Steps:**
```bash
# 1. Create RDS instance (AWS Console)
# 2. Export local database
pg_dump -U streamsync -d streamsync > backup.sql

# 3. Import to RDS
psql -h <rds-endpoint> -U postgres -d streamsync < backup.sql

# 4. Update .env file
DATABASE_HOST=<rds-endpoint>
DATABASE_PORT=5432
DATABASE_NAME=streamsync

# 5. Restart application
pm2 restart streamsync-api
```

### 2. HTTPS Setup with Let's Encrypt
**Current:** HTTP only (http://3.85.120.15)  
**Target:** HTTPS with valid SSL certificate

**Requirements:**
- Domain name (e.g., streamsync.yourdomain.com)
- DNS A record pointing to 3.85.120.15

**Steps:**
```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d streamsync.yourdomain.com

# Auto-renewal (certbot sets this up automatically)
sudo systemctl enable certbot-renew.timer
```

### 3. Security Hardening

**SSH Key Rotation (CRITICAL):**
- Current key (streamsync.pem) was exposed in chat
- Generate new key pair
- Update EC2 instance authorized_keys
- Delete old key

**Environment Variables:**
- Move sensitive data to AWS Secrets Manager or Parameter Store
- Remove hardcoded credentials from .env

**Firewall Rules:**
- Restrict SSH (port 22) to your IP only
- Keep HTTP/HTTPS open for public access

### 4. Monitoring & Alerts

**Set up CloudWatch Alarms:**
- High CPU usage (> 80%)
- High memory usage (> 90%)
- Low disk space (< 20% free)
- Application errors in logs
- HTTP 5xx errors

**Email notifications:**
- Use SNS to send alerts
- Monitor application health

### 5. Backup Strategy

**Database Backups:**
- Daily automated backups (RDS handles this)
- Export schema separately
- Store backups in S3

**Application Code:**
- Already in GitHub ✅
- Consider private repository for production secrets

## 🔍 Monitoring URLs

Once IAM role is configured:

**CloudWatch Logs:**
- https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

**CloudWatch Metrics:**
- https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~();namespace=StreamSync

**EC2 Instance:**
- https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:

## 📊 Current Infrastructure

- **Backend:** NestJS on EC2 (t2.micro)
- **Database:** PostgreSQL 15.14 (local)
- **Reverse Proxy:** NGINX 1.28.0
- **Process Manager:** PM2 6.0.13
- **Frontend:** Flutter app (APK)
- **Push Notifications:** Firebase Cloud Messaging
- **Region:** us-east-1 (N. Virginia)

## 🎯 Production Checklist

- ✅ Application running and stable
- ✅ Push notifications working
- ✅ PM2 auto-start configured
- ✅ CloudWatch agent installed
- ⏳ IAM role for CloudWatch (pending)
- ⏳ RDS migration (pending)
- ⏳ HTTPS setup (needs domain)
- ⏳ SSH key rotation (security)
- ⏳ CloudWatch alarms (pending)
- ⏳ Secrets management (pending)

## 📝 Notes

- CloudWatch logs retention: 7 days (can be increased)
- Metrics collection: Every 60 seconds
- PM2 restarts: 24 times (check for memory leaks if increasing)
- EC2 instance type: t2.micro (consider upgrading for production)
