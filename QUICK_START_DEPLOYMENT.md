# StreamSync Lite - Quick Deployment Steps

## 🚀 GitHub Deployment (5 minutes)

### 1. Create GitHub Repository
- Go to https://github.com/new
- Repository name: `streamsync-lite`
- Description: "YouTube streaming app with offline sync and push notifications - Hackathon Project"
- Keep it **Public** (for showcase) or **Private**

### 2. Push Your Code
```powershell
cd c:\STREAMSYNC
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/streamsync-lite.git
git push -u origin main
```

✅ Done! Your code is now on GitHub

---

## ☁️ AWS Deployment (30-45 minutes)

### Prerequisites Checklist
- [ ] AWS Account created
- [ ] YouTube API Key from Google Cloud Console
- [ ] Firebase Admin SDK credentials (JSON file)
- [ ] Domain name (optional)

### Quick Setup Commands

#### 1. Create RDS Database (5 mins)
```powershell
aws rds create-db-instance `
  --db-instance-identifier streamsync-db `
  --db-instance-class db.t3.micro `
  --engine postgres `
  --engine-version 16.1 `
  --master-username postgres `
  --master-user-password YourPassword123! `
  --allocated-storage 20 `
  --publicly-accessible `
  --backup-retention-period 7

# Wait 5-10 minutes for DB to be ready
# Get endpoint:
aws rds describe-db-instances `
  --db-instance-identifier streamsync-db `
  --query 'DBInstances[0].Endpoint.Address' `
  --output text
```

#### 2. Launch EC2 Instance (3 mins)
```powershell
aws ec2 run-instances `
  --image-id ami-0c55b159cbfafe1f0 `
  --instance-type t2.micro `
  --key-name YOUR_KEY_PAIR `
  --security-group-ids sg-xxxxxxxx `
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=StreamSync}]'
```

#### 3. Setup EC2 (20 mins)
```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Run setup script
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git nginx postgresql15
sudo npm install -g pm2

# Clone and setup
git clone https://github.com/YOUR_USERNAME/streamsync-lite.git
cd streamsync-lite/backend
npm install

# Create .env (paste your values)
nano .env

# Build and start
npm run build
pm2 start dist/main.js --name api
pm2 start dist/worker.js --name worker
pm2 save
pm2 startup

# Configure Nginx
sudo nano /etc/nginx/conf.d/streamsync.conf
# (Paste nginx config from deploy-to-aws.md)

sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 4. Build Android APK (5 mins)
```powershell
cd c:\STREAMSYNC\frontend

# Update API URL in lib/core/config/app_config.dart
# Change to: http://YOUR_EC2_PUBLIC_IP

flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## ✅ Verification Checklist

### Backend
- [ ] RDS database is running and accessible
- [ ] EC2 instance is running
- [ ] PM2 shows 2 processes running (api + worker)
- [ ] Nginx is running
- [ ] API health check works: `curl http://YOUR_EC2_IP/health`
- [ ] Swagger docs accessible: `http://YOUR_EC2_IP/api/docs`

### Frontend
- [ ] APK built successfully
- [ ] API URL updated to EC2 public IP
- [ ] APK installed on Android device
- [ ] App can login/register
- [ ] Videos load from YouTube
- [ ] Can play videos
- [ ] Can send test push notification
- [ ] Notification arrives on device

---

## 🎥 Demo Video Requirements

Record 3-5 minute video showing:

1. **Intro** (15 seconds)
   - "Hi, I'm showcasing StreamSync Lite"
   - Mention it's a hackathon project

2. **Features Demo** (2-3 minutes)
   - Login screen
   - Home feed with YouTube videos
   - Browse Trending/New/Popular tabs
   - Search for videos
   - Play a video
   - Add to favorites
   - Check watch history in Library
   - Navigate to Profile

3. **Push Notifications** (1 minute)
   - Show Test Push section in Profile
   - Send a test notification
   - Show notification arriving
   - Swipe to delete notification

4. **Architecture Highlight** (30 seconds)
   - Mention: "Backend uses NestJS + PostgreSQL"
   - "YouTube Data API v3 integration"
   - "Firebase Cloud Messaging with worker process"
   - "Offline sync with SQLite"

5. **Outro** (15 seconds)
   - "GitHub: github.com/YOUR_USERNAME/streamsync-lite"
   - "Deployed on AWS EC2 + RDS"
   - "Thank you!"

---

## 📝 Submission Checklist

- [ ] Code pushed to GitHub (public repo)
- [ ] README.md complete with setup instructions
- [ ] Backend deployed on AWS EC2
- [ ] Database running on AWS RDS
- [ ] Android APK built and tested
- [ ] Demo video recorded (3-5 minutes)
- [ ] Architecture diagram included in README
- [ ] .env.example provided (no secrets)
- [ ] API documentation (Swagger) accessible
- [ ] All features working end-to-end

---

## 🆘 Quick Troubleshooting

**Backend not starting?**
```bash
pm2 logs api
# Check .env file has all required variables
```

**Database connection failed?**
```bash
# Test connection
psql -h YOUR_RDS_ENDPOINT -U postgres
# Check RDS security group allows EC2 traffic
```

**Push notifications not working?**
```bash
pm2 logs worker
# Verify Firebase credentials in .env
# Check worker process is running
```

**APK won't install?**
```powershell
# Enable "Install from unknown sources" on Android
# Rebuild: flutter clean && flutter build apk --release
```

---

## 🎯 Time Estimate

| Task | Time |
|------|------|
| GitHub setup | 5 mins |
| AWS RDS setup | 10 mins |
| AWS EC2 setup | 20 mins |
| Configure backend | 15 mins |
| Build APK | 5 mins |
| Testing | 15 mins |
| Demo video | 20 mins |
| **TOTAL** | **90 mins** |

---

## 🔗 Important Links

- **GitHub Repo**: https://github.com/YOUR_USERNAME/streamsync-lite
- **Backend API**: http://YOUR_EC2_IP
- **API Docs**: http://YOUR_EC2_IP/api/docs
- **YouTube API Console**: https://console.cloud.google.com/apis/credentials
- **Firebase Console**: https://console.firebase.google.com/

---

## 🎉 You're Ready!

Follow these steps in order and you'll have:
- ✅ Code on GitHub
- ✅ Backend on AWS
- ✅ Working Android app
- ✅ Demo video
- ✅ Complete hackathon submission

**Good luck with your hackathon! 🚀**
