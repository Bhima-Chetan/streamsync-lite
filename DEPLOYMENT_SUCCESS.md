# 🎉 StreamSync Lite - AWS Deployment Complete!

## ✅ Deployment Summary

**Date:** November 3, 2025  
**Backend URL:** http://3.85.120.15  
**Status:** ✅ **LIVE AND RUNNING**

---

## 📦 What's Deployed

### Backend Infrastructure
- **Server:** AWS EC2 (Amazon Linux 2023, t2.micro)
- **Public IP:** 3.85.120.15
- **Node.js:** v18.20.8
- **Process Manager:** PM2 (streamsync-api)
- **Reverse Proxy:** NGINX 1.28.0
- **Database:** PostgreSQL 15.14 (local)

### Backend Services
- ✅ NestJS API running on port 3000
- ✅ NGINX reverse proxy on port 80
- ✅ Firebase Admin SDK initialized
- ✅ JWT authentication configured (24h access tokens)
- ✅ PostgreSQL database created and connected
- ✅ Health endpoint: http://3.85.120.15/health

### Frontend Configuration
- ✅ Flutter app updated to use EC2 backend
- ✅ API base URL: `http://3.85.120.15`
- ✅ API client regenerated with new URL

---

## 🚀 Testing the Deployment

### 1. Test Backend Health
```powershell
curl http://3.85.120.15/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-03T12:25:04.477Z",
  "uptime": 1681.898094475
}
```

### 2. Run Flutter App
```powershell
cd C:\STREAMSYNC\frontend
flutter run
```

The app should now connect to the AWS EC2 backend!

---

## 📊 PM2 Process Status

Check backend process:
```bash
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 status"
```

View logs:
```bash
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 logs streamsync-api"
```

Restart backend:
```bash
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 restart streamsync-api"
```

---

## 🔐 Security Configuration

### Current Setup
- ✅ SSH (port 22) open from your IP only
- ✅ HTTP (port 80) open to public (0.0.0.0/0)
- ✅ PostgreSQL (port 5432) localhost only
- ✅ Backend API (port 3000) localhost only (proxied via NGINX)

### ⚠️ URGENT: SSH Key Rotation Required
**You accidentally exposed your SSH private key in chat.** Please:

1. **Generate a new SSH keypair:**
   ```powershell
   ssh-keygen -t rsa -b 4096 -f C:\Users\YourName\.ssh\streamsync-new -N ""
   ```

2. **Add new public key to EC2:**
   ```bash
   ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15
   echo "YOUR_NEW_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
   ```

3. **Remove old compromised key:**
   ```bash
   nano ~/.ssh/authorized_keys
   # Delete the old key line, save and exit
   ```

4. **Delete old keypair from AWS Console:**
   - EC2 → Key Pairs → Delete "streamsync"

---

## 🔧 Backend Configuration

### Environment Variables (.env on EC2)
```bash
NODE_ENV=production
PORT=3000
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=streamsync
DATABASE_PASSWORD=streamsync123
DATABASE_NAME=streamsync
JWT_SECRET=3HoFjwdDQNIBGb5LxO1vcfeT6spZtWhP
JWT_EXPIRES_IN=24h
FIREBASE_PROJECT_ID=streamsync-dccc1
YOUTUBE_API_KEY=AIzaSyAo9PdNWl5fPr57VhRVZWJu8rmTAh8Noo4
```

### NGINX Configuration
Location: `/etc/nginx/conf.d/streamsync.conf`

```nginx
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
    }
}
```

---

## 📱 Flutter App Updates Made

### Files Modified:
1. **`frontend/lib/core/config/app_config.dart`**
   - Changed `apiBaseUrl` from `http://192.168.1.8:3000` to `http://3.85.120.15`

2. **`frontend/lib/core/di/injection.dart`**
   - Updated Dio `baseUrl` to `http://3.85.120.15`

3. **`frontend/lib/data/remote/api_client.g.dart`**
   - Regenerated with new base URL

---

## 🎯 Next Steps (Optional)

### 1. Enable HTTPS with SSL/TLS
- Use Let's Encrypt with Certbot
- Install Certbot: `sudo dnf install -y certbot python3-certbot-nginx`
- Get certificate: `sudo certbot --nginx -d yourdomain.com`

### 2. Migrate to RDS (Production Database)
- Create RDS PostgreSQL Free Tier instance
- Update `DATABASE_HOST` in backend .env
- Migrate data from local PostgreSQL to RDS

### 3. Set up CloudWatch Logging
- Install CloudWatch agent on EC2
- Stream PM2 logs to CloudWatch
- Set up alarms for errors/downtime

### 4. Configure PM2 Startup
```bash
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15
pm2 startup
# Run the command it outputs
pm2 save
```

### 5. Enable Firebase Cloud Messaging
- Test push notifications from Profile screen
- Verify FCM tokens are registered correctly

---

## 🐛 Troubleshooting

### Backend not responding
```bash
# Check if PM2 process is running
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 status"

# Restart backend
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 restart streamsync-api"

# Check NGINX status
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "sudo systemctl status nginx"
```

### Flutter app can't connect
1. Verify backend health: `curl http://3.85.120.15/health`
2. Check security group has port 80 open
3. Ensure Flutter app has internet permissions (already configured)
4. Check for CORS errors in backend logs

### Database connection errors
```bash
# Check PostgreSQL status
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "sudo systemctl status postgresql"

# Check backend logs for DB errors
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15 "pm2 logs streamsync-api --err"
```

---

## 📞 Quick Commands Reference

### Connect to EC2
```powershell
ssh -i "D:\streamsync.pem" ec2-user@3.85.120.15
```

### View Backend Logs
```bash
pm2 logs streamsync-api
```

### Restart Services
```bash
pm2 restart streamsync-api
sudo systemctl restart nginx
sudo systemctl restart postgresql
```

### Update Backend Code
```bash
cd ~/streamsync-lite/backend
git pull
npm install
npm run build
pm2 restart streamsync-api
```

---

## 🎊 Success Metrics

✅ **All deployment tasks completed!**
- [x] EC2 instance launched and configured
- [x] Node.js, Git, PM2 installed
- [x] PostgreSQL database setup
- [x] Backend deployed and running
- [x] NGINX reverse proxy configured
- [x] Security groups configured
- [x] Flutter app updated to use EC2

**🚀 Your app is now live on AWS Free Tier!**

---

## 💰 AWS Free Tier Usage

**Current Resources:**
- EC2 t2.micro: ✅ Free Tier eligible (750 hours/month)
- Data Transfer: ✅ 100 GB out/month free
- PostgreSQL: ✅ Running locally (no RDS charges)

**Estimated Monthly Cost:** $0 (within Free Tier limits)

---

**Deployment completed successfully!** 🎉
