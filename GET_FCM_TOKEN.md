# How to Get a Fresh FCM Token

## Issue Detected
The FCM token you provided is **not registered** with Firebase. This happens when:
- The token expired
- The app was uninstalled/reinstalled
- The token is from a different Firebase project

## Solution: Get a Fresh Token from Your App

### Method 1: From Flutter App (Recommended)

1. **Run the app** on your device:
   ```bash
   cd C:\STREAMSYNC\frontend
   flutter run
   ```

2. **Check the console logs** when the app starts. You'll see:
   ```
   🔔 FCM Token: e19-bmy5Qz-KT3isZrY_Fh:APA91b...
   ```

3. **Copy the full token** from the console

### Method 2: Test on Emulator

1. **Launch Android emulator**:
   ```bash
   cd C:\STREAMSYNC\frontend
   flutter emulators --launch Pixel_8_Pro
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Copy the token** from console logs

### Method 3: Check App Login

1. **Login to the app** on your device
2. The app automatically registers the FCM token with backend
3. Go to **Profile → Test Push Notification**
4. Enter title and message
5. Click "Send Test Push"

## Common Issues

### Token Not Registered Error
```
messaging/registration-token-not-registered
```
**Fix**: Get a fresh token using methods above

### No FCM Tokens in Database
**Fix**: Make sure you logged in to the app at least once

### Firebase Project Mismatch
**Fix**: Verify `google-services.json` in `android/app/` matches your Firebase project

## Verify Token Registration

After logging in, check if token was saved:

### Via Backend API:
```bash
# Get your user ID first
curl http://3.85.120.15/users

# Then check tokens (replace USER_ID)
curl http://3.85.120.15/users/USER_ID/tokens
```

## Test Notification Flow

1. **Login to app** → Token automatically registered
2. **Go to Profile** → Tap "Test Push Notification"
3. **Enter**: Title: "Test", Body: "Hello"
4. **Tap Send** → Should receive notification immediately

## Debug Checklist

- [ ] App is connected to correct Firebase project
- [ ] `google-services.json` is up to date
- [ ] User is logged in
- [ ] FCM token appears in console logs
- [ ] Token is registered in backend database
- [ ] Backend has correct Firebase credentials in `.env`

## Current Firebase Project
- **Project ID**: `streamsync-dccc1`
- **Client Email**: `firebase-adminsdk-fbsvc@streamsync-dccc1.iam.gserviceaccount.com`

Make sure your Flutter app's `google-services.json` matches this project!
