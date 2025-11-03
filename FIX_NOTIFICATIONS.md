# Fix Firebase Push Notifications - Quick Guide

## Problem
The FCM token `e19-bmy5Qz-KT3isZrY_Fh:APA...` is **NOT REGISTERED** with Firebase.

Error: `messaging/registration-token-not-registered`

## Root Cause
- Token expired or invalid
- Token from different Firebase project
- App was uninstalled/reinstalled

## ✅ Solution: Get Fresh Token

### Step 1: Open Your App on Physical Device

Your device **21091116AI (Android 13)** is already connected!

### Step 2: Launch the App

1. Open PowerShell in VS Code
2. Run:
   ```powershell
   cd C:\STREAMSYNC\frontend
   flutter run -d 21091116AI
   ```

3. Wait for app to launch (2-3 minutes first time)

### Step 3: Find the FCM Token

When app starts, look for this in the console:
```
🔔 FCM Token: e19-bmy5Qz-KT3isZrY_Fh:APA91b...
```

**Copy the FULL token!**

### Step 4: Login to the App

1. On your device, login with test credentials
2. The app will **automatically register** the new FCM token with backend

### Step 5: Test Push Notification

**Method A: From App (Easiest)**
1. Go to **Profile tab** (bottom right)
2. Tap **"Test Push Notification"** button
3. Enter:
   - Title: `Hello!`
   - Body: `Testing notifications!`
4. Tap **"Send Test Push"**
5. You should see notification immediately!

**Method B: From Backend Test Script**
1. Copy the new FCM token from console
2. Update `test-fcm-token.js` with new token
3. Run: `node backend/test-fcm-token.js`

## Why It's Not Working Now

The token you provided:
```
e19-bmy5Qz-KT3isZrY_Fh:APA91bEX2xkUmeoA1NVJZig9HlDh-DNqAUR3R0aQOxym147n8zgfstnhWS-DVG5MbwckmGPSBDJaCujRCOCiIkg4GuekpQaALIaWrbbkTgw2B-ZhdcsPPXA
```

Is **NOT VALID** because:
- It's expired (FCM tokens expire after ~2 months of inactivity)
- OR app was uninstalled/data cleared
- OR token wasn't properly registered

## Verification Checklist

After getting new token:

- [ ] App is running on device
- [ ] User logged in successfully
- [ ] FCM token appeared in console logs
- [ ] Test push notification works from app
- [ ] Notification appears on device

## Backend is Working! ✅

Your backend Firebase setup is **CORRECT**:
- ✅ Firebase initialized successfully
- ✅ Project ID: `streamsync-dccc1`
- ✅ Client Email: `firebase-adminsdk-fbsvc@streamsync-dccc1.iam.gserviceaccount.com`
- ✅ Private key loaded correctly (1703 chars)

**The only issue is the TOKEN itself - it's not valid!**

## Quick Test

Run this in PowerShell:
```powershell
# Launch app
cd C:\STREAMSYNC\frontend
flutter run -d 21091116AI

# Watch for "🔔 FCM Token: ..." in console
# Login to app
# Test push from Profile screen
```

## Expected Result

When working correctly:
1. App starts → FCM token printed in console
2. User logs in → Token saved to database
3. Tap "Test Push" in Profile → Notification appears immediately
4. Backend logs show: `✅ FCM Response - Success: 1, Failures: 0`

## Need Help?

If still not working:
1. Share the NEW token from console logs
2. Check backend logs: `ssh ec2 "pm2 logs streamsync-backend"`
3. Verify Firebase console: https://console.firebase.google.com/project/streamsync-dccc1
