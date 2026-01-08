# Quick Deploy Instructions

## ✅ Firebase CLI is Installed!

Firebase CLI version **15.1.0** is installed and working.

## 🚀 Deploy Functions (Run These Commands)

**Open a NEW PowerShell window** (to refresh PATH), then run:

```powershell
# Navigate to project
cd C:\Users\wailo\Desktop\mob_dev_project

# Login to Firebase (will open browser)
firebase login

# Navigate to functions directory
cd functions

# Deploy functions
firebase deploy --only functions
```

## 📝 Step-by-Step:

### Step 1: Login
```powershell
firebase login
```
- This will open your browser
- Sign in with your Google account
- Authorize Firebase CLI
- Return to PowerShell - you should see "Success! Logged in as [your-email]"

### Step 2: Initialize Firebase (if needed)
If you get "Firebase project not found", run:
```powershell
cd C:\Users\wailo\Desktop\mob_dev_project
firebase init functions
```
- Select: **Use an existing project**
- Choose: **cleanspace** (your project)
- Language: **JavaScript**
- ESLint: **No** (or Yes if you want)
- Install dependencies: **Yes**

### Step 3: Deploy
```powershell
cd functions
firebase deploy --only functions
```

You should see:
```
✔  functions[sendToUser(us-central1)] Successful create operation.
✔  functions[sendToTopic(us-central1)] Successful create operation.
✔  functions[scheduledSender(us-central1)] Successful create operation.
```

## 🔧 If Firebase Command Still Not Found

**Option 1**: Close and reopen PowerShell (refreshes PATH)

**Option 2**: Use full path:
```powershell
$env:APPDATA\npm\firebase.cmd login
$env:APPDATA\npm\firebase.cmd deploy --only functions
```

**Option 3**: Use npx (no PATH needed):
```powershell
npx firebase-tools login
npx firebase-tools deploy --only functions
```

## ✅ After Deployment

1. **Verify in Firebase Console**:
   - Go to https://console.firebase.google.com
   - Select your project → Functions
   - You should see 3 functions: `sendToUser`, `sendToTopic`, `scheduledSender`

2. **Test Functions**:
   - In Firebase Console → Functions → Click a function → Test tab
   - Or use from Flutter: `NotificationBackendService.sendToUser(...)`

3. **Check Logs**:
   ```powershell
   firebase functions:log
   ```

## 🎯 Your Functions Will Be Available At:

- `https://us-central1-cleanspace.cloudfunctions.net/sendToUser`
- `https://us-central1-cleanspace.cloudfunctions.net/sendToTopic`

(Region may vary - check Firebase Console for exact URLs)

---

## 💡 Quick Test (Without Deployment)

Test functions locally first:

```powershell
cd functions
firebase emulators:start --only functions
```

Then test using: `http://localhost:5001/cleanspace/us-central1/sendToUser`

