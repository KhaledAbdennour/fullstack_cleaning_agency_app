# Firebase Storage Rules Deployment Guide

## Option 1: Deploy via Firebase Console (Web Interface) - RECOMMENDED

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **cleanspace-8214c**
3. Click on **Storage** in the left sidebar
4. Click on the **Rules** tab
5. Copy and paste the contents of `storage.rules` file
6. Click **Publish**

## Option 2: Deploy via Firebase CLI (if installation completes)

Once Firebase CLI is installed, run:
```bash
firebase login
firebase deploy --only storage
```

## Current Storage Rules

The rules allow:
- **Read**: Public access (anyone can view profile pictures)
- **Write**: All writes allowed (temporary for development)

After deployment, profile picture uploads should work!
