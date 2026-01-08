# CleanSpace Project - Complete Setup Guide

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- Firebase account
- Android device or emulator for testing

---

## STEP 1: Firebase Project Setup

### 1.1 Create/Select Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"** or select existing project **"cleanspace-8214c"**
3. If creating new project:
   - Project name: `cleanspace` (or your preferred name)
   - Enable Google Analytics (optional)
   - Create project

### 1.2 Enable Cloud Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in production mode"** (we'll set rules later)
4. Choose location: **us-central** (or closest to your users)
5. Click **"Enable"**

**Important:** Wait 2-3 minutes for Firestore to be fully enabled.

### 1.3 Enable Cloud Firestore API

1. Go to [Google Cloud Console - Firestore API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=cleanspace-8214c)
2. Click **"Enable"** if not already enabled
3. Wait for API to be enabled (may take a few minutes)

### 1.4 Set Firestore Security Rules (Development)

1. In Firebase Console → **Firestore Database** → **Rules** tab
2. Replace with these development rules (allows read/write for testing):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents (DEVELOPMENT ONLY)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

**⚠️ WARNING:** These rules allow anyone to read/write. For production, implement proper authentication-based rules.

---

## STEP 2: Android App Configuration

### 2.1 Add Android App to Firebase

1. In Firebase Console → **Project Settings** (gear icon)
2. Scroll to **"Your apps"** section
3. Click **"Add app"** → Select **Android**
4. Enter package name: `com.example.mob_dev_project`
   - Find this in `android/app/build.gradle.kts` → `applicationId`
5. Register app
6. Download `google-services.json`
7. Replace `android/app/google-services.json` with the downloaded file

### 2.2 Add SHA-1/SHA-256 Fingerprints (Optional - for Google Sign-In)

1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Look for SHA1 in the output under `Variant: debug`

2. In Firebase Console → **Project Settings** → **Your apps** → Android app
3. Click **"Add fingerprint"**
4. Paste SHA-1 and SHA-256 (if available)
5. Click **"Save"**

---

## STEP 3: iOS App Configuration (If Needed)

### 3.1 Add iOS App to Firebase

1. In Firebase Console → **Project Settings** → **Your apps**
2. Click **"Add app"** → Select **iOS**
3. Enter bundle ID: Check `ios/Runner/Info.plist` → `CFBundleIdentifier`
4. Register app
5. Download `GoogleService-Info.plist`
6. Replace `ios/Runner/GoogleService-Info.plist` with downloaded file

---

## STEP 4: Firebase Cloud Messaging (FCM) Setup

### 4.1 Enable Cloud Messaging API

1. Go to [Google Cloud Console - FCM API](https://console.developers.google.com/apis/api/fcm.googleapis.com/overview?project=cleanspace-8214c)
2. Click **"Enable"** if not already enabled

### 4.2 Get FCM Server Key

1. In Firebase Console → **Project Settings** → **Cloud Messaging** tab
2. Copy the **Server key** (starts with `AIza...`)
3. This key is already stored in:
   - `lib/core/services/notification_backend_service.dart`
   - `lib/data/repositories/notifications/notifications_repo_db.dart`

**Note:** For production, move this key to Firebase Functions environment variables or a secure backend.

---

## STEP 5: Firestore Collections Structure

The app will automatically create these collections when data is first written:

### Required Collections:

1. **`profiles`** - User profiles
   - Fields: `id`, `username`, `email`, `user_type`, `full_name`, etc.

2. **`jobs`** - Job listings
   - Fields: `id`, `title`, `city`, `country`, `status`, `client_id`, `agency_id`, etc.

3. **`bookings`** - Job applications/bookings
   - Fields: `id`, `job_id`, `client_id`, `provider_id`, `status`, etc.

4. **`cleaners`** - Cleaner team members
   - Fields: `id`, `name`, `rating`, `agency_id`, etc.

5. **`cleaning_history`** - Cleaning history records
   - Fields: `id`, `cleaner_id`, `title`, `date`, `type`, etc.

6. **`cleaner_reviews`** - Reviews for cleaners
   - Fields: `id`, `cleaner_id`, `reviewer_name`, `rating`, `comment`, etc.

7. **`notifications`** - Notification history
   - Fields: `user_id`, `title`, `body`, `data_json`, `created_at`, `read`, etc.

8. **`user_devices`** - FCM tokens per user
   - Fields: `user_id`, `fcm_token`, `platform`, `updated_at`, etc.

**No manual creation needed** - collections are created automatically on first write.

### 8. **`job_history`** - Job completion history for all roles
   - Fields: `job_id`, `participant_user_id`, `role`, `completed_at`, `title`, `other_party_id`, etc.
   - Tracks completed jobs for workers, clients, and agencies

---

## STEP 6: Deploy Firestore Composite Indexes

**CRITICAL:** Firestore requires composite indexes for queries that combine `where()` filters with `orderBy()`. These indexes must be deployed before the app can query notifications and jobs efficiently.

### 6.1 Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### 6.2 Login to Firebase

```bash
firebase login
```

### 6.3 Initialize Firebase in Project (if not already done)

```bash
cd C:\Users\wailo\Desktop\mob_dev_project
firebase init firestore
```

When prompted:
- Select existing project: `cleanspace-8214c` (or your project)
- Use existing `firestore.indexes.json`: **Yes**
- Use existing `firestore.rules`: **Yes** (or create new)

### 6.4 Deploy Indexes

```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
✔  firestore: indexes deployed successfully
```

### 6.5 Verify Indexes in Firebase Console

1. Go to Firebase Console → **Firestore Database** → **Indexes** tab
2. Verify all indexes show **"Enabled"** status:
   - `notifications` - user_id + type + created_at
   - `notifications` - user_id + read + created_at
   - `jobs` - assigned_worker_id + status + is_deleted + posted_date
   - `jobs` - client_id + status + is_deleted + posted_date
   - `jobs` - agency_id + status + is_deleted + assigned_worker_id
   - `job_history` - participant_user_id + role + completed_at

**Note:** Index creation can take 5-10 minutes. The app will use fallback queries (client-side filtering) if indexes are not ready, but performance will be better once indexes are enabled.

---

## STEP 7: Install Dependencies

```bash
cd C:\Users\wailo\Desktop\mob_dev_project
flutter pub get
```

---

## STEP 8: Run the App

### 7.1 Check Connected Devices

```bash
flutter devices
```

### 7.2 Run on Android Device/Emulator

```bash
flutter run -d <device-id>
```

Or simply:
```bash
flutter run
```

---

## STEP 9: Verify Setup

### 8.1 Check Firebase Connection

1. Run the app
2. Check console logs for:
   - `✅ Firebase initialized successfully!`
   - `✅ Firestore initialized successfully`
   - No `PERMISSION_DENIED` errors

### 8.2 Check Firestore Data

1. Go to Firebase Console → **Firestore Database**
2. Verify collections are created after app runs
3. Check that seed data appears (profiles, jobs, etc.)

### 8.3 Test Notifications

1. Create a test user account in the app
2. Check that FCM token is saved in `user_devices` collection
3. Create a job as a client
4. Verify workers receive notification (check Firestore `notifications` collection)

---

## STEP 10: Firebase Cloud Functions (Optional - for Production)

If you want to use Cloud Functions instead of direct FCM calls:

### 9.1 Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 9.2 Login to Firebase

```bash
npx firebase login
```

### 9.3 Deploy Functions

```bash
cd functions
npm install
cd ..
npx firebase deploy --only functions
```

**Note:** Cloud Functions require **Blaze (pay-as-you-go) plan**, but has a generous free tier (2M invocations/month).

**Current Setup:** The app uses direct FCM HTTP API calls (FREE, works on Spark plan).

---

## Notification Architecture

### How Notifications Work

1. **Creation**: When an event occurs (job created, application accepted, etc.), `NotificationServiceEnhanced.createNotification()` is called
2. **Storage**: Notification is saved to Firestore `notifications` collection with:
   - `user_id`: Recipient's user ID
   - `type`: Notification type (job_published, job_accepted, etc.)
   - `title`, `body`: Notification content
   - `created_at`: Timestamp
   - `read`: Boolean flag
3. **Push Notification**: FCM push notification is sent to user's device
4. **Retrieval**: UI queries notifications using role-based selectors:
   - `getNotificationsForWorker()` - Returns job_accepted, job_rejected, job_completed, review_added
   - `getNotificationsForAgency()` - Returns job_published, job_accepted, job_rejected, job_completed, review_added
   - `getNotificationsForClient()` - Returns job_accepted, job_rejected, job_completed, review_added
5. **Badge Count**: Uses the same role-based query as inbox to ensure consistency

### Job Lifecycle State Machine

```
open → assigned → inProgress → completedPendingConfirmation → completed
  ↓                                                              ↑
pending                                                          |
  ↓                                                              |
cancelled ←──────────────────────────────────────────────────────┘
```

**State Transitions:**
- **open** → **assigned**: Client accepts worker application (`acceptApplication()`)
- **assigned** → **inProgress**: Worker starts job (`markJobStarted()`)
- **inProgress** → **completedPendingConfirmation**: One party marks done (`markClientDone()` or `markWorkerDone()`)
- **completedPendingConfirmation** → **completed**: Both parties confirm completion
- **completed**: History entries created in `job_history` collection for worker, client, and agency

**Review Flow:**
- Reviews can only be added when `job.status == completed`
- Client reviews cleaner (required)
- Worker can optionally review client
- Rating automatically updates cleaner's profile

---

## Troubleshooting

### Error: "Cloud Firestore API has not been used"

- **Solution:** Enable Firestore API in Google Cloud Console (Step 1.3)
- Wait 2-3 minutes after enabling

### Error: "No Firebase App '[DEFAULT]' has been created"

- **Solution:** Ensure `Firebase.initializeApp()` runs before any Firestore calls
- Check `lib/main.dart` - initialization order is fixed

### Error: "PERMISSION_DENIED"

- **Solution:** 
  1. Check Firestore rules (Step 1.4)
  2. Ensure Firestore database is created (Step 1.2)
  3. Wait a few minutes after creating database

### Notifications Not Working

- **Check:**
  1. FCM token is saved in `user_devices` collection
  2. FCM Server Key is correct in code
  3. Cloud Messaging API is enabled
  4. App has notification permissions (Android: automatic, iOS: request permission)

### Build Errors

- **Solution:** Run `flutter clean` then `flutter pub get`
- Check that `google-services.json` is in `android/app/` directory

---

## Production Checklist

Before deploying to production:

- [ ] Update Firestore security rules with proper authentication
- [ ] Move FCM Server Key to secure backend (Firebase Functions or environment variables)
- [ ] Enable Firebase App Check for additional security
- [ ] Set up proper error monitoring (Firebase Crashlytics)
- [ ] Test on multiple devices and Android versions
- [ ] Review and optimize Firestore queries
- [ ] Set up Firebase Storage for image uploads (if needed)
- [ ] Configure proper backup and data retention policies

---

## Support

If you encounter issues:

1. Check Firebase Console for error logs
2. Check Flutter console output for detailed errors
3. Verify all steps in this guide are completed
4. Ensure Firebase project ID matches `.firebaserc` file

---

**Last Updated:** 2024
**Project:** CleanSpace - Mobile Development Project
