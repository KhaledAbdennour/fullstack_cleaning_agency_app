# Firebase Setup Fix - Package Name Mismatch

## ⚠️ Issue Detected

Your `google-services.json` file has package name: **`com.labpixies.flood`**
But your app's `applicationId` is: **`com.example.mob_dev_project`**

This mismatch will prevent Firebase from working correctly.

## ✅ Solution Options

### Option 1: Register New Android App in Firebase (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **fir-demo-project**
3. Click **Add app** → Select **Android**
4. Enter package name: **`com.example.mob_dev_project`**
5. Download the new `google-services.json`
6. Replace `android/app/google-services.json` with the new file

### Option 2: Change Application ID (Not Recommended)

If you want to use the existing Firebase app:

1. Update `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.labpixies.flood"
   ```

2. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest package="com.labpixies.flood">
   ```

3. Update Kotlin package structure to match

**Note**: This requires changing package names throughout the codebase.

## ✅ Current Status

### Fixed ✅
- ✅ Google Services plugin added to `android/app/build.gradle.kts`
- ✅ Google Services classpath added to `android/build.gradle.kts`
- ✅ `google-services.json` file exists in correct location

### Needs Action ⚠️
- ⚠️ Package name mismatch needs to be resolved (see options above)

## After Fixing

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Verify Firebase connection**:
   - Check that FCM token is generated
   - Test notification sending/receiving

## Verification

After updating `google-services.json`, verify it contains:
```json
{
  "client": [{
    "client_info": {
      "android_client_info": {
        "package_name": "com.example.mob_dev_project"
      }
    }
  }]
}
```

---

**Recommendation**: Use Option 1 (register new Android app) to keep your current package name structure.

