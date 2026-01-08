# Firebase Messaging Implementation Plan - Exercise C2

## STEP 0: Project Analysis ✅

### Current State:
- ✅ **State Management**: Cubit/BLoC pattern using MultiBlocProvider
- ✅ **Repository Pattern**: Abstract repos + *_repo_db.dart implementations
- ❌ **Service Locator**: NOT using GetIt - need to add
- ✅ **Navigation**: Navigator 1.0 (MaterialApp)
- ✅ **Backend**: Firebase Firestore (migrated from Supabase)
- ✅ **Localization**: EN/FR/AR with RTL support
- ⚠️ **Notifications**: Basic service exists but needs refactoring to follow teacher's pattern

### Current Notification Code:
- `lib/core/services/notification_service.dart` - Static service (needs refactoring)
- `lib/core/services/notification_repo.dart` - Abstract repo interface
- `lib/core/services/notification_repo_db.dart` - Firestore implementation

### Files to Create/Modify:

#### NEW FILES:
1. `lib/core/di/service_locator.dart` - GetIt setup
2. `lib/data/models/notification_item.dart` - Notification model
3. `lib/data/repositories/notifications/notifications_repo.dart` - Abstract repo
4. `lib/data/repositories/notifications/notifications_repo_db.dart` - Firestore implementation
5. `lib/logic/cubits/notifications/notifications_cubit.dart` - State management
6. `lib/logic/cubits/notifications/notifications_state.dart` - States
7. `lib/core/services/notification_router.dart` - Navigation handler
8. `lib/screens/notifications_inbox_page.dart` - Inbox screen
9. `functions/index.js` - Firebase Cloud Functions backend

#### MODIFY FILES:
1. `pubspec.yaml` - Add get_it dependency
2. `lib/main.dart` - Initialize GetIt, add NotificationsCubit to MultiBlocProvider
3. `lib/core/services/notification_service.dart` - Refactor to use repo pattern
4. `lib/l10n/app_en.arb`, `app_fr.arb`, `app_ar.arb` - Add notification strings

---

## STEP 1: Add Dependencies ✅ (Already have most)

### Required Dependencies:
- ✅ `firebase_core: ^2.32.0`
- ✅ `firebase_messaging: ^14.7.9`
- ✅ `flutter_local_notifications: ^16.3.0`
- ✅ `cloud_firestore: ^4.17.5`
- ✅ `shared_preferences: ^2.2.2`
- ❌ `get_it: ^7.6.4` - **NEED TO ADD**

### Firebase Config Files Needed:
- ✅ `android/app/google-services.json` - Already exists
- ❓ `ios/Runner/GoogleService-Info.plist` - Need to verify

---

## STEP 2: Implement Repository Pattern for Notifications

### A) Create Notification Model
**File**: `lib/data/models/notification_item.dart`
```dart
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // route, id, etc.
  final bool read;
}
```

### B) Create Abstract Repository
**File**: `lib/data/repositories/notifications/notifications_repo.dart`
- Abstract class with methods:
  - `initMessaging()`
  - `requestPermission()`
  - `getFcmToken()`
  - `saveTokenToBackend(userId, token, platform)`
  - `storeReceivedNotification(NotificationItem)`
  - `getStoredNotifications()`
  - `markAsRead(id)`

### C) Create Firestore Implementation
**File**: `lib/data/repositories/notifications/notifications_repo_db.dart`
- Implements abstract repo
- Uses Firebase Messaging APIs
- Stores notifications in Firestore collection `notifications`
- Stores tokens in Firestore collection `user_devices`

---

## STEP 3: Create Cubit for State Management

### States:
**File**: `lib/logic/cubits/notifications/notifications_state.dart`
- `NotificationsInitial`
- `NotificationsLoading`
- `NotificationsReady` (with permissionGranted, fcmToken, notifications list)
- `NotificationsError`

### Cubit:
**File**: `lib/logic/cubits/notifications/notifications_cubit.dart`
- `initialize()` - calls repo.initMessaging
- `refreshInbox()` - loads local notifications
- `markRead(id)` - marks notification as read

---

## STEP 4: Add GetIt Service Locator

**File**: `lib/core/di/service_locator.dart`
```dart
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register repositories
  getIt.registerLazySingleton<AbstractNotificationsRepo>(() => NotificationsRepoDB());
  
  // Register other repos if needed...
}
```

---

## STEP 5: Foreground/Background Handling + Click Navigation

### Foreground Handler:
- `FirebaseMessaging.onMessage` → show local notification + store

### Background Handler:
- Top-level function `_firebaseMessagingBackgroundHandler`
- Store notification payload

### Click Navigation:
- `FirebaseMessaging.onMessageOpenedApp` - app opened from notification
- `FirebaseMessaging.instance.getInitialMessage()` - app opened from terminated state
- Create `NotificationRouter.handleMessage(RemoteMessage)` to navigate based on payload

### Payload Structure:
```json
{
  "notification": {
    "title": "New Booking",
    "body": "You have a new booking assigned"
  },
  "data": {
    "route": "/bookingDetails",
    "id": "123"
  }
}
```

---

## STEP 6: Local Storage (Notification Inbox)

### Option: Use Firestore (already using it)
- Store in `notifications` collection with `user_id`, `read`, `created_at`
- Query by user_id, order by created_at desc

### Option: Use SharedPreferences (simpler)
- Store JSON list of notifications
- Less scalable but simpler

**Decision**: Use Firestore since we're already using it.

---

## STEP 7: Simple Backend (Firebase Cloud Functions)

**File**: `functions/index.js`
- Function: `sendToUser(userId, title, body, data)`
- Function: `sendToTopic(topic, title, body, data)`
- Function: `scheduledSender` (runs every hour)

### Token Storage:
- Firestore collection: `user_devices`
- Fields: `user_id`, `fcm_token`, `platform`, `updated_at`

---

## STEP 8: Localization

Add to ARB files:
- Notification titles/messages
- Permission prompts
- Error messages
- Inbox screen strings

---

## IMPLEMENTATION CHECKLIST

- [ ] Add get_it dependency
- [ ] Create notification_item.dart model
- [ ] Refactor notifications to repository pattern
- [ ] Create NotificationsCubit + States
- [ ] Setup GetIt service locator
- [ ] Implement foreground handler
- [ ] Implement background handler
- [ ] Implement click navigation router
- [ ] Create notifications inbox screen
- [ ] Add localization strings
- [ ] Create Firebase Cloud Functions backend
- [ ] Update main.dart with GetIt + NotificationsCubit
- [ ] Test foreground notifications
- [ ] Test background notifications
- [ ] Test click navigation
- [ ] Test backend sending

---

## FIREBASE CONSOLE SETUP NEEDED

### What you need to provide:
1. ✅ FCM Server Key: `6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0`
2. ✅ Sender ID: `636141062102`
3. ✅ google-services.json - Already exists
4. ❓ GoogleService-Info.plist for iOS - Need to verify

### Firestore Collections to Create:
- `notifications` - for storing notification history
- `user_devices` - for storing FCM tokens

### Firebase Cloud Functions:
- Need to deploy functions to send notifications
- Need to set up scheduled function (optional)

---

## NEXT STEPS

1. Fix compilation errors first ✅
2. Add get_it dependency
3. Create notification model
4. Refactor notification service to repository pattern
5. Create NotificationsCubit
6. Setup GetIt
7. Implement handlers
8. Create inbox screen
9. Create backend functions
10. Test everything

