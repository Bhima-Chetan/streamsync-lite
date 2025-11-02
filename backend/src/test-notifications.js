const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Download service account key from Firebase Console:
// Project Settings → Service Accounts → Generate New Private Key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send test notification
async function sendTestNotification(fcmToken) {
  const message = {
    notification: {
      title: '🎉 Welcome to StreamSync!',
      body: 'Your notifications are working perfectly!'
    },
    data: {
      type: 'test',
      route: '/home'
    },
    token: fcmToken
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Successfully sent message:', response);
  } catch (error) {
    console.log('❌ Error sending message:', error);
  }
}

// Send video notification
async function sendVideoNotification(fcmToken, videoId, videoTitle) {
  const message = {
    notification: {
      title: '📹 New Video Available',
      body: videoTitle
    },
    data: {
      type: 'new_video',
      videoId: videoId,
      route: '/video-player'
    },
    token: fcmToken,
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#FF5722',
        sound: 'default',
        channelId: 'streamsync_notifications'
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Successfully sent video notification:', response);
  } catch (error) {
    console.log('❌ Error sending notification:', error);
  }
}

// Send to topic (all users)
async function sendToTopic(topic, title, body) {
  const message = {
    notification: {
      title: title,
      body: body
    },
    topic: topic
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Successfully sent to topic:', response);
  } catch (error) {
    console.log('❌ Error sending to topic:', error);
  }
}

// Usage examples (uncomment to use):

// Test notification to a specific device
// const fcmToken = 'PASTE_FCM_TOKEN_FROM_FLUTTER_CONSOLE_HERE';
// sendTestNotification(fcmToken);

// Send video notification
// sendVideoNotification(fcmToken, 'dQw4w9WgXcQ', 'Flutter Tutorial - Complete Course');

// Send to all users subscribed to topic
// sendToTopic('all_users', 'New Update!', 'StreamSync has new features!');

module.exports = {
  sendTestNotification,
  sendVideoNotification,
  sendToTopic
};
