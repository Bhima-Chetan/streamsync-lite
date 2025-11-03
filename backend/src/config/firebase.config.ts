import * as admin from 'firebase-admin';

let firebaseApp: admin.app.App;

export const initializeFirebase = () => {
  if (!firebaseApp) {
    // Parse private key - handle both escaped and literal newlines
    let privateKey = process.env.FIREBASE_PRIVATE_KEY || '';
    
    // Remove surrounding quotes if present
    privateKey = privateKey.replace(/^["']|["']$/g, '');
    
    // Remove any trailing backslashes or whitespace
    privateKey = privateKey.trim().replace(/\\+$/, '');
    
    // Replace escaped newlines with actual newlines
    privateKey = privateKey.replace(/\\n/g, '\n');
    
    // Trim again after newline replacement to remove leading/trailing whitespace
    privateKey = privateKey.trim();
    
    console.log('🔑 Firebase private key length:', privateKey.length);
    console.log('🔑 Private key starts with:', privateKey.substring(0, 30));
    console.log('🔑 Private key ends with:', privateKey.substring(privateKey.length - 30));
    
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: privateKey,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
  }
  return firebaseApp;
};

export const getFirebaseApp = () => {
  if (!firebaseApp) {
    return initializeFirebase();
  }
  return firebaseApp;
};
