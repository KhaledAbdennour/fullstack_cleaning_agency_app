# CleanSpace

CleanSpace is a Flutter mobile app for connecting clients with cleaners and agencies. The repo includes the app, Firebase rules and indexes, Cloud Functions for notification support, local cache code, and automated tests.

## Repo Contents

- `lib/`: Flutter application code
- `test/`: unit tests
- `integration_test/`: integration tests
- `functions/`: Firebase Cloud Functions
- `docs/ux/`: usability testing artifacts
- `firestore.indexes.json`, `firestore.rules`, `storage.rules`: Firebase configuration

## Quick Start

### Prerequisites

- Flutter 3.35.x or newer
- Dart 3.9.x or newer
- Node.js 18.x if you want to run or deploy Firebase Functions
- Firebase CLI if you want to deploy indexes, rules, or functions
- Android Studio or a connected Android device/emulator

### Clone And Run

```bash
git clone https://github.com/WailOuaret/clean-space.git
cd clean-space
flutter pub get
firebase deploy --only firestore:indexes
flutter run
```

If you want to work with Cloud Functions too:

```bash
cd functions
npm install
cd ..
```

## Firebase Notes

- The repo is configured for the Firebase project `cleanspace-8214c` in `.firebaserc`.
- Android already includes `android/app/google-services.json`.
- iOS does not currently include `ios/Runner/GoogleService-Info.plist`. Add that file before running on iOS.
- Firestore indexes are required for notifications and some job queries. Deploy them before testing the full app flow.

## Verified Commands

The following commands were run successfully in this repo:

```bash
flutter pub get
flutter test
```

## Tests

```bash
flutter test
flutter test integration_test
```

## Backend

Cloud Functions live in `functions/` and use Node 18:

```bash
cd functions
npm install
npm run serve
```

To deploy:

```bash
firebase deploy --only functions
```

## Additional Setup

See `SETUP.md` for a fuller project setup checklist.
