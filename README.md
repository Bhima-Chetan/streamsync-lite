# StreamSync Lite

> A real-time video streaming platform with intelligent synchronization, offline support, and push notifications.

## Table of Contents

- [System Architecture](#system-architecture)
- [Technical Stack](#technical-stack)
- [Core Algorithms](#core-algorithms)
- [Database Schema](#database-schema)
- [API Architecture](#api-architecture)
- [Deployment Architecture](#deployment-architecture)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [API Documentation](#api-documentation)
- [Environment Configuration](#environment-configuration)

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Client Layer (Flutter)                       │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Presentation │  │  Business    │  │   Data Layer       │   │
│  │   (BLoC)     │→ │   Logic      │→ │ (Repository/ORM)   │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│         │                                      │                 │
│         │                                      ↓                 │
│         │                           ┌──────────────────┐        │
│         │                           │  Local Database  │        │
│         │                           │  (SQLite/Drift)  │        │
│         │                           └──────────────────┘        │
└─────────┼──────────────────────────────────────────────────────┘
          │
          │ HTTPS/REST API
          │
          ↓
┌─────────────────────────────────────────────────────────────────┐
│              Application Server (NestJS/Node.js)                 │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐    │
│  │   Auth   │  │  Videos  │  │  Users   │  │    Push    │    │
│  │  Service │  │  Service │  │  Service │  │  Notifs    │    │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘    │
│        │             │             │              │             │
│        └─────────────┴─────────────┴──────────────┘             │
│                          │                                       │
│                          ↓                                       │
│              ┌──────────────────────┐                          │
│              │   Data Access Layer  │                          │
│              │    (TypeORM/SQL)     │                          │
│              └──────────────────────┘                          │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│                  Data Layer (PostgreSQL)                         │
│                                                                  │
│  ┌────────┐  ┌────────┐  ┌──────────┐  ┌──────────────┐      │
│  │ Users  │  │ Videos │  │ Progress │  │ Notifications │      │
│  └────────┘  └────────┘  └──────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
          │                                    │
          │                                    │
          ↓                                    ↓
┌──────────────────────┐          ┌─────────────────────────┐
│  YouTube Data API v3 │          │  Firebase Cloud         │
│  (Video Metadata)    │          │  Messaging (FCM)        │
└──────────────────────┘          └─────────────────────────┘
```

### Component Interaction Flow

```
┌────────────┐
│   Client   │
└──────┬─────┘
       │
       │ 1. User Request
       ↓
┌──────────────┐
│   API Layer  │
│  (NestJS)    │
└──────┬───────┘
       │
       │ 2. Validate & Authenticate
       ↓
┌──────────────┐
│ Auth Guard   │
└──────┬───────┘
       │
       │ 3. Route to Service
       ↓
┌──────────────┐       ┌──────────────┐
│   Service    │──────→│  Repository  │
│   Layer      │←──────│   Pattern    │
└──────┬───────┘       └──────────────┘
       │
       │ 4. Query Database
       ↓
┌──────────────┐
│  TypeORM +   │
│  PostgreSQL  │
└──────┬───────┘
       │
       │ 5. Return Data
       ↓
┌──────────────┐
│   Response   │
│ Serialization│
└──────┬───────┘
       │
       │ 6. Send to Client
       ↓
┌────────────┐
│   Client   │
└────────────┘
```

---

## Technical Stack

### Backend Technologies

```
┌──────────────────────────────────────────────────┐
│                  Runtime                         │
│  Node.js 18.20.8 (LTS) + TypeScript 5.1.3       │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│              Framework Layer                      │
│  NestJS 10.x (Enterprise-grade framework)        │
│  - Modular architecture                          │
│  - Dependency injection                          │
│  - Middleware pipeline                           │
│  - Exception filters                             │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│              Core Libraries                       │
│  - TypeORM 0.3.17 (ORM)                          │
│  - Passport JWT (Authentication)                 │
│  - Class Validator (DTO validation)              │
│  - Firebase Admin SDK (Push notifications)       │
│  - Axios (HTTP client for YouTube API)           │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│             Database Layer                        │
│  PostgreSQL 15.x                                 │
│  - ACID compliance                               │
│  - JSON support                                  │
│  - Full-text search                              │
│  - uuid-ossp extension                           │
└──────────────────────────────────────────────────┘
```

### Frontend Technologies

```
┌──────────────────────────────────────────────────┐
│              Framework                            │
│  Flutter 3.x (Cross-platform mobile)             │
│  Dart 3.x                                        │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│          State Management                         │
│  - BLoC Pattern (flutter_bloc 8.x)               │
│  - Provider (dependency injection)               │
│  - GetIt (service locator)                       │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│            Data Layer                             │
│  - Drift (Local SQLite ORM)                      │
│  - Dio (HTTP client)                             │
│  - Retrofit (Type-safe API)                      │
└──────────────────────────────────────────────────┘
                      │
                      ↓
┌──────────────────────────────────────────────────┐
│          External Services                        │
│  - Firebase Cloud Messaging                      │
│  - YouTube Player                                │
│  - Cached Network Images                         │
└──────────────────────────────────────────────────┘
```

---

## Core Algorithms

### 1. JWT Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│              User Registration & Login                   │
└─────────────────────────────────────────────────────────┘

INPUT: { email, password, name }
OUTPUT: { accessToken, refreshToken, user }

ALGORITHM RegisterUser:
  1. Validate input (email format, password strength)
  2. Check if email exists in database
     IF exists THEN
       THROW ConflictException("Email already registered")
     END IF
  
  3. Hash password using bcrypt (10 salt rounds)
     hashedPassword ← bcrypt.hash(password, 10)
  
  4. Create user record
     user ← CREATE User {
       id: uuid(),
       email: email,
       name: name,
       password: hashedPassword,
       createdAt: NOW()
     }
  
  5. Generate JWT tokens
     accessToken ← jwt.sign({
       sub: user.id,
       email: user.email
     }, JWT_SECRET, { expiresIn: '15m' })
     
     refreshToken ← jwt.sign({
       sub: user.id,
       email: user.email
     }, JWT_REFRESH_SECRET, { expiresIn: '7d' })
  
  6. RETURN { accessToken, refreshToken, user }
END ALGORITHM

TIME COMPLEXITY: O(1) - constant time database operations
SPACE COMPLEXITY: O(1) - fixed size tokens
```

### 2. Video Synchronization Algorithm

```
┌─────────────────────────────────────────────────────────┐
│         Playback Progress Tracking & Resume              │
└─────────────────────────────────────────────────────────┘

INPUT: { userId, videoId, currentTime, duration }
OUTPUT: Boolean (success/failure)

ALGORITHM TrackProgress:
  1. Validate input parameters
     IF currentTime < 0 OR currentTime > duration THEN
       THROW BadRequestException("Invalid time range")
     END IF
  
  2. Calculate progress percentage
     progressPercent ← (currentTime / duration) × 100
  
  3. Check existing progress record
     existingProgress ← FIND Progress WHERE
       userId = userId AND videoId = videoId
  
  4. Update or create progress
     IF existingProgress EXISTS THEN
       UPDATE Progress SET {
         currentTime: currentTime,
         duration: duration,
         progressPercent: progressPercent,
         lastWatched: NOW()
       } WHERE id = existingProgress.id
     ELSE
       CREATE Progress {
         id: uuid(),
         userId: userId,
         videoId: videoId,
         currentTime: currentTime,
         duration: duration,
         progressPercent: progressPercent,
         lastWatched: NOW()
       }
     END IF
  
  5. IF progressPercent >= 95 THEN
       Mark video as completed
       Trigger completion notification job
     END IF
  
  6. RETURN true
END ALGORITHM

TIME COMPLEXITY: O(1) - single database query/update
SPACE COMPLEXITY: O(1) - fixed record size
```

### 3. Push Notification Queue Algorithm

```
┌─────────────────────────────────────────────────────────┐
│          Notification Queue Processing                   │
└─────────────────────────────────────────────────────────┘

INPUT: { userId, title, body, data }
OUTPUT: NotificationJob

ALGORITHM QueueNotification:
  1. Retrieve user's FCM tokens
     tokens ← FIND FcmToken WHERE userId = userId AND active = true
  
  2. IF tokens.length = 0 THEN
       THROW NotFoundException("No active FCM tokens")
     END IF
  
  3. Create notification record
     notification ← CREATE Notification {
       id: uuid(),
       userId: userId,
       title: title,
       body: body,
       data: data,
       createdAt: NOW(),
       read: false
     }
  
  4. Create notification job for each token
     FOR EACH token IN tokens DO
       job ← CREATE NotificationJob {
         id: uuid(),
         notificationId: notification.id,
         fcmToken: token.token,
         status: 'pending',
         attempts: 0,
         maxAttempts: 3,
         scheduledFor: NOW()
       }
       
       ENQUEUE job TO notification_queue
     END FOR
  
  5. RETURN notification
END ALGORITHM

ALGORITHM ProcessNotificationQueue:
  WHILE true DO
    1. Dequeue pending jobs
       jobs ← FIND NotificationJob WHERE
         status = 'pending' AND
         scheduledFor <= NOW() AND
         attempts < maxAttempts
       LIMIT 100
    
    2. FOR EACH job IN jobs DO
         TRY
           result ← firebase.send({
             token: job.fcmToken,
             notification: {
               title: job.notification.title,
               body: job.notification.body
             },
             data: job.notification.data
           })
           
           UPDATE job SET {
             status: 'sent',
             sentAt: NOW()
           }
         
         CATCH error
           UPDATE job SET {
             status: IF attempts + 1 >= maxAttempts
                    THEN 'failed'
                    ELSE 'pending',
             attempts: attempts + 1,
             lastError: error.message,
             scheduledFor: NOW() + exponentialBackoff(attempts)
           }
         END TRY
       END FOR
    
    3. SLEEP(5 seconds)
  END WHILE
END ALGORITHM

TIME COMPLEXITY: O(n) where n = number of pending jobs
SPACE COMPLEXITY: O(n) for job queue
RETRY BACKOFF: 30s, 1m, 5m (exponential)
```

### 4. Offline Synchronization Algorithm

```
┌─────────────────────────────────────────────────────────┐
│          Offline-First Data Sync Strategy                │
└─────────────────────────────────────────────────────────┘

INPUT: Connection state change
OUTPUT: Synchronized data

ALGORITHM SyncOfflineData:
  1. Monitor network connectivity
     ON CONNECTION_RESTORED:
  
  2. Get pending operations from local queue
     pendingOps ← FIND LocalOperation WHERE synced = false
     ORDER BY timestamp ASC
  
  3. Process operations in order
     FOR EACH op IN pendingOps DO
       TRY
         CASE op.type OF
           'progress':
             response ← api.saveProgress(op.data)
           
           'favorite':
             response ← api.toggleFavorite(op.data)
           
           'mark_read':
             response ← api.markNotificationRead(op.data)
         END CASE
         
         UPDATE LocalOperation SET synced = true WHERE id = op.id
         DELETE LocalOperation WHERE id = op.id
       
       CATCH error
         IF error.status = 409 THEN
           // Conflict resolution
           serverData ← api.fetchLatest(op.resourceId)
           localData ← LOCAL_DB.get(op.resourceId)
           
           resolvedData ← RESOLVE_CONFLICT(localData, serverData)
           LOCAL_DB.update(op.resourceId, resolvedData)
           
           UPDATE LocalOperation SET synced = true WHERE id = op.id
         ELSE IF error.status >= 500 THEN
           // Server error - retry later
           UPDATE LocalOperation SET
             retryCount = retryCount + 1,
             nextRetry = NOW() + RETRY_DELAY(retryCount)
           WHERE id = op.id
         END IF
       END TRY
     END FOR
  
  4. Fetch updates from server
     lastSync ← GET last_sync_timestamp FROM LocalStorage
     
     updates ← api.getUpdates({
       since: lastSync,
       userId: currentUser.id
     })
     
     FOR EACH update IN updates DO
       LOCAL_DB.upsert(update.resourceType, update.data)
     END FOR
     
     SET last_sync_timestamp = NOW() IN LocalStorage
  
  5. RETURN sync_status
END ALGORITHM

CONFLICT RESOLUTION STRATEGY:
  FUNCTION RESOLVE_CONFLICT(local, server):
    IF local.updatedAt > server.updatedAt THEN
      // Local changes are newer
      RETURN local
    ELSE IF server.updatedAt > local.updatedAt THEN
      // Server changes are newer
      RETURN server
    ELSE
      // Timestamps equal - merge based on business rules
      RETURN MERGE(local, server)
    END IF
  END FUNCTION

TIME COMPLEXITY: O(n) where n = pending operations
SPACE COMPLEXITY: O(m) where m = local database size
SYNC INTERVAL: On connection restore + every 5 minutes
```

### 5. Video Feed Caching Algorithm

```
┌─────────────────────────────────────────────────────────┐
│          LRU Cache for Video Metadata                    │
└─────────────────────────────────────────────────────────┘

CACHE_SIZE = 100 videos
TTL = 1 hour

DATA STRUCTURE:
  cache = {
    map: HashMap<videoId, CacheEntry>,
    list: DoublyLinkedList<videoId>,
    maxSize: 100
  }
  
  CacheEntry = {
    data: VideoMetadata,
    timestamp: number,
    accessCount: number
  }

ALGORITHM GetVideo(videoId):
  1. Check cache
     IF cache.map.has(videoId) THEN
       entry ← cache.map.get(videoId)
       
       // Check TTL
       IF NOW() - entry.timestamp < TTL THEN
         // Cache hit
         cache.list.moveToFront(videoId)
         entry.accessCount++
         RETURN entry.data
       ELSE
         // Expired - remove from cache
         cache.map.delete(videoId)
         cache.list.remove(videoId)
       END IF
     END IF
  
  2. Cache miss - fetch from API
     videoData ← youtube.getVideo(videoId)
     
  3. Add to cache
     IF cache.map.size >= CACHE_SIZE THEN
       // Evict least recently used
       lruVideoId ← cache.list.tail
       cache.map.delete(lruVideoId)
       cache.list.remove(lruVideoId)
     END IF
     
     cache.map.set(videoId, {
       data: videoData,
       timestamp: NOW(),
       accessCount: 1
     })
     cache.list.addToFront(videoId)
  
  4. RETURN videoData
END ALGORITHM

TIME COMPLEXITY:
  - Cache Hit: O(1)
  - Cache Miss: O(1) + API call
  - Eviction: O(1)
SPACE COMPLEXITY: O(n) where n = CACHE_SIZE
HIT RATIO: ~85% for typical usage patterns
```

---

## Database Schema

### Entity Relationship Diagram

```
┌──────────────────────┐
│       Users          │
├──────────────────────┤
│ id (PK)             │
│ email (unique)      │
│ name                │
│ password (hashed)   │
│ createdAt           │
│ updatedAt           │
└──────────┬───────────┘
           │
           │ 1
           │
           │ *
┌──────────┴───────────┐      ┌──────────────────────┐
│     FcmTokens        │      │       Videos         │
├──────────────────────┤      ├──────────────────────┤
│ id (PK)             │      │ id (PK)             │
│ userId (FK)         │      │ videoId (unique)    │
│ token               │      │ title               │
│ platform            │      │ description         │
│ active              │      │ thumbnailUrl        │
│ createdAt           │      │ channelTitle        │
│ updatedAt           │      │ publishedAt         │
└─────────────────────┘      │ duration            │
                              │ viewCount           │
                              │ createdAt           │
                              └──────────┬───────────┘
                                         │
           ┌─────────────────────────────┼────────────────────┐
           │                             │                    │
           │ *                           │ *                  │ *
┌──────────┴───────────┐    ┌────────────┴────────┐ ┌────────┴──────────┐
│     Progress         │    │     Favorites       │ │   Notifications   │
├──────────────────────┤    ├─────────────────────┤ ├───────────────────┤
│ id (PK)             │    │ id (PK)            │ │ id (PK)          │
│ userId (FK)         │    │ userId (FK)        │ │ userId (FK)      │
│ videoId (FK)        │    │ videoId (FK)       │ │ title            │
│ currentTime         │    │ createdAt          │ │ body             │
│ duration            │    └─────────────────────┘ │ data (JSON)      │
│ progressPercent     │                            │ read             │
│ lastWatched         │                            │ createdAt        │
│ createdAt           │                            └──────────┬────────┘
│ updatedAt           │                                       │
└─────────────────────┘                                       │ 1
                                                              │
                                                              │ *
                                                   ┌──────────┴────────────┐
                                                   │   NotificationJobs    │
                                                   ├───────────────────────┤
                                                   │ id (PK)              │
                                                   │ notificationId (FK)  │
                                                   │ fcmToken             │
                                                   │ status               │
                                                   │ attempts             │
                                                   │ maxAttempts          │
                                                   │ scheduledFor         │
                                                   │ sentAt               │
                                                   │ lastError            │
                                                   │ createdAt            │
                                                   └───────────────────────┘
```

### SQL Schema Definitions

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Videos table
CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  video_id VARCHAR(255) UNIQUE NOT NULL,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  thumbnail_url VARCHAR(500),
  channel_title VARCHAR(255),
  published_at TIMESTAMP,
  duration INTEGER,
  view_count BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_videos_video_id ON videos(video_id);
CREATE INDEX idx_videos_published_at ON videos(published_at DESC);

-- Progress table
CREATE TABLE progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  current_time INTEGER NOT NULL DEFAULT 0,
  duration INTEGER NOT NULL DEFAULT 0,
  progress_percent DECIMAL(5,2) DEFAULT 0,
  last_watched TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, video_id)
);

CREATE INDEX idx_progress_user_id ON progress(user_id);
CREATE INDEX idx_progress_last_watched ON progress(last_watched DESC);

-- Favorites table
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, video_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);

-- FCM Tokens table
CREATE TABLE fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) NOT NULL UNIQUE,
  platform VARCHAR(50) NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_active ON fcm_tokens(active);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Notification Jobs table
CREATE TABLE notification_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  fcm_token VARCHAR(500) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  scheduled_for TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sent_at TIMESTAMP,
  last_error TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_jobs_status ON notification_jobs(status);
CREATE INDEX idx_notification_jobs_scheduled_for ON notification_jobs(scheduled_for);
```

---

## API Architecture

### RESTful Endpoint Structure

```
┌─────────────────────────────────────────────────────────┐
│                    API Gateway                           │
│              http://api.streamsync.com                   │
└─────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ↓                ↓                ↓
┌────────────────┐ ┌────────────┐ ┌──────────────┐
│   /auth/*      │ │  /users/*  │ │  /videos/*   │
└────────────────┘ └────────────┘ └──────────────┘
         │                │                │
         │                │                │
    ┌────┴────┐      ┌────┴────┐     ┌────┴────┐
    │         │      │         │     │         │
    ↓         ↓      ↓         ↓     ↓         ↓
  POST      POST    POST     DELETE  GET      POST
register   login   fcmToken fcmToken latest  progress
  │         │        │         │       │         │
  ↓         ↓        ↓         ↓       ↓         ↓
┌─────────────────────────────────────────────────┐
│            Authentication Middleware             │
│  - JWT validation                               │
│  - Rate limiting                                │
│  - Request logging                              │
└─────────────────────────────────────────────────┘
```

### Request/Response Flow

```
CLIENT REQUEST:
  POST /api/auth/login
  Headers: {
    Content-Type: application/json
  }
  Body: {
    email: "user@example.com",
    password: "securePassword123"
  }

↓ Middleware Pipeline

1. CORS Middleware
   - Validate origin
   - Set CORS headers

2. Helmet Middleware
   - Security headers
   - XSS protection

3. Body Parser
   - Parse JSON payload
   - Validate content-type

4. Request Logger
   - Log request details
   - Generate request ID

↓ Controller Layer

5. AuthController.login()
   - Validate DTO
   - Call AuthService

↓ Service Layer

6. AuthService.validateUser()
   - Find user by email
   - Compare passwords (bcrypt)

7. AuthService.generateTokens()
   - Create access token (15m)
   - Create refresh token (7d)

↓ Response Serialization

8. Transform response
   - Exclude sensitive fields
   - Format timestamps

↓ Send Response

SERVER RESPONSE:
  Status: 200 OK
  Headers: {
    Content-Type: application/json
    X-Request-ID: uuid
  }
  Body: {
    accessToken: "eyJhbGc...",
    refreshToken: "eyJhbGc...",
    user: {
      id: "uuid",
      email: "user@example.com",
      name: "User Name"
    }
  }
```

---

## Deployment Architecture

### AWS Free Tier Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Gateway                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ HTTPS/HTTP
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                  VPC (Virtual Private Cloud)                 │
│                      us-east-1                               │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Public Subnet (us-east-1a)                    │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────┐    │ │
│  │  │  EC2 Instance (t2.micro)                     │    │ │
│  │  │  Amazon Linux 2023                           │    │ │
│  │  │                                              │    │ │
│  │  │  ┌────────────────────────────────┐         │    │ │
│  │  │  │  NGINX (Port 80/443)          │         │    │ │
│  │  │  │  Reverse Proxy                │         │    │ │
│  │  │  └──────────┬─────────────────────┘         │    │ │
│  │  │             │                                │    │ │
│  │  │             ↓                                │    │ │
│  │  │  ┌────────────────────────────────┐         │    │ │
│  │  │  │  PM2 Process Manager          │         │    │ │
│  │  │  │  - Auto-restart               │         │    │ │
│  │  │  │  - Load balancing             │         │    │ │
│  │  │  │  - Log management             │         │    │ │
│  │  │  └──────────┬─────────────────────┘         │    │ │
│  │  │             │                                │    │ │
│  │  │             ↓                                │    │ │
│  │  │  ┌────────────────────────────────┐         │    │ │
│  │  │  │  NestJS Application           │         │    │ │
│  │  │  │  Node.js 18.20.8              │         │    │ │
│  │  │  │  Port: 3000                   │         │    │ │
│  │  │  └────────────────────────────────┘         │    │ │
│  │  │                                              │    │ │
│  │  └──────────────────────────────────────────────┘    │ │
│  │                          │                            │ │
│  └──────────────────────────┼────────────────────────────┘ │
│                             │                              │
│                             │ PostgreSQL Protocol          │
│                             │ (Port 5432)                  │
│                             │                              │
│  ┌──────────────────────────┼────────────────────────────┐ │
│  │      Private Subnet (us-east-1b)                      │ │
│  │                          │                            │ │
│  │                          ↓                            │ │
│  │  ┌─────────────────────────────────────────────┐    │ │
│  │  │  RDS PostgreSQL (db.t4g.micro)              │    │ │
│  │  │  - 20 GB Storage (gp3)                      │    │ │
│  │  │  - Automated backups (7 days)               │    │ │
│  │  │  - Multi-AZ: No (Free Tier)                 │    │ │
│  │  │  - Encryption: SSL/TLS required             │    │ │
│  │  └─────────────────────────────────────────────┘    │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                      │
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              AWS Systems Manager (SSM)                       │
│              Parameter Store                                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Encrypted Parameters (SecureString)               │    │
│  │  - /streamsync/prod/database/password             │    │
│  │  - /streamsync/prod/jwt/secret                    │    │
│  │  - /streamsync/prod/youtube/api-key               │    │
│  │  - /streamsync/prod/firebase/private-key          │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              CloudWatch Logs & Metrics                       │
│  - /aws/ec2/streamsync/app (Application logs)               │
│  - /aws/ec2/streamsync/nginx (NGINX logs)                   │
│  - CPU, Memory, Disk metrics                                │
└─────────────────────────────────────────────────────────────┘
```

### Security Groups Configuration

```
EC2 Security Group (sg-01d2bbbf4c8a7865c)
┌─────────────────────────────────────────┐
│  Inbound Rules:                         │
│  - Port 80 (HTTP): 0.0.0.0/0           │
│  - Port 443 (HTTPS): 0.0.0.0/0         │
│  - Port 22 (SSH): Your IP only         │
│                                         │
│  Outbound Rules:                        │
│  - All traffic: 0.0.0.0/0              │
└─────────────────────────────────────────┘
            │
            │ Allow PostgreSQL (5432)
            ↓
RDS Security Group (sg-04bd0c91266a947a4)
┌─────────────────────────────────────────┐
│  Inbound Rules:                         │
│  - Port 5432 (PostgreSQL):             │
│    Source: sg-01d2bbbf4c8a7865c        │
│                                         │
│  Outbound Rules:                        │
│  - None (database only receives)       │
└─────────────────────────────────────────┘
```

### CI/CD Pipeline

```
┌───────────────┐
│  Developer    │
│  Local Machine│
└───────┬───────┘
        │
        │ git push
        ↓
┌───────────────────────────────────┐
│  GitHub Repository                │
│  - main branch                    │
│  - feature branches               │
└───────┬───────────────────────────┘
        │
        │ webhook trigger
        ↓
┌───────────────────────────────────┐
│  GitHub Actions                   │
│  ┌─────────────────────────────┐ │
│  │  1. Lint & Format           │ │
│  │     - ESLint                │ │
│  │     - Prettier              │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │  2. Build                   │ │
│  │     - npm install           │ │
│  │     - npm run build         │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │  3. Test                    │ │
│  │     - Unit tests            │ │
│  │     - Integration tests     │ │
│  │     - Coverage report       │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │  4. Deploy to EC2           │ │
│  │     - SSH to instance       │ │
│  │     - Pull latest code      │ │
│  │     - npm install           │ │
│  │     - npm run build         │ │
│  │     - pm2 reload            │ │
│  └─────────────────────────────┘ │
└───────┬───────────────────────────┘
        │
        ↓
┌───────────────────────────────────┐
│  EC2 Production Instance          │
│  - Application running            │
│  - Zero-downtime deployment       │
└───────────────────────────────────┘
```

---

## Project Structure

```
STREAMSYNC/
│
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── typeorm.config.ts          # Database configuration with SSL
│   │   │   ├── firebase.config.ts         # Firebase Admin SDK setup
│   │   │   └── parameter-store.config.ts  # AWS SSM parameter loading
│   │   │
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   │   ├── auth.controller.ts
│   │   │   │   ├── auth.service.ts
│   │   │   │   ├── auth.module.ts
│   │   │   │   ├── dto/
│   │   │   │   │   ├── login.dto.ts
│   │   │   │   │   ├── register.dto.ts
│   │   │   │   │   └── refresh.dto.ts
│   │   │   │   ├── strategies/
│   │   │   │   │   ├── jwt.strategy.ts
│   │   │   │   │   └── jwt-refresh.strategy.ts
│   │   │   │   └── guards/
│   │   │   │       └── jwt-auth.guard.ts
│   │   │   │
│   │   │   ├── users/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── user.entity.ts
│   │   │   │   │   └── fcm-token.entity.ts
│   │   │   │   ├── users.controller.ts
│   │   │   │   ├── users.service.ts
│   │   │   │   └── users.module.ts
│   │   │   │
│   │   │   ├── videos/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── video.entity.ts
│   │   │   │   │   ├── progress.entity.ts
│   │   │   │   │   └── favorite.entity.ts
│   │   │   │   ├── dto/
│   │   │   │   │   ├── save-progress.dto.ts
│   │   │   │   │   └── toggle-favorite.dto.ts
│   │   │   │   ├── videos.controller.ts
│   │   │   │   ├── videos.service.ts
│   │   │   │   └── videos.module.ts
│   │   │   │
│   │   │   └── notifications/
│   │   │       ├── entities/
│   │   │       │   ├── notification.entity.ts
│   │   │       │   └── notification-job.entity.ts
│   │   │       ├── dto/
│   │   │       │   └── send-test-notification.dto.ts
│   │   │       ├── notifications.controller.ts
│   │   │       ├── notifications.service.ts
│   │   │       └── notifications.module.ts
│   │   │
│   │   ├── common/
│   │   │   ├── decorators/
│   │   │   │   └── current-user.decorator.ts
│   │   │   ├── filters/
│   │   │   │   └── http-exception.filter.ts
│   │   │   └── interceptors/
│   │   │       └── logging.interceptor.ts
│   │   │
│   │   ├── app.module.ts
│   │   ├── app.controller.ts
│   │   ├── app.service.ts
│   │   └── main.ts
│   │
│   ├── test/
│   │   ├── unit/
│   │   └── integration/
│   │
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .env.example
│   ├── package.json
│   ├── tsconfig.json
│   ├── nest-cli.json
│   └── ecosystem.config.js          # PM2 configuration
│
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── di/
│   │   │   │   └── injection.dart   # GetIt setup
│   │   │   ├── config/
│   │   │   │   └── app_config.dart
│   │   │   ├── constants/
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_strings.dart
│   │   │   └── theme/
│   │   │       └── app_theme.dart
│   │   │
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   ├── database.dart      # Drift database
│   │   │   │   └── dao/
│   │   │   │       ├── video_dao.dart
│   │   │   │       └── user_dao.dart
│   │   │   ├── remote/
│   │   │   │   ├── api_client.dart    # Retrofit API
│   │   │   │   └── interceptors/
│   │   │   │       ├── auth_interceptor.dart
│   │   │   │       └── logging_interceptor.dart
│   │   │   └── repositories/
│   │   │       ├── auth_repository.dart
│   │   │       ├── video_repository.dart
│   │   │       └── notification_repository.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── user.dart
│   │   │   │   ├── video.dart
│   │   │   │   └── notification.dart
│   │   │   └── entities/
│   │   │       └── ...
│   │   │
│   │   ├── presentation/
│   │   │   ├── blocs/
│   │   │   │   ├── auth/
│   │   │   │   │   ├── auth_bloc.dart
│   │   │   │   │   ├── auth_event.dart
│   │   │   │   │   └── auth_state.dart
│   │   │   │   ├── video/
│   │   │   │   │   ├── video_bloc.dart
│   │   │   │   │   ├── video_event.dart
│   │   │   │   │   └── video_state.dart
│   │   │   │   └── notification/
│   │   │   │       └── ...
│   │   │   ├── screens/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── auth/
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   └── register_screen.dart
│   │   │   │   ├── home/
│   │   │   │   │   └── home_screen.dart
│   │   │   │   ├── video/
│   │   │   │   │   └── video_player_screen.dart
│   │   │   │   └── profile/
│   │   │   │       └── profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── video_card.dart
│   │   │       └── notification_item.dart
│   │   │
│   │   └── main.dart
│   │
│   ├── android/
│   │   ├── app/
│   │   │   ├── google-services.json
│   │   │   └── build.gradle
│   │   └── build.gradle
│   │
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
├── docs/
│   ├── RDS_MIGRATION_COMPLETE.md
│   ├── RDS_MIGRATION_GUIDE.md
│   ├── DEPLOYMENT_SETUP.md
│   ├── DEPLOYMENT_CHECKLIST.md
│   └── NEXT_STEPS.md
│
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       └── frontend-ci.yml
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## Setup Instructions

### Prerequisites

- Node.js 18.x or higher
- PostgreSQL 15.x
- Flutter SDK 3.x
- Firebase project
- YouTube Data API key
- AWS account (for deployment)

### Backend Setup

1. **Clone repository**
   ```bash
   git clone https://github.com/Bhima-Chetan/streamsync-lite.git
   cd streamsync-lite/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Setup database**
   ```sql
   CREATE DATABASE streamsync;
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   ```

5. **Run migrations** (development mode auto-syncs)
   ```bash
   npm run start:dev
   ```

6. **Verify installation**
   ```bash
   curl http://localhost:3000/health
   # Expected: {"status":"ok","timestamp":"...","uptime":...}
   ```

### Frontend Setup

1. **Navigate to frontend**
   ```bash
   cd ../frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download google-services.json from Firebase Console
   - Place in android/app/google-services.json

4. **Update API endpoint**
   ```dart
   // lib/core/config/app_config.dart
   static const String apiBaseUrl = 'http://YOUR_BACKEND_URL';
   ```

5. **Run application**
   ```bash
   flutter run
   ```

### AWS Deployment

See detailed guides:
- [RDS_MIGRATION_COMPLETE.md](./RDS_MIGRATION_COMPLETE.md)
- [DEPLOYMENT_SETUP.md](./DEPLOYMENT_SETUP.md)
- [NEXT_STEPS.md](./NEXT_STEPS.md)

Quick deploy:
```bash
# On EC2 instance
git clone https://github.com/Bhima-Chetan/streamsync-lite.git
cd streamsync-lite/backend
npm install
npm run build
pm2 start ecosystem.config.js
pm2 save
```

---

## API Documentation

### Authentication Endpoints

#### POST /auth/register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "SecurePass123!"
}

Response: 201 Created
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### POST /auth/login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response: 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### POST /auth/refresh
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}

Response: 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Video Endpoints

#### GET /videos/latest
```http
GET /api/videos/latest?limit=10&channelId=UCuAXFkgsw1L7xaCfnd5JJOw
Authorization: Bearer {accessToken}

Response: 200 OK
[
  {
    "id": "uuid",
    "videoId": "dQw4w9WgXcQ",
    "title": "Video Title",
    "description": "Video description...",
    "thumbnailUrl": "https://i.ytimg.com/vi/...",
    "channelTitle": "Channel Name",
    "publishedAt": "2025-01-01T00:00:00Z",
    "duration": 240,
    "viewCount": 1000000
  }
]
```

#### POST /videos/progress
```http
POST /api/videos/progress
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "videoId": "uuid",
  "currentTime": 120,
  "duration": 240
}

Response: 201 Created
{
  "id": "uuid",
  "userId": "uuid",
  "videoId": "uuid",
  "currentTime": 120,
  "duration": 240,
  "progressPercent": 50.00
}
```

### Notification Endpoints

#### GET /notifications
```http
GET /api/notifications?userId={uuid}&limit=50
Authorization: Bearer {accessToken}

Response: 200 OK
[
  {
    "id": "uuid",
    "title": "New Video Available",
    "body": "Check out the latest upload!",
    "data": {},
    "read": false,
    "createdAt": "2025-01-01T00:00:00Z"
  }
]
```

#### POST /notifications/send-test
```http
POST /api/notifications/send-test
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "title": "Test Notification",
  "body": "This is a test message",
  "data": {
    "customKey": "value"
  }
}

Response: 201 Created
{
  "id": "uuid",
  "title": "Test Notification",
  "body": "This is a test message",
  "status": "sent"
}
```

---

## Environment Configuration

### Backend Environment Variables

```bash
# Application
NODE_ENV=production
PORT=3000

# Database (RDS)
DATABASE_HOST=streamsync-db.ckng6848ej05.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=<secure-password>
DATABASE_NAME=streamsync

# JWT Authentication
JWT_SECRET=<64-char-random-string>
JWT_REFRESH_SECRET=<64-char-random-string>
JWT_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# YouTube API
YOUTUBE_API_KEY=<your-youtube-api-key>
YOUTUBE_CHANNEL_ID=UCuAXFkgsw1L7xaCfnd5JJOw

# Firebase Admin SDK
FIREBASE_PROJECT_ID=<your-project-id>
FIREBASE_PRIVATE_KEY=<private-key-from-service-account>
FIREBASE_CLIENT_EMAIL=<service-account-email>

# AWS Systems Manager (Optional)
USE_SSM=true
AWS_REGION=us-east-1
```

### Frontend Configuration

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://3.85.120.15';
  static const String apiVersion = 'v1';
  static const int connectionTimeout = 30000; // 30s
  static const int receiveTimeout = 30000;
  
  // Cache settings
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const Duration cacheExpiry = Duration(hours: 24);
  
  // Sync settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
}
```

---

## Performance Metrics

### Expected Performance

```
Endpoint Performance (P95):
- POST /auth/login: <200ms
- GET /videos/latest: <500ms (with YouTube API)
- POST /videos/progress: <100ms
- GET /notifications: <150ms

Database Performance:
- Read queries: <50ms
- Write queries: <100ms
- Complex joins: <200ms

Cache Hit Rates:
- Video metadata: 85%
- User sessions: 95%
- API responses: 70%

Resource Usage (EC2 t2.micro):
- CPU: <30% average, <70% peak
- Memory: <512MB average, <900MB peak
- Network: <10Mbps

RDS (db.t4g.micro):
- Connections: <50 concurrent
- CPU: <40% average
- Storage: <2GB initial
```

---

## License

MIT License - See LICENSE file for details

---

## Contributors

- Bhima Chetan - Full Stack Development

---

## Documentation

- [RDS Migration Guide](./RDS_MIGRATION_COMPLETE.md)
- [Deployment Setup](./DEPLOYMENT_SETUP.md)
- [Next Steps](./NEXT_STEPS.md)
- [API Reference](http://3.85.120.15/api/docs)

---

Last Updated: November 3, 2025
