# 🎯 StreamSync Lite - AWS Deployment Summary

## ✅ What I've Created for You

### 📄 Documentation Files
1. **AWS_DEPLOYMENT.md** - Complete step-by-step AWS deployment guide
   - RDS PostgreSQL setup (Free Tier)
   - EC2 instance configuration
   - PM2 process manager setup
   - NGINX reverse proxy configuration
   - CloudWatch logging setup
   - IAM roles and permissions
   - Troubleshooting guide

2. **QUICK_DEPLOY.md** - Quick 5-step deployment (15 minutes)
   - Fast track for experienced users
   - CLI commands for all steps
   - Verification checklist
   - Cost breakdown
   - Troubleshooting tips

3. **README.md** - Updated with AWS deployment section
   - Architecture diagrams
   - Technology stack
   - Requirements checklist
   - Cost estimates
   - Quick start guide

### 🛠 Deployment Scripts

4. **deploy.ps1** - PowerShell deployment automation
   - Clones/updates repository on EC2
   - Installs dependencies
   - Builds application
   - Configures environment (fetches from Parameter Store)
   - Starts with PM2
   - Tests health endpoint
   - Usage: `.\deploy.ps1 -EC2IP "your-ip" -KeyFile "key.pem" -RDSEndpoint "rds-endpoint"`

5. **setup-secrets.ps1** - AWS Parameter Store setup
   - Interactive script for storing secrets
   - Prompts for all required values
   - Auto-detects Firebase key from .env
   - Usage: `.\setup-secrets.ps1 -Region "us-east-1"`

### 🔧 Configuration Files

6. **docker-compose.prod.yml** - Production Docker Compose (optional)
   - Health checks
   - Logging configuration
   - Network isolation
   - Can use instead of PM2 if preferred

7. **.env.production.example** - Environment template
   - All required variables documented
   - Safe to commit (no secrets)
   - Copy and fill for production

8. **backend/.gitignore** - Updated to prevent secrets in repo
   - Excludes .env files
   - Excludes .pem keys
   - Excludes PM2 logs
   - Allows .env.production.example

---

## 🚀 Deployment Architecture (PM2 + NGINX)

```
Internet
   │
   ▼
┌────────────────────────────────────────┐
│  AWS EC2 t2.micro (Free Tier)          │
│  Amazon Linux 2023                     │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  NGINX (Port 80)                 │ │
│  │  - Reverse Proxy                 │ │
│  │  - Security Headers              │ │
│  │  - Request Logging               │ │
│  └──────────┬───────────────────────┘ │
│             │                          │
│             ▼                          │
│  ┌──────────────────────────────────┐ │
│  │  PM2 Process Manager             │ │
│  │  - Auto-restart on crash         │ │
│  │  - CPU/Memory monitoring         │ │
│  │  - Log management                │ │
│  │  - Zero-downtime reload          │ │
│  └──────────┬───────────────────────┘ │
│             │                          │
│             ▼                          │
│  ┌──────────────────────────────────┐ │
│  │  NestJS Backend (Port 3000)      │ │
│  │  - REST API                      │ │
│  │  - Business Logic                │ │
│  │  - Firebase FCM                  │ │
│  │  - YouTube API                   │ │
│  └──────────┬───────────────────────┘ │
└─────────────┼──────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  AWS RDS PostgreSQL db.t3.micro         │
│  (Free Tier - 20GB Storage)             │
│  - User data                            │
│  - FCM tokens                           │
│  - Watch progress                       │
│  - Favorites                            │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  AWS Systems Manager Parameter Store    │
│  (Secrets - Not in Repository)          │
│  - DATABASE_PASSWORD                    │
│  - JWT_SECRET                           │
│  - JWT_REFRESH_SECRET                   │
│  - FIREBASE_PRIVATE_KEY                 │
│  - YOUTUBE_API_KEY                      │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  CloudWatch Logs                        │
│  - Application logs (PM2 stdout/stderr) │
│  - NGINX access logs                    │
│  - NGINX error logs                     │
│  - Real-time monitoring                 │
└─────────────────────────────────────────┘
```

---

## 📋 Step-by-Step Deployment Checklist

### Phase 1: AWS Resources Setup (10 minutes)

- [ ] **Create RDS PostgreSQL Database**
  ```bash
  aws rds create-db-instance \
    --db-instance-identifier streamsync-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20
  ```
  - Note down endpoint after creation (~5 min)

- [ ] **Launch EC2 Instance**
  ```bash
  aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t2.micro \
    --key-name your-key-pair
  ```
  - Note down public IP

- [ ] **Configure Security Groups**
  - EC2: Allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
  - RDS: Allow port 5432 from EC2 security group

### Phase 2: IAM Configuration (5 minutes)

- [ ] **Create IAM Role for EC2**
  ```bash
  aws iam create-role --role-name StreamSyncEC2Role
  ```

- [ ] **Attach Policies**
  - `AmazonSSMReadOnlyAccess` (for Parameter Store)
  - `CloudWatchAgentServerPolicy` (for logging)

- [ ] **Attach Role to EC2 Instance**

### Phase 3: Store Secrets (2 minutes)

- [ ] **Run Setup Script**
  ```powershell
  .\setup-secrets.ps1 -Region "us-east-1"
  ```
  - Enter RDS password
  - Generate JWT secrets (random strings)
  - Firebase key auto-detected from .env
  - YouTube API key (default provided)

### Phase 4: Install Dependencies on EC2 (5 minutes)

- [ ] **SSH into EC2**
  ```bash
  ssh -i your-key.pem ec2-user@YOUR-EC2-IP
  ```

- [ ] **Install Node.js, PM2, NGINX**
  ```bash
  curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
  sudo yum install -y nodejs nginx git
  sudo npm install -g pm2
  ```

- [ ] **Configure PM2 Startup**
  ```bash
  pm2 startup systemd -u ec2-user --hp /home/ec2-user
  ```

- [ ] **Configure NGINX** (see AWS_DEPLOYMENT.md for config)

### Phase 5: Deploy Application (3 minutes)

- [ ] **Run Deployment Script**
  ```powershell
  .\deploy.ps1 -EC2IP "your-ip" -KeyFile "key.pem" -RDSEndpoint "rds-endpoint"
  ```
  
  This script will:
  - Clone repository
  - Install dependencies
  - Build application
  - Create environment loader (fetches secrets from Parameter Store)
  - Start with PM2
  - Test health endpoint

- [ ] **Verify Deployment**
  ```bash
  curl http://YOUR-EC2-IP/health
  # Should return: {"status":"ok","timestamp":"..."}
  ```

### Phase 6: Update Flutter App (2 minutes)

- [ ] **Update API Base URL**
  ```dart
  // frontend/lib/data/remote/api_client.dart (line ~15)
  static const String baseUrl = 'http://YOUR-EC2-IP';
  ```

- [ ] **Build APK**
  ```bash
  cd frontend
  flutter build apk --release
  ```

- [ ] **Test App**
  - Install APK on device
  - Login/register
  - Test video streaming
  - **Test Push Notification** (Profile → Test Area)

---

## 🎯 Key Features of This Setup

### ✅ Meets All Hackathon Requirements

1. **EC2 t2.micro with PM2** ✓
   - Process management
   - Auto-restart on crashes
   - Zero-downtime reloads

2. **NGINX Reverse Proxy** ✓
   - Port 80 HTTP
   - Security headers
   - Request logging
   - Load balancing ready

3. **RDS Free Tier PostgreSQL** ✓
   - db.t3.micro instance
   - 20 GB storage
   - Automatic backups

4. **CloudWatch Logging** ✓
   - Application logs (PM2)
   - NGINX access/error logs
   - Real-time monitoring

5. **Health Endpoint** ✓
   - `/health` for uptime checks
   - Cron job monitoring
   - Auto-restart on failure

6. **Secrets Management** ✓
   - AWS Systems Manager Parameter Store
   - No secrets in repository
   - IAM role-based access

7. **No Paid AWS Services** ✓
   - Only Free Tier resources
   - YouTube embed (free API)
   - Firebase FCM (free tier)

### 🔒 Security Best Practices

- ✅ Secrets stored in Parameter Store, not in repo
- ✅ JWT authentication with refresh tokens
- ✅ bcrypt password hashing
- ✅ Helmet security headers
- ✅ Rate limiting (100 req/min)
- ✅ NGINX reverse proxy
- ✅ IAM roles (no hardcoded credentials)
- ✅ Security groups restrict access

### 🚀 Production-Ready Features

- ✅ PM2 process management
- ✅ Auto-restart on crashes
- ✅ Zero-downtime deployments
- ✅ CloudWatch centralized logging
- ✅ Health monitoring
- ✅ NGINX load balancing ready
- ✅ Database connection pooling
- ✅ Swagger API documentation

---

## 💰 Cost Analysis

### Free Tier (12 Months)
| Resource | Usage | Cost |
|----------|-------|------|
| EC2 t2.micro | 750 hrs/mo | $0 |
| RDS db.t3.micro | 750 hrs/mo | $0 |
| RDS Storage (20 GB) | Included | $0 |
| EBS (30 GB) | Included | $0 |
| CloudWatch Basic | Included | $0 |
| Parameter Store | < 10,000 req | $0 |
| **Monthly Total** | | **$0** |

### After Free Tier
| Resource | Cost |
|----------|------|
| EC2 t2.micro | $8-10/mo |
| RDS db.t3.micro | $15-18/mo |
| Data Transfer | $1-2/mo |
| **Monthly Total** | **$24-30/mo** |

### Hackathon Demo (2-3 Days)
- **Total Cost: ~$2-3**
- Stop instances when not demoing
- Can restart anytime

---

## 🔧 Management Commands

### On EC2 (SSH Required)

```bash
# PM2 Management
pm2 status                  # Check app status
pm2 logs streamsync-api     # View real-time logs
pm2 restart streamsync-api  # Restart app
pm2 reload streamsync-api   # Zero-downtime reload
pm2 monit                   # Monitor CPU/Memory

# NGINX Management
sudo systemctl status nginx      # Check NGINX status
sudo systemctl restart nginx     # Restart NGINX
sudo nginx -t                    # Test configuration
sudo tail -f /var/log/nginx/streamsync-error.log

# Application Health
curl http://localhost:3000/health
```

### From Local Machine

```powershell
# View CloudWatch Logs
aws logs tail /aws/ec2/streamsync/application --follow

# Check EC2 Status
aws ec2 describe-instances --instance-ids i-xxxxxx

# Update Secrets
.\setup-secrets.ps1 -Region "us-east-1"

# Redeploy
.\deploy.ps1 -EC2IP "ip" -KeyFile "key.pem" -RDSEndpoint "rds"

# SSH Into EC2
ssh -i your-key.pem ec2-user@YOUR-EC2-IP
```

---

## 📚 Documentation Reference

| File | Purpose | When to Use |
|------|---------|-------------|
| **README.md** | Project overview | Understanding the project |
| **AWS_DEPLOYMENT.md** | Complete deployment guide | First-time setup, detailed steps |
| **QUICK_DEPLOY.md** | Fast deployment | Experienced users, quick reference |
| **deploy.ps1** | Automated deployment | Every deployment/update |
| **setup-secrets.ps1** | Setup Parameter Store | First-time setup, secret updates |
| **docker-compose.prod.yml** | Docker alternative | If using Docker instead of PM2 |

---

## ✅ Deployment Verification

After deployment, verify:

- [ ] Health endpoint: `curl http://YOUR-EC2-IP/health`
- [ ] API docs: `http://YOUR-EC2-IP/api/docs`
- [ ] PM2 running: `pm2 status` (shows streamsync-api)
- [ ] NGINX running: `sudo systemctl status nginx`
- [ ] CloudWatch logs visible in AWS Console
- [ ] Secrets loading from Parameter Store
- [ ] Flutter app connects to backend
- [ ] Login/register works
- [ ] Videos load from YouTube
- [ ] **Test Push notification works** ✨

---

## 🎉 You're Ready to Deploy!

### Quick Deployment Command

```powershell
# One-line deployment (after AWS resources are created)
.\setup-secrets.ps1; .\deploy.ps1 -EC2IP "your-ip" -KeyFile "key.pem" -RDSEndpoint "rds"
```

### Next Steps

1. **Create RDS and EC2** (see QUICK_DEPLOY.md Step 1)
2. **Run setup-secrets.ps1**
3. **Run deploy.ps1**
4. **Update Flutter app API URL**
5. **Build APK and test**
6. **Submit hackathon with working demo! 🚀**

---

## 🆘 Need Help?

- **Full Guide**: [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)
- **Quick Guide**: [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)
- **Troubleshooting**: See AWS_DEPLOYMENT.md → Troubleshooting section
- **API Docs**: `http://your-ec2-ip/api/docs`

**Good luck with your hackathon! 🎯**
