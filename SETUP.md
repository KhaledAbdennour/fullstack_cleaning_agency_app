# CleanSpace Setup

This guide is the shortest reliable path to get a fresh clone running.

## 1. Requirements

- Flutter 3.35.x or newer
- Dart 3.9.x or newer
- Node.js 18.x
- Firebase CLI
- Android Studio or a physical Android device

## 2. Clone The Repository

```bash
git clone https://github.com/WailOuaret/clean-space.git
cd clean-space
```

## 3. Install Flutter Dependencies

```bash
flutter pub get
```

## 4. Firebase Project

The repo already points to Firebase project `cleanspace-8214c` through `.firebaserc`.

If your local Firebase CLI is not using that project yet:

```bash
firebase login
firebase use cleanspace-8214c
```

## 5. Deploy Firestore Indexes

The app depends on composite indexes for notifications and job queries.

```bash
firebase deploy --only firestore:indexes
```

You can also deploy rules if needed:

```bash
firebase deploy --only firestore:rules,storage
```

## 6. Optional Functions Setup

Cloud Functions are stored in `functions/`.

```bash
cd functions
npm install
cd ..
```

Run the local emulator:

```bash
cd functions
npm run serve
```

Deploy functions:

```bash
firebase deploy --only functions
```

## 7. Run The App

List devices:

```bash
flutter devices
```

Run on a connected device or emulator:

```bash
flutter run
```

## 8. Platform Notes

- Android is ready with `android/app/google-services.json`.
- iOS needs `ios/Runner/GoogleService-Info.plist` before it can run against Firebase.
- The package name in the codebase remains `mob_dev_project`; that is expected.

## 9. Validation

These commands are the basic health check for a fresh clone:

```bash
flutter pub get
flutter test
```

Optional integration test command:

```bash
flutter test integration_test
```

## 10. Common Issues

- If Firestore queries fail, deploy indexes again and wait for them to finish building.
- If functions fail locally, confirm you are using Node 18.
- If iOS fails to start, add the missing `GoogleService-Info.plist`.
