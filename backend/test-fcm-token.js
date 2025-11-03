require('dotenv').config();
const admin = require('firebase-admin');

// Initialize Firebase using environment variables (same as the app)
let privateKey = process.env.FIREBASE_PRIVATE_KEY || '';
privateKey = privateKey.replace(/^["']|["']$/g, '');
privateKey = privateKey.trim().replace(/\\+$/, '');
privateKey = privateKey.replace(/\\n/g, '\n');
privateKey = privateKey.trim();

console.log('🔑 Initializing Firebase Admin SDK...');
console.log('📧 Client Email:', process.env.FIREBASE_CLIENT_EMAIL);
console.log('🆔 Project ID:', process.env.FIREBASE_PROJECT_ID);
console.log('🔑 Private Key Length:', privateKey.length);

const app = admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: privateKey,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});

console.log('✅ Firebase initialized successfully');

// The FCM token to test
const fcmToken = 'e19-bmy5Qz-KT3isZrY_Fh:APA91bEX2xkUmeoA1NVJZig9HlDh-DNqAUR3R0aQOxym147n8zgfstnhWS-DVG5MbwckmGPSBDJaCujRCOCiIkg4GuekpQaALIaWrbbkTgw2B-ZhdcsPPXA';

// Test notification message
const message = {
  notification: {
    title: '🎉 Test Notification',
    body: 'If you see this, Firebase is working perfectly!',
  },
  data: {
    type: 'test',
    timestamp: new Date().toISOString(),
  },
  token: fcmToken,
  android: {
    notification: {
      sound: 'default',
      channelId: 'streamsync_notifications',
      priority: 'high',
    },
  },
};

console.log('\n🚀 Sending test notification...');
console.log('📱 Token:', fcmToken.substring(0, 30) + '...');

admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log('\n✅ SUCCESS! Notification sent successfully');
    console.log('📨 Message ID:', response);
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ FAILED to send notification');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  });
