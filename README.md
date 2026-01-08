# CleanSpace - Mobile Development Project

A Flutter-based mobile application for connecting clients with cleaning service providers (individual cleaners and agencies).

## Features

- **Multi-Role System**: Supports Clients, Individual Cleaners, and Agencies
- **Job Management**: Post jobs, apply, accept, and track job lifecycle
- **Real-time Notifications**: Firebase Cloud Messaging (FCM) for job updates
- **Review System**: Rate and review cleaners after job completion
- **History Tracking**: Complete job history for all participants
- **Role-based UI**: Customized experience for each user type

## Architecture

### Notification System

The app uses a role-based notification system:

- **Notifications Collection**: Stores all notifications in Firestore
- **Role-based Filtering**: Each role (Worker, Agency, Client) receives only relevant notifications
- **Notification Types**:
  - `job_published` - New job posted (Agencies receive)
  - `job_accepted` - Application accepted (Worker, Client, Agency)
  - `job_rejected` - Application rejected (Worker)
  - `job_completed` - Job fully completed (All parties)
  - `review_added` - New review added (Cleaner, Client, Agency)

**Notification Flow:**
1. Event occurs (job created, application accepted, etc.)
2. `NotificationServiceEnhanced.createNotification()` creates notification document
3. FCM push notification sent to user's device
4. Notification stored in Firestore `notifications` collection
5. UI queries notifications using role-based selectors

**Badge Count:** Uses the same role-based query as inbox to ensure consistency.

### Job Lifecycle State Machine

```
open → assigned → inProgress → completedPendingConfirmation → completed
  ↓                                                              ↑
pending                                                          |
  ↓                                                              |
cancelled ←──────────────────────────────────────────────────────┘
```

**State Transitions:**
1. **open** → **assigned**: Client accepts a worker application
2. **assigned** → **inProgress**: Worker starts the job (optional)
3. **inProgress** → **completedPendingConfirmation**: One party marks job as done
4. **completedPendingConfirmation** → **completed**: Both parties confirm completion
5. **completed**: Job is fully done, history entries created, reviews enabled

**Key Methods:**
- `acceptApplication()` - Transitions job from `open`/`pending` to `assigned`
- `markJobStarted()` - Transitions from `assigned` to `inProgress`
- `markClientDone()` / `markWorkerDone()` - Transitions to `completedPendingConfirmation` or `completed`
- `_addJobToHistory()` - Creates history entries in `job_history` collection for all participants

### Data Models

**Job History:**
- Collection: `job_history`
- Tracks completed jobs for workers, clients, and agencies
- Fields: `job_id`, `participant_user_id`, `role`, `completed_at`, `title`, `other_party_id`

**Reviews:**
- Collection: `cleaner_reviews`
- Reviews can only be added when `job.status == completed`
- Auto-updates cleaner's average rating in `cleaners`/`profiles` collection

## Setup

See [SETUP.md](SETUP.md) for complete setup instructions.

### Quick Start

1. **Deploy Firestore Indexes** (REQUIRED):
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## Firestore Indexes

The app requires the following composite indexes (defined in `firestore.indexes.json`):

1. **Notifications by User and Type**
   - Collection: `notifications`
   - Fields: `user_id` (Ascending), `type` (Ascending), `created_at` (Descending)

2. **Notifications by User and Read Status**
   - Collection: `notifications`
   - Fields: `user_id` (Ascending), `read` (Ascending), `created_at` (Descending)

3. **Active Jobs for Worker**
   - Collection: `jobs`
   - Fields: `assigned_worker_id` (Ascending), `status` (Ascending), `is_deleted` (Ascending), `posted_date` (Descending)

4. **Active Jobs for Client**
   - Collection: `jobs`
   - Fields: `client_id` (Ascending), `status` (Ascending), `is_deleted` (Ascending), `posted_date` (Descending)

5. **Jobs for Agency**
   - Collection: `jobs`
   - Fields: `agency_id` (Ascending), `status` (Ascending), `is_deleted` (Ascending), `assigned_worker_id` (Ascending)

6. **Job History**
   - Collection: `job_history`
   - Fields: `participant_user_id` (Ascending), `role` (Ascending), `completed_at` (Descending)

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

## Project Structure

```
lib/
├── core/
│   ├── config/          # Firebase configuration
│   ├── debug/           # Debug flags and logging
│   └── services/        # Notification services, routing
├── data/
│   ├── models/          # Data models (Job, Notification, Review, etc.)
│   └── repositories/    # Data access layer (Firestore implementations)
├── logic/
│   └── cubits/          # State management (BLoC pattern)
└── screens/             # UI screens
```

## Debug Mode

Debug logging can be controlled via `lib/core/debug/debug_flags.dart`:

```dart
static const bool enableDebugLogs = false;  // Set to true for debugging
static const bool enableUIDiagnostics = false;  // Set to true for UI diagnostics
```

## Testing Checklist

Before submission, verify:

- [ ] Notifications appear in inbox after creation (not just badge)
- [ ] Accepted job appears immediately in worker's active jobs (no restart)
- [ ] Job completion creates history entries for worker, client, and agency
- [ ] Reviews are blocked before completion and enabled after
- [ ] Rating updates correctly on cleaner profile
- [ ] All Firestore indexes are deployed and enabled
- [ ] No hardcoded dummy data in production UI
- [ ] Debug logs are disabled in production

## License

This project is for educational purposes.
