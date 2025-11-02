# 🧪 End-to-End Test Guide - StreamSync FCM Push Notifications

## ✅ Prerequisites Check
- [x] Backend running on `http://localhost:3000`
- [x] Worker process running (`npm run start:worker`)
- [x] Flutter app launching on device
- [x] YouTube API integration working

---

## 📱 Test Flow

### **Step 1: Login and FCM Token Registration** 🔐

**What to do:**
1. Open the app on your device
2. Login with credentials:
   - Email: `test@example.com`
   - Password: `test12345`

**What to watch for:**

**In Flutter app logs** - Look for:
```
🔵 AuthBloc._onLoginRequested called
🔵 AuthBloc: Login successful!
✅ AuthBloc: AuthAuthenticated state emitted!
🔔 AuthBloc: Registering FCM token with backend...
🔔 FCM Token: e19-bmy5Qz-KT3isZrY_Fh:APA91b...
✅ AuthBloc: FCM token registered successfully
```

**In Backend logs** (Terminal running `npm run start:dev`) - Look for:
```
[INFO] request completed {"req":{"method":"POST","url":"/users/{userId}/fcmToken"...
```

**To verify in database:**
```powershell
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -h localhost -d streamsync -c "SELECT user_id, platform, LEFT(token, 30) as token_preview FROM fcm_tokens;"
```

✅ **Success Criteria:** You should see the FCM token in the database with `user_id` matching your logged-in user.

---

### **Step 2: Navigate to Profile Screen** 👤

**What to do:**
1. Tap the **Profile** tab in bottom navigation
2. Scroll down to find the **Test Push Notifications** section (orange card with bug icon 🐛)

**What to watch for:**
- Orange card titled "🐛 Test Push Notifications"
- Two text fields: "Title" and "Body"
- Blue "Send Test Push" button
- Gray helper text about rate limiting (5 notifications per minute)

---

### **Step 3: Send Test Push Notification** 🔔

**What to do:**
1. Enter in the form:
   - **Title:** `"Test Notification"`
   - **Body:** `"This is a test push from StreamSync!"`
2. Tap **"Send Test Push"** button

**What to watch for:**

**In Flutter app:**
```
Sending test push notification...
✅ Test push sent successfully
```
- Green success toast should appear
- Button becomes disabled for a few seconds (rate limit protection)

**In Backend logs:**
```
[INFO] POST /notifications/send-test
query: INSERT INTO "notifications"...
query: INSERT INTO "notification_jobs"...
```

**In Worker logs** (Terminal running `npm run start:worker`) - Look for:
```
Processing 1 pending notification jobs...
Sending notification: Test Notification
Successfully sent notification to 1 device(s)
query: UPDATE "notification_jobs" SET "status" = 'completed'...
```

**On your device:**
- 🔔 **Notification should appear** with:
  - Title: "Test Notification"
  - Body: "This is a test push from StreamSync!"
  - App icon

✅ **Success Criteria:** Notification appears on device within 5-10 seconds

---

### **Step 4: Test Rate Limiting** ⏱️

**What to do:**
1. Quickly send 6 test pushes in a row (as fast as you can click)

**What to watch for:**

**First 5 requests:** ✅ Success toasts
**6th request:** ⚠️ Orange toast saying:
```
Rate limit exceeded. Please wait before sending another notification.
```

**In Backend logs:**
```
[WARN] ThrottlerException: Too Many Requests
```

✅ **Success Criteria:** 6th request gets blocked with 429 status

---

### **Step 5: Verify YouTube API Integration** 📺

**What to do:**
1. Navigate to **Home** tab
2. Pull down to refresh the video feed

**What to watch for:**

**In Flutter app:**
- Loading indicator appears
- Real YouTube videos load from Rick Astley's channel
- Each video shows:
  - Thumbnail
  - Title
  - View count
  - Duration
  - Published date

**In Backend logs:**
```
[INFO] GET /videos/latest
query: SELECT ... FROM "videos"...
```

✅ **Success Criteria:** Videos from YouTube appear in the feed

---

## 🔍 Debugging Commands

### Check Backend Status:
```powershell
curl http://localhost:3000/health
```

### Check FCM Tokens in Database:
```powershell
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -h localhost -d streamsync -c "SELECT * FROM fcm_tokens;"
```

### Check Notification Jobs:
```powershell
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -h localhost -d streamsync -c "SELECT id, status, retries, created_at FROM notification_jobs ORDER BY created_at DESC LIMIT 5;"
```

### Check Notifications:
```powershell
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -h localhost -d streamsync -c "SELECT title, body, sent, created_at FROM notifications ORDER BY created_at DESC LIMIT 5;"
```

---

## ✅ Success Checklist

- [ ] Login successful with FCM token registered
- [ ] FCM token appears in `fcm_tokens` table
- [ ] Profile screen shows Test Push UI
- [ ] Test notification sent successfully
- [ ] Notification appears on device
- [ ] Worker processes job (status: completed)
- [ ] Rate limiting works (6th request blocked)
- [ ] YouTube videos load in Home feed

---

## 🎉 Expected Final State

**Database:**
- ✅ 1 entry in `fcm_tokens` (your device token)
- ✅ Multiple entries in `notifications` (one per test)
- ✅ Multiple entries in `notification_jobs` (status: `completed`)

**Logs:**
- ✅ Backend: `request completed` for all endpoints
- ✅ Worker: `Successfully sent notification` messages
- ✅ Flutter: `FCM token registered successfully`

**Device:**
- ✅ Multiple test notifications in notification tray
- ✅ App works smoothly with no crashes

---

## 🐛 Troubleshooting

### Notification doesn't arrive?
1. Check worker is running: `Get-Process node`
2. Check job status: `SELECT status FROM notification_jobs ORDER BY created_at DESC LIMIT 1;`
3. Check worker logs for errors
4. Verify FCM token in database matches device token (check Flutter logs)

### "Rate limit exceeded" on first request?
- Wait 60 seconds and try again
- Rate limit is 5 requests per 60 seconds

### FCM token not registered?
- Check Flutter logs for errors during login
- Verify backend is running
- Check API endpoint: `POST /users/{userId}/fcmToken`

---

**Ready to test!** 🚀
