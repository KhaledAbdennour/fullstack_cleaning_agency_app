# Firebase Setup Test Guide

## ✅ Step 1: Complete Firebase Console Setup

1. **Fix google-services.json** (if not done):
   - Firebase Console → Project Settings → Your Apps → Android
   - Add/edit Android app with package: `com.example.mob_dev_project`
   - Download new `google-services.json`
   - Replace `android/app/google-services.json`

2. **Click "Next" on Firebase SDK screen**
   - You should see "Continue to console"
   - Click it to finish

---

## ✅ Step 2: Clean and Run

```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Step 3: Test FCM Token

The app already has FCM token collection in `NotificationService.initialize()`.

### Option A: Check Logs

When the app starts, look for:
- `FCM Token: <token>` in console/logs
- Or any error messages

### Option B: Add Test Code

Temporarily add this to test (e.g., in `main.dart` after initialization):

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// After NotificationService.initialize()
try {
  final token = await FirebaseMessaging.instance.getToken();
  print("FCM TOKEN: $token");
  if (token != null) {
    print("✅ FCM token generated successfully!");
  } else {
    print("❌ FCM token is null");
  }
} catch (e) {
  print("❌ FCM token error: $e");
}
```

---

## ✅ Expected Results

### ✅ Success
- Token prints: `FCM TOKEN: <long-string>`
- No errors in console
- **Tell me**: "FCM token printed"

### ❌ Failure
- Token is null
- Error message appears
- **Tell me**: "Token is null / error" + the error message

---

## 🔍 Common Issues

### Issue 1: Package Name Mismatch
**Error**: `Default FirebaseApp is not initialized`
**Fix**: Ensure `google-services.json` has correct package name

### Issue 2: Missing google-services.json
**Error**: `File google-services.json is missing`
**Fix**: Download from Firebase Console and place in `android/app/`

### Issue 3: Plugin Not Applied
**Error**: Build fails
**Fix**: Verify `android/app/build.gradle.kts` has Google Services plugin

---

## 📝 After Testing

**Tell me ONE of these:**

1. ✅ **"FCM token printed"** - Token generated successfully
2. ❌ **"Token is null / error"** - Include the error message

Then I'll guide you through connecting Firebase → Supabase Edge Function for notifications!

