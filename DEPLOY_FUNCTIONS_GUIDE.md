# Deploy Firebase Cloud Functions - Windows Guide

## Issue: Firebase CLI Not Recognized

After installing `firebase-tools` globally, PowerShell may not recognize the `firebase` command immediately. Here are solutions:

## Solution 1: Refresh PowerShell PATH (Recommended)

**Close and reopen PowerShell**, then try again:
```powershell
firebase --version
firebase login
```

## Solution 2: Use Full Path

Find where npm installed Firebase CLI (usually in `%APPDATA%\npm`), then use full path:

```powershell
# Check if firebase.cmd exists here
$env:APPDATA\npm\firebase.cmd --version

# If it exists, use it directly:
$env:APPDATA\npm\firebase.cmd login
```

## Solution 3: Add npm to PATH Manually

1. Open System Properties → Environment Variables
2. Edit "Path" under User variables
3. Add: `%APPDATA%\npm`
4. Restart PowerShell

## Step-by-Step Deployment

Once `firebase` command works:

### 1. Login to Firebase
```powershell
firebase login
```
This will open a browser for authentication.

### 2. Initialize Firebase (if not already done)
```powershell
cd C:\Users\wailo\Desktop\mob_dev_project
firebase init functions
```
- Select existing project: **cleanspace**
- Language: JavaScript
- ESLint: No (or Yes if you want)
- Install dependencies: Yes

### 3. Deploy Functions
```powershell
cd functions
firebase deploy --only functions
```

### 4. Verify Deployment
Check Firebase Console → Functions to see deployed functions.

## Alternative: Use npx (No Installation Needed)

If Firebase CLI still doesn't work, use `npx`:

```powershell
cd C:\Users\wailo\Desktop\mob_dev_project\functions
npx firebase-tools login
npx firebase-tools deploy --only functions
```

## Quick Test Without Deployment

You can test functions locally first:

```powershell
npx firebase-tools emulators:start --only functions
```

Then test using the emulator URL.

---

## Troubleshooting

### "firebase: command not found"
- **Solution**: Close and reopen PowerShell, or use `npx firebase-tools`

### "Permission denied" or "Access denied"
- **Solution**: Run PowerShell as Administrator

### "Project not found"
- **Solution**: Make sure you're logged in: `firebase login`
- Check project ID in `.firebaserc` matches your Firebase Console project

### Functions deployment fails
- Check `functions/package.json` has correct dependencies
- Run `npm install` in `functions/` directory first
- Check Firebase Console → Functions → Verify billing is enabled (Blaze plan required for Cloud Functions)

---

## Next Steps After Deployment

1. **Test Functions**:
   - Go to Firebase Console → Functions
   - Click on a function → Test tab
   - Or call from Flutter using `NotificationBackendService`

2. **Check Logs**:
   ```powershell
   firebase functions:log
   ```

3. **Update Functions** (if needed):
   ```powershell
   cd functions
   # Edit index.js
   firebase deploy --only functions
   ```

