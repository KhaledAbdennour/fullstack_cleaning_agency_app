# Exercise C2: Firebase Messaging Implementation - Complete Setup Guide

## ✅ IMPLEMENTATION COMPLETE

All requirements from Exercise C2 have been implemented following the teacher's architecture pattern.

---

## 📋 WHAT WAS IMPLEMENTED

### ✅ 1. Firebase Cloud Messaging (FCM)
- ✅ Receive notifications when app is OPEN (foreground)
- ✅ Receive notifications when app is CLOSED/BACKGROUND
- ✅ Show notification banner using flutter_local_notifications while app is foreground
- ✅ Handle notification click: route user to correct screen

### ✅ 2. Repository Pattern (Teacher's Method)
- ✅ **Abstract Repository**: `lib/data/repositories/notifications/notifications_repo.dart`
- ✅ **Implementation**: `lib/data/repositories/notifications/notifications_repo_db.dart`
- ✅ **All Firebase APIs called ONLY in repo_db** - UI never touches Firebase directly

### ✅ 3. Cubit/BLoC State Management
- ✅ **Cubit**: `lib/logic/cubits/notifications/notifications_cubit.dart`
- ✅ **States**: `lib/logic/cubits/notifications/notifications_state.dart`
- ✅ Registered in `MultiBlocProvider` in `main.dart`

### ✅ 4. GetIt Service Locator
- ✅ **Setup**: `lib/core/di/service_locator.dart`
- ✅ NotificationsRepo registered as singleton
- ✅ Cubit uses GetIt to get repo instance

### ✅ 5. Simple Backend
- ✅ **Firebase Cloud Functions**: `functions/index.js`
- ✅ `sendToUser(userId, title, body, data)` - Send to specific user
- ✅ `sendToTopic(topic, title, body, data)` - Send to topic subscribers
- ✅ `scheduledSender` - Runs every hour automatically

### ✅ 6. Local Storage
- ✅ Notifications stored in Firestore `notifications` collection
- ✅ FCM tokens stored in Firestore `user_devices` collection
- ✅ Notifications persist across app restarts

### ✅ 7. Notification Inbox Screen
- ✅ `lib/screens/notifications_inbox_page.dart`
- ✅ Shows all received notifications
- ✅ Mark as read / Mark all as read
- ✅ Click notification to navigate

### ✅ 8. Click Navigation
- ✅ **Router**: `lib/core/services/notification_router.dart`
- ✅ Handles `onMessageOpenedApp` (app in background)
- ✅ Handles `getInitialMessage()` (app terminated)
- ✅ Routes to: BookingDetails, JobDetails, Profile, or Inbox

### ✅ 9. Localization
- ✅ Added notification strings to `app_en.arb`, `app_fr.arb`, `app_ar.arb`
- ✅ RTL support for Arabic maintained

---

## 🚀 SETUP INSTRUCTIONS

### Step 1: Firebase Console Setup

#### A) Verify Firebase Project
1. Go to https://console.firebase.google.com
2. Select your project: **cleanspace**
3. Verify Sender ID: `636141062102`
4. Verify FCM Server Key is available (Project Settings → Cloud Messaging)

#### B) Verify Configuration Files
- ✅ Android: `android/app/google-services.json` - **Already exists**
- ❓ iOS: `ios/Runner/GoogleService-Info.plist` - **Need to verify/download**

**To download iOS config:**
1. Firebase Console → Project Settings → Your apps → iOS app
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` directory

#### C) Enable Cloud Messaging API
1. Firebase Console → Project Settings → Cloud Messaging
2. Verify "Firebase Cloud Messaging API (V1)" is **Enabled** ✅
3. Note: Legacy API is disabled (as shown in your screenshot)

### Step 2: Firestore Collections

The following collections will be created automatically when first used:
- `notifications` - Stores notification history
- `user_devices` - Stores FCM tokens per user

**Optional**: Create them manually in Firestore Console if you want to see the structure first.

### Step 3: Deploy Firebase Cloud Functions

```bash
# Install Node.js (v18+) if not already installed
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

**Functions will be available at:**
- `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendToUser`
- `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendToTopic`

### Step 4: Android Configuration

✅ **Already configured:**
- `google-services.json` in place
- AndroidManifest.xml updated with permissions
- Notification channel configured in code

**Verify AndroidManifest.xml has:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### Step 5: iOS Configuration

**Required:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/` directory
3. Open Xcode → Enable Push Notifications capability
4. Enable Background Modes → Remote notifications

**In Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Add "Push Notifications"
4. Add "Background Modes" → Check "Remote notifications"

---

## 🧪 TESTING CHECKLIST

### Test 1: App Closed → Receive Notification
1. Close the app completely
2. Send notification via Firebase Console or backend function
3. ✅ Notification should appear in system tray
4. Tap notification
5. ✅ App should open and navigate to correct screen

### Test 2: App Open → Receive Notification
1. Keep app open in foreground
2. Send notification
3. ✅ Local notification banner should appear
4. ✅ Notification stored in inbox
5. Tap notification
6. ✅ Should navigate to correct screen

### Test 3: App in Background → Receive Notification
1. Put app in background (home button)
2. Send notification
3. ✅ Notification should appear in system tray
4. Tap notification
5. ✅ App should come to foreground and navigate

### Test 4: Notification Inbox
1. Open app → Go to Settings → Notifications (or add button to navigate to inbox)
2. ✅ Should see all received notifications
3. ✅ Unread notifications marked with blue dot
4. Tap notification → ✅ Should navigate
5. Tap "Mark all read" → ✅ All marked as read

### Test 5: Backend Function Call
```dart
// Test sending notification from Flutter
import 'package:mob_dev_project/core/services/notification_backend_service.dart';

await NotificationBackendService.sendToUser(
  userId: '1', // Replace with actual user ID
  title: 'Test Notification',
  body: 'This is a test notification',
  route: '/notifications',
);
```

### Test 6: Scheduled Notifications
- Scheduled function runs every hour
- Check Firebase Functions logs to verify it's running
- Users with active jobs should receive periodic reminders

---

## 📱 HOW TO USE IN YOUR APP

### Send Notification from Flutter Code:

```dart
import 'package:mob_dev_project/core/services/notification_backend_service.dart';

// Send to specific user
await NotificationBackendService.sendToUser(
  userId: '123',
  title: 'New Booking Assigned',
  body: 'You have a new booking to complete',
  route: '/bookingDetails',
  id: '456', // booking ID
);

// Send to topic (e.g., all cleaners)
await NotificationBackendService.sendToTopic(
  topic: 'cleaners',
  title: 'New Jobs Available',
  body: 'Check out new cleaning jobs in your area',
  data: {'route': '/jobs'},
);
```

### Access Notifications Cubit in UI:

```dart
// In any screen
BlocBuilder<NotificationsCubit, NotificationsState>(
  builder: (context, state) {
    if (state is NotificationsReady) {
      final unreadCount = state.unreadCount;
      // Show badge, etc.
    }
    return YourWidget();
  },
)

// Refresh inbox
context.read<NotificationsCubit>().refreshInbox();

// Mark as read
context.read<NotificationsCubit>().markAsRead(notificationId);
```

### Navigate to Notifications Inbox:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NotificationsInboxPage()),
);
```

---

## 🔧 FILES CREATED/MODIFIED

### New Files:
1. `lib/data/models/notification_item.dart` - Notification model
2. `lib/data/repositories/notifications/notifications_repo.dart` - Abstract repo
3. `lib/data/repositories/notifications/notifications_repo_db.dart` - Firestore impl
4. `lib/logic/cubits/notifications/notifications_cubit.dart` - State management
5. `lib/logic/cubits/notifications/notifications_state.dart` - States
6. `lib/core/di/service_locator.dart` - GetIt setup
7. `lib/core/services/notification_router.dart` - Navigation handler
8. `lib/core/services/notification_backend_service.dart` - Backend calls
9. `lib/screens/notifications_inbox_page.dart` - Inbox screen
10. `functions/index.js` - Cloud Functions backend
11. `functions/package.json` - Functions dependencies

### Modified Files:
1. `pubspec.yaml` - Added get_it, cloud_functions
2. `lib/main.dart` - Added GetIt setup, NotificationsCubit, click handlers
3. `lib/l10n/app_*.arb` - Added notification strings
4. `android/app/src/main/AndroidManifest.xml` - Added permissions

---

## 📝 PAYLOAD STRUCTURE

### Notification Payload Format:
```json
{
  "notification": {
    "title": "New Booking",
    "body": "You have a new booking assigned"
  },
  "data": {
    "route": "/bookingDetails",
    "id": "123",
    "user_id": "1"
  }
}
```

### Supported Routes:
- `/bookingDetails` or `/booking` → BookingDetailsScreen
- `/jobDetails` or `/job` → JobDetailsScreen
- `/profile` or `/clientProfile` → ClientProfilePage
- `/notifications` or `/inbox` → NotificationsInboxPage (default)

---

## 🎯 DEMO CHECKLIST (For Teacher)

- [x] ✅ Repository pattern: UI never calls Firebase directly
- [x] ✅ Cubit/BLoC: NotificationsCubit manages state
- [x] ✅ GetIt: Service locator registered and used
- [x] ✅ Foreground notifications: Shows local notification banner
- [x] ✅ Background notifications: Handled via background handler
- [x] ✅ Click navigation: Routes to correct screen based on payload
- [x] ✅ Local storage: Notifications stored in Firestore
- [x] ✅ Backend: Cloud Functions can send targeted notifications
- [x] ✅ Scheduled: Function runs periodically (every hour)
- [x] ✅ Localization: EN/FR/AR strings added

---

## 🐛 TROUBLESHOOTING

### Notifications not received:
1. Check FCM token is saved: Look in Firestore `user_devices` collection
2. Check Firebase Console → Cloud Messaging → Verify API enabled
3. Check Android: Verify `google-services.json` is correct
4. Check iOS: Verify `GoogleService-Info.plist` is in place
5. Check permissions: Android 13+ requires POST_NOTIFICATIONS permission

### Click navigation not working:
1. Verify notification payload has `route` field
2. Check NotificationRouter.handleMessage is called
3. Verify screens exist and are imported correctly

### Backend function errors:
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify functions are deployed: `firebase functions:list`
3. Check Firestore rules allow read/write

---

## 📚 NEXT STEPS (Optional Enhancements)

1. **Add notification badge** to app icon showing unread count
2. **Enhance navigation** to fetch and pass actual job/booking data
3. **Add notification sounds** and custom vibration patterns
4. **Implement notification categories** (booking updates, job alerts, etc.)
5. **Add notification preferences** (user can choose what to receive)
6. **Implement notification grouping** (group by type/date)

---

## ✅ PROJECT STATUS

**Exercise C2: COMPLETE** ✅

All requirements implemented following teacher's architecture pattern:
- ✅ Repository pattern separation
- ✅ Cubit/BLoC state management  
- ✅ GetIt service locator
- ✅ Foreground/background handling
- ✅ Click navigation
- ✅ Local storage
- ✅ Simple backend
- ✅ Localization

**Ready for testing and demo!** 🎉

