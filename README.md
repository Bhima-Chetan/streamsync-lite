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

## AWS Deployment

### Option 1: AWS Elastic Beanstalk (Recommended)

#### Deploy Backend

1. **Install EB CLI**
```powershell
pip install awsebcli
```

2. **Initialize EB**
```powershell
cd c:\STREAMSYNC\backend
eb init -p node.js-18 streamsync-backend --region us-east-1
```

3. **Create .ebextensions/options.config**
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    PORT: 8080
  aws:elasticbeanstalk:container:nodejs:
    NodeCommand: "npm start"
```

4. **Create environment and deploy**
```powershell
eb create streamsync-backend-env
eb deploy
```

5. **Set environment variables**
```powershell
eb setenv DATABASE_HOST=your-rds-endpoint `
  DATABASE_PORT=5432 `
  DATABASE_USER=postgres `
  DATABASE_PASSWORD=yourpassword `
  DATABASE_NAME=streamsync `
  JWT_SECRET=yoursecret `
  YOUTUBE_API_KEY=yourkey `
  FIREBASE_PROJECT_ID=yourproject `
  FIREBASE_PRIVATE_KEY="yourkey" `
  FIREBASE_CLIENT_EMAIL=youremail
```

#### Setup RDS Database

1. **Create RDS Instance**
```powershell
aws rds create-db-instance `
  --db-instance-identifier streamsync-db `
  --db-instance-class db.t3.micro `
  --engine postgres `
  --master-username postgres `
  --master-user-password YourPassword123 `
  --allocated-storage 20 `
  --publicly-accessible
```

2. **Get RDS endpoint**
```powershell
aws rds describe-db-instances `
  --db-instance-identifier streamsync-db `
  --query 'DBInstances[0].Endpoint.Address'
```

### Option 2: AWS EC2 Manual Deployment

#### 1. Launch EC2 Instance

```powershell
# Launch t3.small instance with Amazon Linux 2023
aws ec2 run-instances `
  --image-id ami-0c55b159cbfafe1f0 `
  --instance-type t3.small `
  --key-name your-key-pair `
  --security-group-ids sg-xxxxxx `
  --subnet-id subnet-xxxxxx
```

#### 2. SSH into EC2 and setup

```bash
# Connect to EC2
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git

# Install PM2
sudo npm install -g pm2

# Clone repository
git clone https://github.com/YOUR_USERNAME/streamsync-lite.git
cd streamsync-lite/backend

# Install dependencies
npm install

# Create .env file
nano .env
# Paste your environment variables

# Build
npm run build

# Start with PM2
pm2 start dist/main.js --name streamsync-api
pm2 start dist/worker.js --name streamsync-worker
pm2 startup
pm2 save
```

#### 3. Setup Nginx

```bash
sudo yum install nginx -y
sudo nano /etc/nginx/conf.d/streamsync.conf
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 4. Setup SSL (Optional)

```bash
sudo yum install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

### Frontend APK Build

```powershell
cd c:\STREAMSYNC\frontend

# Update API base URL in lib/core/config/app_config.dart
# Change to your AWS backend URL

# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## License

MIT License - Hackathon Project
