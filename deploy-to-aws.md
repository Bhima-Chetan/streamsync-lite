# StreamSync Lite - AWS Deployment Guide

## Prerequisites
- AWS Account
- AWS CLI installed and configured
- Domain name (optional but recommended)

## Step 1: Setup AWS RDS PostgreSQL Database

### Create RDS Instance
```powershell
aws rds create-db-instance `
  --db-instance-identifier streamsync-db `
  --db-instance-class db.t3.micro `
  --engine postgres `
  --engine-version 16.1 `
  --master-username postgres `
  --master-user-password YourSecurePassword123! `
  --allocated-storage 20 `
  --publicly-accessible `
  --backup-retention-period 7 `
  --vpc-security-group-ids sg-xxxxxxxx
```

### Get RDS Endpoint
```powershell
aws rds describe-db-instances `
  --db-instance-identifier streamsync-db `
  --query 'DBInstances[0].Endpoint.Address' `
  --output text
```

Save this endpoint - you'll need it for environment variables.

## Step 2: Launch EC2 Instance

### Create EC2 Instance
```powershell
aws ec2 run-instances `
  --image-id ami-0c55b159cbfafe1f0 `
  --instance-type t3.small `
  --key-name YOUR_KEY_PAIR_NAME `
  --security-group-ids sg-xxxxxxxx `
  --subnet-id subnet-xxxxxxxx `
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=StreamSync-Backend}]'
```

### Security Group Rules
Ensure your security group allows:
- Port 22 (SSH) from your IP
- Port 80 (HTTP) from 0.0.0.0/0
- Port 443 (HTTPS) from 0.0.0.0/0
- Port 3000 (API) from 0.0.0.0/0 (temporarily, will be proxied through nginx)

```powershell
# Add inbound rules
aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxxxxx `
  --protocol tcp --port 22 --cidr YOUR_IP/32

aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxxxxx `
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxxxxx `
  --protocol tcp --port 443 --cidr 0.0.0.0/0
```

## Step 3: Connect to EC2 and Setup Environment

### SSH into EC2
```powershell
ssh -i "path\to\your-key.pem" ec2-user@YOUR_EC2_PUBLIC_IP
```

### Install Required Software
```bash
# Update system
sudo yum update -y

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version  # Should show v18.x
npm --version

# Install Git
sudo yum install -y git

# Install PM2 globally
sudo npm install -g pm2

# Install Nginx
sudo yum install -y nginx

# Install PostgreSQL client (for testing connection)
sudo yum install -y postgresql15
```

## Step 4: Clone and Setup Backend

```bash
# Clone repository
cd /home/ec2-user
git clone https://github.com/YOUR_USERNAME/streamsync-lite.git
cd streamsync-lite/backend

# Install dependencies
npm install

# Create .env file
nano .env
```

### .env Configuration
```env
NODE_ENV=production
PORT=3000

# Database - Use your RDS endpoint
DATABASE_HOST=streamsync-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=YourSecurePassword123!
DATABASE_NAME=streamsync

# JWT Secrets - Generate secure random strings
JWT_SECRET=your-very-long-and-secure-jwt-secret-key-here
JWT_REFRESH_SECRET=your-very-long-and-secure-refresh-secret-key-here

# YouTube API
YOUTUBE_API_KEY=YOUR_YOUTUBE_API_KEY_FROM_GOOGLE_CLOUD
YOUTUBE_CHANNEL_ID=UC_x5XG1OV2P6uZZ5FSM9Ttw
YOUTUBE_CACHE_TTL=600

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Worker
WORKER_POLL_INTERVAL=5000
```

Save and exit (Ctrl+X, Y, Enter)

### Test Database Connection
```bash
psql -h streamsync-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d postgres

# If connected successfully, create database:
CREATE DATABASE streamsync;
\q
```

### Build and Start Application
```bash
# Build TypeScript
npm run build

# Start API with PM2
pm2 start dist/main.js --name streamsync-api

# Start Worker with PM2
pm2 start dist/worker.js --name streamsync-worker

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system boot
pm2 startup
# Copy and run the command it outputs

# Check status
pm2 status
pm2 logs
```

## Step 5: Configure Nginx Reverse Proxy

```bash
# Create Nginx configuration
sudo nano /etc/nginx/conf.d/streamsync.conf
```

```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain or EC2 public IP

    location / {
        proxy_pass http://localhost:3000;
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
# Test Nginx configuration
sudo nginx -t

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

## Step 6: Setup SSL with Let's Encrypt (Optional but Recommended)

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Follow prompts to configure SSL
# Certbot will automatically update your Nginx config

# Test auto-renewal
sudo certbot renew --dry-run
```

## Step 7: Configure Firewall

```bash
# If firewalld is running
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Or use iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo service iptables save
```

## Step 8: Test Backend API

```powershell
# Test health endpoint
curl http://YOUR_EC2_PUBLIC_IP/health

# Test API documentation
# Visit: http://YOUR_EC2_PUBLIC_IP/api/docs
```

## Step 9: Update Frontend Configuration

Update `frontend/lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://your-domain.com';  // or http://YOUR_EC2_IP
  static const String apiVersion = 'v1';
}
```

## Step 10: Build and Deploy Android APK

```powershell
cd c:\STREAMSYNC\frontend

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`
AAB location: `build/app/outputs/bundle/release/app-release.aab`

## Monitoring and Maintenance

### View Logs
```bash
# PM2 logs
pm2 logs streamsync-api
pm2 logs streamsync-worker

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
# Restart API
pm2 restart streamsync-api

# Restart Worker
pm2 restart streamsync-worker

# Restart Nginx
sudo systemctl restart nginx
```

### Update Application
```bash
cd /home/ec2-user/streamsync-lite
git pull
cd backend
npm install
npm run build
pm2 restart all
```

### Monitor Resources
```bash
# System resources
htop

# PM2 monitoring
pm2 monit

# Disk usage
df -h
```

## Cost Estimation (AWS Free Tier)

- **EC2 t3.small**: ~$0.023/hour (~$17/month) - NOT free tier
- **EC2 t2.micro**: Free tier eligible (750 hours/month for 12 months)
- **RDS db.t3.micro**: Free tier eligible (750 hours/month for 12 months)
- **Data transfer**: First 1 GB/month free
- **Storage**: 20 GB free with RDS

**Recommended for hackathon**: Use t2.micro to stay within free tier

## Troubleshooting

### API not responding
```bash
pm2 logs streamsync-api
# Check for errors
```

### Database connection failed
```bash
# Test connection
psql -h YOUR_RDS_ENDPOINT -U postgres -d streamsync
# Check security group allows traffic from EC2
```

### Nginx 502 Bad Gateway
```bash
# Check if backend is running
pm2 status
# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### Worker not processing jobs
```bash
pm2 logs streamsync-worker
# Check Firebase credentials in .env
```

## Alternative: AWS Elastic Beanstalk (Easier)

```powershell
# Install EB CLI
pip install awsebcli

# Initialize
cd c:\STREAMSYNC\backend
eb init -p node.js-18 streamsync --region us-east-1

# Create environment
eb create streamsync-env

# Deploy
eb deploy

# Set environment variables
eb setenv `
  DATABASE_HOST=your-rds `
  JWT_SECRET=your-secret `
  YOUTUBE_API_KEY=your-key
```

## Success Checklist

- [ ] RDS database created and accessible
- [ ] EC2 instance running
- [ ] Backend code deployed
- [ ] PM2 processes running (API + Worker)
- [ ] Nginx configured and running
- [ ] SSL certificate installed (optional)
- [ ] API accessible via public URL
- [ ] Frontend APK built with correct API URL
- [ ] Tested end-to-end: Login → Videos → Notifications

## Next Steps

1. Test all API endpoints
2. Install APK on Android device
3. Test push notifications
4. Record demo video
5. Submit project!
