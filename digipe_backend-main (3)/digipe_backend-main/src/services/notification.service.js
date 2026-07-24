const admin = require('firebase-admin');
const env = require('../config/env');
const logger = require('../config/logger');

let firebaseInitialized = false;

/**
 * Initialize Firebase Admin SDK if credentials are available.
 * This is called lazily on first notification attempt.
 */
const initFirebase = () => {
  if (firebaseInitialized) return true;

  if (!env.firebase.projectId || !env.firebase.clientEmail || !env.firebase.privateKey) {
    logger.warn('Firebase not configured — push notifications disabled. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY in .env');
    return false;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.firebase.projectId,
        clientEmail: env.firebase.clientEmail,
        privateKey: env.firebase.privateKey,
      }),
    });
    firebaseInitialized = true;
    logger.info('Firebase Admin SDK initialized successfully');
    return true;
  } catch (error) {
    logger.error(`Firebase initialization failed: ${error.message}`);
    return false;
  }
};

/**
 * Send a push notification to a single device.
 *
 * @param {string} fcmToken - The FCM device token
 * @param {Object} payload - { title, body, data, imageUrl }
 * @returns {Object|null} FCM response or null if failed
 */
const sendToDevice = async (fcmToken, { title, body, data = {}, imageUrl = null }) => {
  if (!initFirebase()) {
    logger.warn('Skipping notification — Firebase not initialized');
    return null;
  }

  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
      ...(imageUrl && { imageUrl }),
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    webpush: {
      fcmOptions: {
        link: data.deepLink || undefined,
      },
      notification: {
        icon: '/icon-192.png',
        badge: '/badge-72.png',
        ...(imageUrl && { image: imageUrl }),
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    logger.debug(`FCM sent to ${fcmToken.slice(0, 20)}...: ${response}`);
    return response;
  } catch (error) {
    logger.error(`FCM send failed for token ${fcmToken.slice(0, 20)}...: ${error.message}`);
    // If token is invalid/expired, the caller should remove it
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      return { error: 'INVALID_TOKEN', token: fcmToken };
    }
    return null;
  }
};

/**
 * Send a push notification to multiple devices (batch).
 *
 * @param {string[]} fcmTokens - Array of FCM device tokens
 * @param {Object} payload - { title, body, data, imageUrl }
 * @returns {{ successCount: number, failureCount: number, invalidTokens: string[] }}
 */
const sendToMultipleDevices = async (fcmTokens, { title, body, data = {}, imageUrl = null }) => {
  if (!initFirebase()) {
    logger.warn('Skipping bulk notification — Firebase not initialized');
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  if (!fcmTokens || fcmTokens.length === 0) {
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const message = {
    notification: {
      title,
      body,
      ...(imageUrl && { imageUrl }),
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
  };

  // FCM sendEachForMulticast handles up to 500 tokens per call
  const batchSize = 500;
  let successCount = 0;
  let failureCount = 0;
  const invalidTokens = [];

  for (let i = 0; i < fcmTokens.length; i += batchSize) {
    const batch = fcmTokens.slice(i, i + batchSize);

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch,
        ...message,
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          if (
            resp.error.code === 'messaging/invalid-registration-token' ||
            resp.error.code === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(batch[idx]);
          }
        }
      });
    } catch (error) {
      logger.error(`FCM batch send failed: ${error.message}`);
      failureCount += batch.length;
    }
  }

  logger.info(`FCM bulk send: ${successCount} success, ${failureCount} failed, ${invalidTokens.length} invalid tokens`);
  return { successCount, failureCount, invalidTokens };
};

module.exports = {
  initFirebase,
  sendToDevice,
  sendToMultipleDevices,
};
