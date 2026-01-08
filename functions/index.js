const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Send push notification to a specific user
 * 
 * Payload:
 * {
 *   "userId": "123",
 *   "title": "New Booking",
 *   "body": "You have a new booking assigned",
 *   "data": {
 *     "route": "/bookingDetails",
 *     "id": "456"
 *   }
 * }
 */
exports.sendToUser = functions.https.onCall(async (data, context) => {
  try {
    const { userId, title, body, data: customData = {} } = data;

    if (!userId || !title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: userId, title, body'
      );
    }

    // Get FCM tokens for the user
    const devicesSnapshot = await db
      .collection('user_devices')
      .where('user_id', '==', userId.toString())
      .get();

    if (devicesSnapshot.empty) {
      return { success: false, message: 'No devices found for user' };
    }

    const tokens = devicesSnapshot.docs
      .map(doc => doc.data().fcm_token)
      .filter(token => token && token.length > 0);

    if (tokens.length === 0) {
      return { success: false, message: 'No valid FCM tokens found' };
    }

    // Prepare notification payload
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...customData,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens: tokens,
    };

    // Send to all user devices
    const response = await admin.messaging().sendEachForMulticast(message);

    // Save notification to Firestore for history
    await db.collection('notifications').add({
      user_id: userId.toString(),
      title: title,
      body: body,
      data_json: customData,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });

    return {
      success: true,
      sent: response.successCount,
      failed: response.failureCount,
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Send push notification to a topic
 * 
 * Payload:
 * {
 *   "topic": "all_users" or "cleaners" or "clients",
 *   "title": "New Feature",
 *   "body": "Check out our new feature!",
 *   "data": {}
 * }
 */
exports.sendToTopic = functions.https.onCall(async (data, context) => {
  try {
    const { topic, title, body, data: customData = {} } = data;

    if (!topic || !title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: topic, title, body'
      );
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...customData,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      topic: topic,
    };

    const response = await admin.messaging().send(message);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error('Error sending to topic:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Scheduled function to send periodic notifications
 * Runs every hour (can be changed to daily, weekly, etc.)
 * 
 * Example: Send reminder to cleaners with pending jobs
 */
exports.scheduledSender = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    try {
      console.log('Scheduled notification sender running...');

      // Example: Get cleaners with pending jobs
      // This is just a template - customize based on your needs
      const jobsSnapshot = await db
        .collection('jobs')
        .where('status', '==', 'active')
        .limit(10)
        .get();

      if (jobsSnapshot.empty) {
        console.log('No active jobs to notify about');
        return null;
      }

      // Get unique user IDs who might be interested
      const userIds = new Set();
      jobsSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.agency_id) userIds.add(data.agency_id.toString());
        if (data.client_id) userIds.add(data.client_id.toString());
      });

      // Send notification to each user
      for (const userId of userIds) {
        const devicesSnapshot = await db
          .collection('user_devices')
          .where('user_id', '==', userId)
          .get();

        if (devicesSnapshot.empty) continue;

        const tokens = devicesSnapshot.docs
          .map(doc => doc.data().fcm_token)
          .filter(token => token && token.length > 0);

        if (tokens.length === 0) continue;

        const message = {
          notification: {
            title: 'New Jobs Available',
            body: `There are ${jobsSnapshot.size} active jobs waiting for you!`,
          },
          data: {
            route: '/jobs',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          tokens: tokens,
        };

        await admin.messaging().sendEachForMulticast(message);
      }

      console.log(`Sent scheduled notifications to ${userIds.size} users`);
      return null;
    } catch (error) {
      console.error('Error in scheduled sender:', error);
      return null;
    }
  });

