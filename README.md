# StreamSync Lite - Hackathon Project

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   BLoC     │  │  Repository  │  │  Local ORM   │        │
│  │  /ViewModel│──│    Layer     │──│   (Drift)    │        │
│  └────────────┘  └──────────────┘  └──────────────┘        │
│         │                │                                   │
│         │                └─────────── HTTP/REST API         │
└─────────┼────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│               Node.js Backend (NestJS)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │  Videos  │  │  Users   │  │ Notifs   │   │
│  │  Module  │  │  Module  │  │  Module  │  │  Module  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│       │             │              │             │          │
│       └─────────────┴──────────────┴─────────────┘          │
│                          │                                   │
│                          ▼                                   │
│              ┌──────────────────────┐                       │
│              │  TypeORM + Postgres  │                       │
│              └──────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
          │                                    │
          ▼                                    ▼
  YouTube Data API v3              Firebase Cloud Messaging
  (Video Metadata)                  (Push Notifications)
```

## Project Structure

```
STREAMSYNC/
├── backend/                    # Node.js TypeScript NestJS API
│   ├── src/
│   │   ├── config/            # Database, Firebase config
│   │   ├── modules/
│   │   │   ├── auth/          # JWT authentication
│   │   │   ├── users/         # User & FCM token management
│   │   │   ├── videos/        # Video, Progress, Favorites
│   │   │   └── notifications/ # Push notification system
│   │   ├── app.module.ts
│   │   └── main.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── .env.example
│
└── frontend/                  # Flutter mobile app
    ├── lib/
    │   ├── core/             # DI, constants, themes
    │   ├── data/
    │   │   ├── local/        # Drift ORM, local database
    │   │   ├── remote/       # API clients
    │   │   └── repositories/ # Data layer abstraction
    │   ├── domain/           # Models, entities
    │   ├── presentation/
    │   │   ├── blocs/        # BLoC state management
    │   │   ├── screens/      # UI screens
    │   │   └── widgets/      # Reusable components
    │   └── main.dart
    ├── pubspec.yaml
    └── android/
        └── app/
            └── google-services.json
```

## Backend Setup

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL database (local or AWS RDS)
- YouTube Data API v3 key
- Firebase project with Admin SDK credentials

### Installation Steps

1. **Navigate to backend directory**
```powershell
cd c:\STREAMSYNC\backend
```

2. **Install dependencies**
```powershell
npm install
```

3. **Install additional missing dependencies**
```powershell
npm install @nestjs/config @nestjs/axios nestjs-pino pino-http pino-pretty
```

4. **Create .env file from template**
```powershell
Copy-Item .env.example .env
```

5. **Configure environment variables in .env**
- Set your database credentials
- Add YouTube API key from Google Cloud Console
- Add Firebase credentials from Firebase Console > Project Settings > Service Accounts
- Update JWT secrets with secure random strings

6. **Create PostgreSQL database**
```powershell
# Using psql or pgAdmin, create database:
# CREATE DATABASE streamsync;
```

7. **Run database migrations** (auto-sync enabled in development)
```powershell
npm run start:dev
```

8. **Test backend**
- Visit: http://localhost:3000/health
- Visit: http://localhost:3000/api/docs (Swagger UI)

### Running the Worker (for push notifications)

The worker process handles queued notification jobs. You need to create the worker entry point:

Create `backend/src/worker.ts` with the notification worker logic, then run:
```powershell
npm run start:worker
```

## Frontend Setup

### Prerequisites

- Flutter SDK 3.0+ (stable channel)
- Android Studio / VS Code with Flutter extensions
- Firebase project (same as backend)
- Android SDK configured

### Installation Steps

1. **Create Flutter project**
```powershell
cd c:\STREAMSYNC\frontend
flutter create --org com.streamsync --project-name streamsync_lite .
```

2. **Add dependencies to pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  provider: ^6.0.5
  get_it: ^7.6.0
  
  # Local Database
  drift: ^2.13.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Networking
  dio: ^5.3.3
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # Firebase & Push Notifications
  firebase_core: ^2.17.0
  firebase_messaging: ^14.6.9
  
  # YouTube Player
  youtube_player_flutter: ^8.1.2
  
  # UI & Utils
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  freezed_annotation: ^2.4.1
  equatable: ^2.0.5
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code Generation
  build_runner: ^2.4.6
  drift_dev: ^2.13.0
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.0
```

3. **Install dependencies**
```powershell
flutter pub get
```

4. **Configure Firebase**
- Download `google-services.json` from Firebase Console
- Place in `android/app/google-services.json`
- Update `android/app/build.gradle` to include Firebase plugin

5. **Configure Android permissions**

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Implementation Checklist

### Backend (COMPLETED - Files Created)
- [x] Project structure and configuration
- [x] Database entities (User, Video, Progress, Favorite, Notification, NotificationJob, FcmToken)
- [x] Auth module (register, login, refresh with JWT)
- [x] Users module (FCM token management)
- [x] Videos module (YouTube integration, progress tracking)
- [ ] Notifications module (PENDING - needs controllers and worker)
- [ ] Worker process for push notifications (PENDING)
- [ ] Tests (PENDING)

### Frontend (NEEDS IMPLEMENTATION)
- [ ] Local database with Drift ORM
- [ ] API client with Dio/Retrofit
- [ ] Repository layer
- [ ] BLoC state management
- [ ] Splash & Auth screens
- [ ] Home feed screen
- [ ] Video player screen
- [ ] Notifications tab
- [ ] Profile & Test Push screen
- [ ] Offline sync service
- [ ] Firebase messaging setup
- [ ] Tests

## Next Steps to Complete Implementation

### 1. Complete Backend - Notifications Module

Create these files:
- `backend/src/modules/notifications/dto/notification.dto.ts`
- `backend/src/modules/notifications/notifications.controller.ts`
- `backend/src/modules/notifications/notifications.service.ts`
- `backend/src/modules/notifications/notifications.module.ts`
- `backend/src/worker.ts` (notification job processor)

### 2. Implement Flutter App

Follow this order:
1. Setup local database (Drift)
2. Create API clients
3. Setup dependency injection
4. Implement authentication flow
5. Implement video feed
6. Implement video player
7. Implement notifications
8. Implement offline sync
9. Add tests

### 3. AWS Deployment

- Deploy backend to EC2 t2.micro or Elastic Beanstalk
- Setup RDS PostgreSQL Free Tier
- Configure environment variables
- Setup PM2 for process management
- Configure NGINX reverse proxy
- Setup CloudWatch logging

## API Endpoints

### Auth
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `POST /auth/refresh` - Refresh access token

### Users
- `POST /users/:id/fcmToken` - Register FCM token
- `DELETE /users/:id/fcmToken` - Remove FCM token

### Videos
- `GET /videos/latest?channelId={id}` - Get 10 latest videos
- `GET /videos/{videoId}` - Get single video
- `POST /videos/progress` - Save playback progress
- `GET /videos/progress?userId={id}` - Get user progress
- `POST /videos/favorites` - Toggle favorite
- `GET /videos/favorites?userId={id}` - Get user favorites

### Notifications
- `GET /notifications?userId={id}&limit=50` - Get user notifications
- `POST /notifications/send-test` - Send test push (authenticated users)
- `DELETE /notifications/{id}?userId={id}` - Delete notification
- `POST /notifications/mark-read` - Mark as read

## Environment Variables

### Backend (.env)
```
NODE_ENV=development
PORT=3000
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_NAME=streamsync
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
YOUTUBE_API_KEY=your-youtube-api-key
YOUTUBE_CHANNEL_ID=UCuAXFkgsw1L7xaCfnd5JJOw
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
```

### Frontend (lib/core/config/app_config.dart)
```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:3000';
  static const String apiVersion = 'v1';
}
```

## Testing

### Backend
```powershell
npm test
npm run test:cov
```

### Frontend
```powershell
flutter test
flutter test --coverage
```

## Known Limitations

- FCM may not work on emulators (use physical device)
- YouTube embed requires internet connection
- Offline sync has 5-minute retry interval
- Rate limiting: 10 requests per minute per user

## Demo Video Requirements

Record 2-4 minute video showing:
1. User registration and login
2. Video feed loading from YouTube
3. Playing a video and resuming position
4. Adding video to favorites
5. Offline mode behavior
6. Receiving push notifications
7. Test Push feature in Profile tab
8. Swipe to delete notification

## GitHub Deployment

### 1. Create Repository on GitHub
- Go to github.com and create new repository
- Name it `streamsync-lite`
- Keep it public or private

### 2. Push Code to GitHub
```powershell
cd c:\STREAMSYNC
git add .
git commit -m "Initial commit: StreamSync Lite hackathon project"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/streamsync-lite.git
git push -u origin main
```

### 3. Setup GitHub Actions CI/CD

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: cd backend && npm install
      - run: cd backend && npm run build

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter analyze
```

## AWS Deployment (Updated for PM2 + NGINX)

### Prerequisites
- AWS Account with Free Tier eligibility
- AWS CLI configured
- EC2 key pair (.pem file)

### Quick Deploy (5 Steps - 15 Minutes)

**See [QUICK_DEPLOY.md](./QUICK_DEPLOY.md) for detailed 5-step guide**

#### Step 1: Store Secrets in AWS Parameter Store
```powershell
.\setup-secrets.ps1 -Region "us-east-1"
```

#### Step 2: Create AWS Resources
- RDS PostgreSQL db.t3.micro (Free Tier)
- EC2 t2.micro with Amazon Linux 2023 (Free Tier)
- Security groups for EC2 ↔ RDS communication

#### Step 3: Configure IAM Role
- Attach `AmazonSSMReadOnlyAccess` to EC2
- Attach `CloudWatchAgentServerPolicy` to EC2

#### Step 4: Deploy Application
```powershell
.\deploy.ps1 -EC2IP "your-ec2-ip" -KeyFile "your-key.pem" -RDSEndpoint "your-rds-endpoint"
```

#### Step 5: Update Flutter App
```dart
// frontend/lib/data/remote/api_client.dart
static const String baseUrl = 'http://YOUR-EC2-IP';
```

### Architecture (AWS Free Tier)

```
┌─────────────────┐
│  Flutter App    │
│  (Android APK)  │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────────────────────┐
│  EC2 t2.micro (Free Tier)       │
│  ┌───────────────────────────┐  │
│  │  NGINX (Port 80)          │  │
│  │  Reverse Proxy            │  │
│  └──────────┬────────────────┘  │
│             ▼                    │
│  ┌───────────────────────────┐  │
│  │  PM2 Process Manager      │  │
│  │  ├─ streamsync-api        │  │
│  │  └─ Auto-restart on crash │  │
│  └──────────┬────────────────┘  │
│             ▼                    │
│  ┌───────────────────────────┐  │
│  │  NestJS Backend (Node.js) │  │
│  │  Port 3000                │  │
│  └───────────────────────────┘  │
└──────────┬──────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  RDS PostgreSQL db.t3.micro      │
│  (Free Tier - 20GB Storage)      │
└──────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  AWS Systems Manager             │
│  Parameter Store (Secrets)       │
└──────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  CloudWatch Logs                 │
│  - Application Logs              │
│  - NGINX Access/Error Logs       │
└──────────────────────────────────┘
```

### Technologies Used (No Paid AWS Services)

✅ **Free Tier AWS Services:**
- EC2 t2.micro (750 hours/month - 12 months free)
- RDS db.t3.micro (750 hours/month - 12 months free)
- 20 GB RDS storage (free)
- 30 GB EBS storage (free)
- CloudWatch basic monitoring (free)
- Systems Manager Parameter Store (free)

✅ **Free External Services:**
- YouTube Data API v3 (embed videos)
- Firebase Cloud Messaging (push notifications)

❌ **NOT Using:**
- S3/CloudFront (no file storage needed)
- SNS (using Firebase FCM instead)
- Lambda (using EC2 with PM2)
- Any paid AWS features

### Process Management (PM2)

**Benefits:**
- Zero-downtime reloads
- Auto-restart on crashes
- CPU/Memory monitoring
- Log management
- Cluster mode support

**Commands:**
```bash
pm2 status                  # Check status
pm2 logs streamsync-api     # View logs
pm2 restart streamsync-api  # Restart app
pm2 reload streamsync-api   # Zero-downtime reload
pm2 monit                   # Monitor CPU/Memory
```

### Monitoring & Logging

**CloudWatch Logs:**
- `/aws/ec2/streamsync/application` - Application logs (stdout/stderr)
- `/aws/ec2/streamsync/nginx` - NGINX access/error logs

**Health Endpoint:**
```bash
curl http://your-ec2-ip/health
```

**Uptime Monitoring:**
- Cron job checks `/health` every 5 minutes
- Auto-restarts PM2 if health check fails
- CloudWatch alarms (optional)

### Frontend APK Build

```powershell
cd c:\STREAMSYNC\frontend

# Update API base URL in lib/data/remote/api_client.dart
# Change line ~15 to your AWS backend URL:
# static const String baseUrl = 'http://YOUR-EC2-IP';

# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## 📚 Documentation Files

- **[README.md](./README.md)** - This file (project overview)
- **[AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)** - Complete AWS deployment guide with all steps
- **[QUICK_DEPLOY.md](./QUICK_DEPLOY.md)** - Quick 5-step deployment (15 minutes)
- **[deploy.ps1](./deploy.ps1)** - Automated PowerShell deployment script
- **[setup-secrets.ps1](./setup-secrets.ps1)** - AWS Parameter Store setup script

## 🎯 Hackathon Requirements Checklist

### Core Requirements
- ✅ **Video Streaming** - YouTube integration with diverse content
- ✅ **User Authentication** - JWT with refresh tokens
- ✅ **Push Notifications** - Firebase Cloud Messaging
- ✅ **Test Push Feature** - In Profile screen (hackathon requirement)
- ✅ **Database** - PostgreSQL with TypeORM
- ✅ **Mobile App** - Flutter with BLoC pattern

### AWS Deployment Requirements
- ✅ **Backend** - EC2 t2.micro with PM2 process manager
- ✅ **Database** - RDS PostgreSQL db.t3.micro (Free Tier)
- ✅ **Reverse Proxy** - NGINX on EC2
- ✅ **Logging** - CloudWatch for application and NGINX logs
- ✅ **Health Monitoring** - `/health` endpoint with cron uptime checks
- ✅ **Secrets Management** - AWS Systems Manager Parameter Store (not in repo)
- ✅ **No Paid Services** - Only Free Tier AWS + Free APIs
- ✅ **YouTube Embed** - Using YouTube Data API v3 (free)
- ✅ **Firebase Push** - Using FCM (free tier)

### Security & Best Practices
- ✅ **No Secrets in Repo** - All secrets in AWS Parameter Store
- ✅ **JWT Authentication** - Secure token-based auth
- ✅ **Password Hashing** - bcrypt for secure storage
- ✅ **Rate Limiting** - 100 requests/minute per user
- ✅ **Security Headers** - Helmet middleware
- ✅ **NGINX Proxy** - Reverse proxy for better security
- ✅ **Process Management** - PM2 with auto-restart
- ✅ **IAM Roles** - Secure AWS resource access

## 💰 Cost Breakdown

### Free Tier (First 12 Months)
- EC2 t2.micro: 750 hours/month = **$0**
- RDS db.t3.micro: 750 hours/month = **$0**
- 20 GB RDS storage = **$0**
- 30 GB EBS storage = **$0**
- CloudWatch basic monitoring = **$0**
- Parameter Store (free tier) = **$0**
- **Total: $0/month**

### After Free Tier
- EC2 t2.micro: ~$8-10/month
- RDS db.t3.micro: ~$15-18/month
- Data transfer: ~$1-2/month
- **Total: ~$24-30/month**

### For Hackathon Demo
- Run for 2-3 days = **~$2-3**
- Can stop instances when not demoing
- Free Tier covers most usage

## 🔥 Quick Start Summary

```powershell
# 1. Setup AWS secrets
.\setup-secrets.ps1 -Region "us-east-1"

# 2. Deploy to AWS EC2
.\deploy.ps1 -EC2IP "your-ip" -KeyFile "your-key.pem" -RDSEndpoint "your-rds"

# 3. Update Flutter app and build APK
cd frontend
# Edit lib/data/remote/api_client.dart (line 15)
flutter build apk --release
```

**That's it! Your app is deployed on AWS Free Tier! 🚀**
