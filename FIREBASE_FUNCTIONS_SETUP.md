# Firebase Notifications Setup Guide (FREE - No Cloud Functions Required!)

## ✅ FREE Solution - Direct FCM API

**Good news!** You don't need Cloud Functions (which require Blaze plan). 
Notifications now work directly from your Flutter app using FCM HTTP API.

## How It Works

The `NotificationBackendService` sends notifications directly via FCM HTTP API:
- ✅ **FREE** - Works on Firebase Spark (free) plan
- ✅ No Cloud Functions deployment needed
- ✅ No Blaze plan upgrade required
- ⚠️ FCM Server Key is in client code (OK for development, consider alternatives for production)

## Setup Steps

**No setup needed!** Everything is already configured:
1. FCM Server Key is stored in `NotificationBackendService` and `NotificationsRepoDB`
2. Service automatically reads FCM tokens from Firestore `user_devices` collection
3. Notifications are saved to Firestore `notifications` collection

## Available Methods

### 1. sendToUser
Send notification to a specific user by userId.

**Call from Flutter:**
```dart
final result = await NotificationBackendService.sendToUser(
  userId: '123',
  title: 'New Booking',
  body: 'You have a new booking assigned',
  route: '/bookingDetails',
  id: '456',
);
```

**How it works:**
- Reads FCM tokens from Firestore `user_devices` collection for the user
- Sends notification to all user's devices via FCM HTTP API
- Saves notification history to Firestore `notifications` collection

### 2. sendToTopic
Send notification to all users subscribed to a topic.

**Call from Flutter:**
```dart
final result = await NotificationBackendService.sendToTopic(
  topic: 'all_users',
  title: 'New Feature',
  body: 'Check out our new feature!',
);
```

**How it works:**
- Sends notification to FCM topic (users must subscribe using `FirebaseMessaging.subscribeToTopic()`)
- No Firestore lookup needed - FCM handles topic subscriptions

## Testing

### Test sendToUser:
Just call it from your Flutter app:
```dart
final result = await NotificationBackendService.sendToUser(
  userId: '123',
  title: 'Test Notification',
  body: 'This is a test!',
);
print('Result: $result'); // {success: true, sent: 1, failed: 0}
```

### Verify in Firestore:
- Check `user_devices` collection has FCM tokens
- Check `notifications` collection for notification history

## Important Notes

- ✅ **FREE** - Works on Firebase Spark (free) plan
- ✅ FCM Server Key is stored in `NotificationBackendService` (same as in `NotificationsRepoDB`)
- ⚠️ **Security**: For production apps, consider:
  - Using a free backend service (Vercel/Netlify Functions) to hide the key
  - Or upgrading to Blaze plan (has generous free tier: 2M invocations/month)
- ✅ Make sure Firestore collections `notifications` and `user_devices` exist
- ✅ Users must have FCM tokens saved in `user_devices` collection

## Alternative: If You Want Cloud Functions Later

If you decide to upgrade to Blaze plan later, you can:
1. Deploy the functions in `functions/index.js`
2. Update `NotificationBackendService` to use Cloud Functions again
3. Move FCM Server Key to Firebase Functions environment variables for better security

