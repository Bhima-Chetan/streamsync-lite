# API Keys & Firebase Setup Guide

This guide walks you through obtaining all required API keys and credentials for StreamSync Lite.

---

## 📋 Overview

You need to set up:
1. **YouTube Data API v3** - For fetching video data
2. **Firebase Project** - For push notifications and analytics
3. **google-services.json** - For Flutter Android app

**Estimated Time:** 30 minutes

**⚠️ IMPORTANT NOTE ABOUT FCM:**
- You do **NOT** need to enable "Cloud Messaging API (Legacy)" - it's deprecated!
- If you see an error trying to enable it, **that's normal and expected**
- Our backend uses **Firebase Admin SDK** which automatically uses the modern FCM HTTP v1 API
- Just follow Steps 1-3 and Step 5 below - skip any legacy API setup

---

## 🎬 Part 1: YouTube Data API v3 (10 minutes)

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Sign in with your Google account
3. Click **Select a project** dropdown at the top
4. Click **NEW PROJECT**
5. Enter project details:
   - **Project name:** `StreamSync-Lite`
   - **Organization:** Leave as default
   - Click **CREATE**
6. Wait for project creation (10-30 seconds)

### Step 2: Enable YouTube Data API v3

1. In the Google Cloud Console, make sure your new project is selected
2. Click the **☰ Menu** (hamburger) → **APIs & Services** → **Library**
3. In the search bar, type: `YouTube Data API v3`
4. Click on **YouTube Data API v3** from the results
5. Click the **ENABLE** button
6. Wait for API to be enabled (5-10 seconds)

### Step 3: Create API Key

1. Click **☰ Menu** → **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** at the top
3. Select **API key** from the dropdown
4. A popup will show your new API key - **COPY IT IMMEDIATELY**
5. Click **EDIT API KEY** to restrict it (recommended):
   - Under **API restrictions**, select **Restrict key**
   - Check **YouTube Data API v3**
   - Click **SAVE**

### Step 4: Test Your API Key

Open a browser and test (replace `YOUR_API_KEY`):
```
https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=UCX6OQ3DkcsbYNE6H8uQQuVA&maxResults=1&order=date&key=YOUR_API_KEY
```

If you see JSON data, it works! ✅

### Step 5: Save API Key

**Copy this value** - you'll need it for `.env` file:
```
YOUTUBE_API_KEY=YOUR_ACTUAL_KEY_HERE
```

**⚠️ IMPORTANT:** 
- Never commit this key to Git
- It's already in `.gitignore`
- Free tier allows 10,000 quota units/day (enough for testing)

---

## 🔥 Part 2: Firebase Setup (15 minutes)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Sign in with your Google account
3. Click **Add project** (or **Create a project**)
4. Enter project details:
   - **Project name:** `StreamSync-Lite` (or choose unique name)
   - Click **Continue**
5. **Google Analytics** (optional):
   - Toggle OFF if you don't need it (faster setup)
   - Or select your Google Analytics account
   - Click **Create project**
6. Wait for project creation (30-60 seconds)
7. Click **Continue** when ready

### Step 2: Add Android App

1. In Firebase console, click the **Android icon** (⚙️ Gear icon → Project settings)
2. Click **Add app** → Select **Android** icon
3. Fill in the form:
   - **Android package name:** `com.streamsync.streamsync_lite`
   - **App nickname (optional):** `StreamSync Lite Android`
   - **Debug signing certificate SHA-1 (optional):** Leave blank for now
   - Click **Register app**

### Step 3: Download google-services.json

1. On the next screen, click **Download google-services.json**
2. **Save this file** - you'll need it shortly
3. Click **Next** → **Next** → **Continue to console**

### Step 4: Enable Firebase Cloud Messaging (FCM)

**Good news:** Firebase Cloud Messaging is **automatically enabled** when you create a Firebase project! 

The legacy FCM API is deprecated (and often disabled by default). We're using the modern **Firebase Admin SDK** instead, which is better and more secure.

**You can skip this step** - no additional FCM setup needed! The Firebase Admin SDK credentials from Step 5 are all you need.

### Step 5: Get Firebase Admin SDK Credentials

**Important:** This is the **only Firebase backend credential you need**. The Firebase Admin SDK uses the modern FCM HTTP v1 API automatically - no legacy setup required!

1. Still in **Project settings**, click the **Service accounts** tab
2. Click **Generate new private key** button
3. A popup appears - click **Generate key**
4. A JSON file downloads automatically - **SAVE IT SECURELY**
5. Open this JSON file in a text editor

You'll need these values from the JSON file:
```json
{
  "project_id": "your-project-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com"
}
```

### Step 6: Save Firebase Credentials

**Copy these values** for your `.env` file:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
```

**⚠️ IMPORTANT:** 
- The `private_key` must be in quotes with `\n` preserved
- Never commit this to Git
- Keep the downloaded JSON file secure

---

## 📱 Part 3: Configure Flutter App (5 minutes)

### Step 1: Place google-services.json

1. Locate the `google-services.json` file you downloaded in Part 2, Step 3
2. Copy it to your Flutter project:
   ```
   c:\STREAMSYNC\frontend\android\app\google-services.json
   ```

### Step 2: Update android/build.gradle

Open `c:\STREAMSYNC\frontend\android\build.gradle` and add:

```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        // Add this line:
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### Step 3: Update android/app/build.gradle

Open `c:\STREAMSYNC\frontend\android\app\build.gradle` and:

1. Add at the **TOP** (after `plugins` or first line):
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
// Add this line:
apply plugin: 'com.google.gms.google-services'
```

2. Update `minSdkVersion` in `defaultConfig`:
```gradle
android {
    defaultConfig {
        applicationId "com.streamsync.streamsync_lite"
        minSdkVersion 21  // Change from flutter.minSdkVersion to 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}
```

### Step 4: Update AndroidManifest.xml

Open `c:\STREAMSYNC\frontend\android\app\src\main\AndroidManifest.xml` and add permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application
        android:label="StreamSync Lite"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            ...>
            <!-- Existing intent-filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

## ✅ Part 4: Update Backend .env File

Now that you have all credentials, update your backend `.env` file:

```bash
cd c:\STREAMSYNC\backend
notepad .env
```

Paste and fill in your actual values:

```env
# Server Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=password
DB_DATABASE=streamsync

# JWT Configuration
JWT_ACCESS_SECRET=your-random-secret-key-change-this-in-production
JWT_REFRESH_SECRET=your-random-refresh-secret-key-change-this-in-production
JWT_ACCESS_EXPIRATION=1h
JWT_REFRESH_EXPIRATION=7d

# YouTube API
YOUTUBE_API_KEY=YOUR_YOUTUBE_API_KEY_FROM_PART_1

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-project-id-from-part-2
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com

# Worker Configuration
WORKER_POLL_INTERVAL=5000
WORKER_BATCH_SIZE=10
```

**Save and close the file.**

---

## 🧪 Part 5: Verify Setup

### Test Backend Configuration

```powershell
cd c:\STREAMSYNC\backend

# Install dependencies (if not done)
npm install

# Start the backend
npm run start:dev
```

Open browser to:
- http://localhost:3000/health - Should return `{"status":"ok"}`
- http://localhost:3000/api/docs - Should show Swagger API documentation

### Test Flutter Configuration

```powershell
cd c:\STREAMSYNC\frontend

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Check for errors
flutter doctor
```

You should see no errors related to Firebase or Android configuration.

---

## 📋 Checklist

Before proceeding, verify you have:

- [ ] YouTube API key saved in backend `.env`
- [ ] Firebase project created
- [ ] google-services.json in `frontend/android/app/`
- [ ] Firebase Admin SDK credentials in backend `.env`
- [ ] android/build.gradle updated with google-services plugin
- [ ] android/app/build.gradle updated (minSdkVersion 21, plugin applied)
- [ ] AndroidManifest.xml updated with permissions
- [ ] Backend starts without errors on http://localhost:3000
- [ ] Flutter pub get runs without errors

---

## 🐛 Troubleshooting

### "FCM Legacy API won't enable" or "Cloud Messaging API disabled"
**Solution:** You don't need the legacy API! 
- The backend uses **Firebase Admin SDK** (modern HTTP v1 API)
- Legacy API is deprecated since June 2023
- Just ensure you completed Step 5 (Firebase Admin SDK credentials)
- The Admin SDK automatically uses the latest FCM API

### "API key not valid" error
- Check that YouTube Data API v3 is enabled in Google Cloud Console
- Verify API key has no typos in `.env`
- Wait 5-10 minutes for API activation

### "Default FirebaseApp is not initialized"
- Check `google-services.json` is in correct location: `android/app/`
- Verify package name matches: `com.streamsync.streamsync_lite`
- Run `flutter clean` and `flutter pub get`

### "Execution failed for task ':app:processDebugGoogleServices'"
- Ensure `google-services` plugin is applied in `android/app/build.gradle`
- Check `google-services.json` is valid JSON (not corrupted)

### Backend crashes with Firebase error
- Verify `FIREBASE_PRIVATE_KEY` is wrapped in quotes: `"-----BEGIN..."`
- Check that `\n` characters are preserved in the private key
- Ensure all three Firebase env vars are set

---

## 🎯 Next Steps

Now that APIs are configured:

1. ✅ **Backend is ready** - You can test endpoints at http://localhost:3000/api/docs
2. ✅ **Flutter Firebase is configured** - Ready for FCM integration
3. 🎯 **Next: Implement UI Screens** - See IMPLEMENTATION_GUIDE.md Step 8
4. 🎯 **Then: Implement Firebase Messaging** - See IMPLEMENTATION_GUIDE.md Step 7

---

## 🔒 Security Reminders

- ❌ **NEVER** commit `.env` files to Git
- ❌ **NEVER** commit Firebase service account JSON to Git  
- ❌ **NEVER** hardcode API keys in source code
- ✅ **ALWAYS** use environment variables
- ✅ **ALWAYS** add secrets to `.gitignore`
- ✅ **ALWAYS** use API key restrictions in production

---

## 📚 Additional Resources

- [YouTube API Documentation](https://developers.google.com/youtube/v3)
- [Firebase Console](https://console.firebase.google.com)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Setup](https://firebase.google.com/docs/flutter/setup)

---

**You're all set! 🚀** Proceed to implementing the UI screens next.
