# CleanSpace - Complete Workflow Implementation Report

## Executive Summary

This document provides a comprehensive overview of the complete job workflow implementation for CleanSpace, including notifications, job lifecycle management, reviews, and agency-worker linking. All implementations follow the teacher's architectural pattern (Repository Pattern, Cubit/BLoC, Service Locator).

---

## A) Code Changes Summary

### Files Modified

#### 1. **`lib/data/models/job_model.dart`**
**Changes:**
- Added `assignedWorkerId` field to track which worker is assigned to a job
- Added `clientDone` and `workerDone` boolean fields for completion confirmation
- Updated `JobStatus` enum with proper lifecycle states:
  - `open` - Job visible to workers (can apply)
  - `pending` - Workers can apply, client reviewing
  - `assigned` - ONE worker accepted
  - `inProgress` - Job in progress
  - `completedPendingConfirmation` - One party confirmed, waiting for other
  - `completed` - Both confirmed
  - `cancelled` - Job cancelled
- Added helper methods: `isAvailableForApplication`, `isCompleted`
- Updated `toMap()` and `fromMap()` to handle new fields
- Updated `statusLabel` getter for new statuses
- Added legacy status mapping for backward compatibility

#### 2. **`lib/data/repositories/jobs/jobs_repo_db.dart`**
**Changes:**
- Updated `createJob()` to set initial status to `open` for new jobs
- Updated `getAvailableJobsForAgency()` to:
  - Query for `open`/`pending` status (not `active`)
  - Exclude jobs with `assigned_worker_id != null`
  - Filter out already-applied jobs
- Added `markClientDone(int jobId)` method:
  - Uses Firestore transaction for atomicity
  - Sets `client_done = true`
  - If `worker_done` is also true, sets status to `completed`
  - Otherwise sets status to `completedPendingConfirmation`
  - Sends notifications appropriately
- Added `markWorkerDone(int jobId)` method:
  - Same logic as `markClientDone` but for worker
  - Sends notifications to client when worker confirms

#### 3. **`lib/data/repositories/jobs/jobs_repo.dart`**
**Changes:**
- Added abstract methods: `markClientDone(int jobId)`, `markWorkerDone(int jobId)`

#### 4. **`lib/data/repositories/bookings/bookings_repo_db.dart`**
**Changes:**
- Updated `createBooking()` to send notification to client when worker applies:
  - Title: "New Application Received"
  - Body: "A worker has applied to your job [title]"
  - Route: `/jobDetails` with `jobId`
- Completely rewrote `acceptApplication(int bookingId)`:
  - **Uses Firestore transaction for atomic operation:**
    1. Validates booking exists
    2. Checks job is not already assigned
    3. Updates booking status to `inProgress`
    4. Updates job: sets `status = assigned`, `assigned_worker_id = providerId`
    5. Rejects all other pending applications for the same job
  - Sends notifications:
    - To accepted worker: "Application Accepted!"
    - To client: "Worker Assigned"

#### 5. **`lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart`**
**Changes:**
- Updated `addReview()` to use Firestore transaction:
  - Creates review document
  - **Auto-updates cleaner rating:**
    - Calculates new average from all reviews (including new one)
    - Updates `cleaners` collection: `rating`, `rating_avg`, `rating_count`
    - Falls back to `profiles` collection if cleaner not in `cleaners`
  - Ensures data consistency

#### 6. **`lib/data/models/cleaner_review.dart`**
**Changes:**
- Added optional `jobId` field to link reviews to specific jobs
- Updated `toMap()` and `fromMap()` to include `job_id`

---

## B) Full Project Description

### 1. User Types and Permissions

#### User Roles (from `profiles` collection):
- **Client** (`user_type: 'Client'`)
  - Can publish jobs
  - Can view applicants
  - Can accept ONE worker per job
  - Can mark job as finished
  - Can leave reviews after completion

- **Agency** (`user_type: 'Agency'`)
  - Can manage linked workers (in `cleaners` collection with `agency_id`)
  - Can view jobs relevant to their company
  - Can apply to client jobs
  - Can accept workers if agency acts as client (depends on design)
  - Can mark jobs as finished
  - Can leave reviews

- **Individual Cleaner** (`user_type: 'Individual Cleaner'`)
  - Can apply to client jobs
  - Can see assigned jobs in "my current job"
  - Can mark jobs as finished
  - Can leave reviews

### 2. App Screens and Flows

#### Client Flow:
1. **Create Job** → `add-post.dart`
   - Creates job with status `open`
   - Notification sent to all workers/agencies

2. **View Applicants** → `jobdetails.dart` / `manage_job_page.dart`
   - Shows all pending applications
   - Can accept ONE worker

3. **Accept Worker** → `bookings_repo_db.dart::acceptApplication()`
   - Atomic transaction updates job + booking
   - Job disappears from other workers' available jobs
   - Notifications sent

4. **Mark Finished** → Calls `jobs_repo_db.dart::markClientDone()`
   - Sets `client_done = true`
   - If worker also done → status = `completed`
   - Notification sent

5. **Leave Review** → `review_page.dart`
   - Only after job is `completed`
   - Creates review in `cleaner_reviews` collection
   - Auto-updates cleaner rating

#### Worker/Agency Flow:
1. **Browse Available Jobs** → `find_cleaner_page.dart` / `agency_dashboard_page.dart`
   - Query: `status IN ['open', 'pending']` AND `assigned_worker_id == null`
   - Excludes jobs already applied to

2. **Apply to Job** → `bookings_repo_db.dart::createBooking()`
   - Creates booking with status `pending`
   - Notification sent to client

3. **View Assigned Job** → `booking_details_page.dart`
   - Query: `bookings` where `provider_id == userId` AND `status == 'inProgress'`
   - Shows job details

4. **Mark Finished** → Calls `jobs_repo_db.dart::markWorkerDone()`
   - Sets `worker_done = true`
   - If client also done → status = `completed`
   - Notification sent

5. **Leave Review** → After completion
   - Can review client (if supported)

### 3. Firestore Collections and Schemas

#### `profiles` Collection
```dart
{
  id: int (doc ID),
  username: string,
  password: string,
  full_name: string,
  email: string?,
  phone: string?,
  user_type: 'Client' | 'Agency' | 'Individual Cleaner',
  agency_name: string?,
  rating: double? (for cleaners),
  rating_avg: double?,
  created_at: timestamp,
  updated_at: timestamp?
}
```

#### `jobs` Collection
```dart
{
  id: int (doc ID),
  title: string,
  city: string,
  country: string,
  description: string,
  status: 'open' | 'pending' | 'assigned' | 'inProgress' | 'completedPendingConfirmation' | 'completed' | 'cancelled',
  posted_date: timestamp,
  job_date: timestamp,
  cover_image_url: string?,
  client_id: int?,
  agency_id: int?,
  assigned_worker_id: int?, // NEW: Worker assigned to this job
  client_done: int (0 or 1), // NEW: Client confirmed completion
  worker_done: int (0 or 1), // NEW: Worker confirmed completion
  budget_min: double?,
  budget_max: double?,
  estimated_hours: int?,
  required_services: string? (comma-separated),
  is_deleted: int (0 or 1),
  created_at: timestamp?,
  updated_at: timestamp?
}
```

#### `bookings` Collection (Job Applications)
```dart
{
  id: int (doc ID),
  job_id: int,
  client_id: int,
  provider_id: int? (worker/agency who applied),
  status: 'pending' | 'inProgress' | 'completed' | 'cancelled',
  bid_price: double?,
  message: string?,
  created_at: timestamp,
  updated_at: timestamp
}
```

#### `cleaners` Collection (Agency Workers)
```dart
{
  id: int (doc ID),
  name: string,
  avatar_url: string?,
  rating: double (auto-updated),
  rating_avg: double (auto-updated),
  rating_count: int (auto-updated),
  jobs_completed: int,
  agency_id: int, // Links to profiles.id where user_type='Agency'
  is_active: int (0 or 1),
  created_at: timestamp?,
  updated_at: timestamp?
}
```

#### `cleaner_reviews` Collection
```dart
{
  id: int (doc ID),
  cleaner_id: int,
  job_id: int?, // NEW: Optional link to job
  reviewer_id: int?,
  reviewer_name: string,
  rating: double (1-5),
  date: timestamp,
  comment: string,
  has_photos: int (0 or 1),
  photo_urls: string? (comma-separated),
  created_at: timestamp?
}
```

#### `notifications` Collection (Notification History)
```dart
{
  id: string (auto),
  user_id: string,
  title: string,
  body: string,
  data_json: map {
    route: string?,
    id: string?,
    action_type: string?
  },
  created_at: timestamp,
  read: bool
}
```

#### `user_devices` Collection (FCM Tokens)
```dart
{
  id: string (auto),
  user_id: string,
  fcm_token: string,
  platform: 'android' | 'ios',
  created_at: timestamp,
  updated_at: timestamp
}
```

### 4. Notification Flow Design

#### Token Storage:
- **Location:** `user_devices` collection
- **Key Fields:** `user_id`, `fcm_token`, `platform`
- **Collection:** One document per device per user

#### Sending Notifications:
- **Service:** `lib/core/services/notification_backend_service.dart`
- **Method:** Direct FCM HTTP API calls (FREE - no Cloud Functions)
- **Endpoint:** `https://fcm.googleapis.com/fcm/send`
- **Authorization:** FCM Server Key (stored in service, should be moved to secure location in production)

#### Notification Triggers:

1. **Worker Applies to Job** (`createBooking()`)
   - **Trigger:** Booking created with `provider_id != null`
   - **Recipient:** Client (`client_id`)
   - **Message:** "New Application Received - A worker has applied to your job [title]"
   - **Route:** `/jobDetails` with `jobId`

2. **Client Accepts Worker** (`acceptApplication()`)
   - **Trigger:** Booking status changed to `inProgress`
   - **Recipients:**
     - Accepted worker: "Application Accepted! Your application for [title] has been accepted."
     - Client: "Worker Assigned - A worker has been assigned to your job [title]."
   - **Route:** `/jobDetails` with `jobId`

3. **Worker Marks Job Finished** (`markWorkerDone()`)
   - **Trigger:** `worker_done = true`
   - **Recipient:** Client
   - **Message:** "Worker Marked Job Finished - The worker has marked [title] as finished. Please confirm completion."
   - **Route:** `/jobDetails` with `jobId`

4. **Client Marks Job Finished** (`markClientDone()`)
   - **Trigger:** `client_done = true`
   - **Recipient:** Worker
   - **Message:** "Client Confirmed Completion - The client has confirmed completion of [title]. Please confirm as well."
   - **Route:** `/jobDetails` with `jobId`

5. **Both Confirm Completion** (when `client_done && worker_done`)
   - **Trigger:** Status changed to `completed`
   - **Recipients:** Both client and worker
   - **Message:** "Job Completed! Job [title] has been completed. You can now leave a review."
   - **Route:** `/jobDetails` with `jobId`

#### Notification History:
- Every push notification is also stored in `notifications` collection
- Includes: `user_id`, `title`, `body`, `data_json`, `created_at`, `read`

### 5. Job Lifecycle and State Machine

```
┌─────────┐
│  open   │ ← New job created by client
└────┬────┘
     │ Workers can apply
     ▼
┌─────────┐
│ pending │ ← Client reviewing applicants
└────┬────┘
     │ Client accepts ONE worker
     ▼
┌─────────┐
│assigned │ ← ONE worker accepted, others rejected
└────┬────┘
     │ Job starts
     ▼
┌──────────────┐
│  inProgress  │ ← Job in progress
└────┬─────────┘
     │ One party marks finished
     ▼
┌─────────────────────────────┐
│completedPendingConfirmation │ ← Waiting for other party
└────┬────────────────────────┘
     │ Other party confirms
     ▼
┌───────────┐
│ completed │ ← Both confirmed, reviews enabled
└───────────┘
```

#### State Transitions:

| From | To | Condition |
|------|-----|-----------|
| `open` | `pending` | Client starts reviewing (optional, can stay `open`) |
| `open`/`pending` | `assigned` | Client accepts ONE worker (atomic transaction) |
| `assigned` | `inProgress` | Job starts (optional, can go directly to completion) |
| `inProgress` | `completedPendingConfirmation` | One party marks finished |
| `completedPendingConfirmation` | `completed` | Other party confirms |
| Any | `cancelled` | Job cancelled |

#### Rules:
- ✅ Only ONE worker can be assigned per job
- ✅ Once assigned, job disappears from all other workers' available jobs
- ✅ Both parties must confirm for job to be `completed`
- ✅ Reviews only enabled after `completed` status

### 6. Review System Logic

#### Review Creation:
- **Trigger:** Job status is `completed`
- **Location:** `cleaner_reviews` collection
- **Fields Required:**
  - `cleaner_id` (required)
  - `job_id` (optional, for tracking)
  - `reviewer_id` (optional, client who left review)
  - `reviewer_name` (required)
  - `rating` (1-5, required)
  - `comment` (required)
  - `date` (timestamp)

#### Auto-Update Cleaner Rating:
- **When:** Review is added (`addReview()`)
- **Process:**
  1. Calculate average of ALL reviews for cleaner (including new one)
  2. Update `cleaners` collection:
     - `rating` = calculated average
     - `rating_avg` = calculated average (for compatibility)
     - `rating_count` = total review count
  3. If cleaner not in `cleaners`, update `profiles` collection instead

#### Review Queries:
- `getReviewsForCleaner(cleanerId)` - All reviews for a cleaner
- `getAverageRatingForCleaner(cleanerId)` - Calculated average
- `getReviewCountForCleaner(cleanerId)` - Total count

### 7. Agency-Worker Linking Logic

#### Data Model:
- **Agency:** Profile with `user_type = 'Agency'`
- **Worker:** Entry in `cleaners` collection with `agency_id` pointing to agency's profile ID

#### Linking:
- **Collection:** `cleaners`
- **Key Field:** `agency_id` (references `profiles.id`)
- **Query:** `getCleanersForAgency(agencyId)` returns all workers for an agency

#### Usage:
- Agency dashboard shows linked workers
- Workers can be assigned to agency jobs
- Agency can manage worker list (add/remove/activate/deactivate)

#### Implementation:
- **Repository:** `lib/data/repositories/cleaners/cleaners_repo_db.dart`
- **Method:** `getCleanersForAgency(int agencyId)`
- **Query:** `cleaners.where('agency_id', isEqualTo: agencyId).where('is_active', isEqualTo: true)`

---

## C) Firestore Composite Indexes Required

Firestore requires composite indexes for queries that combine `where()` filters with `orderBy()`. Below are all required indexes:

### Index 1: Jobs - Available Jobs Query
**Collection:** `jobs`  
**Fields:**
- `agency_id` (Ascending)
- `status` (Ascending)
- `is_deleted` (Ascending)
- `posted_date` (Descending)

**Used in:** `getAvailableJobsForAgency()`

**Create Link:**
```
https://console.firebase.google.com/project/cleanspace-8214c/firestore/indexes?create_composite=...
```

**Manual Creation:**
1. Go to Firebase Console → Firestore → Indexes
2. Click "Create Index"
3. Collection: `jobs`
4. Add fields:
   - `agency_id` (Ascending)
   - `status` (Ascending)
   - `is_deleted` (Ascending)
   - `posted_date` (Descending)
5. Query scope: Collection
6. Create

### Index 2: Bookings - Client Bookings
**Collection:** `bookings`  
**Fields:**
- `client_id` (Ascending)
- `created_at` (Descending)

**Used in:** `getBookingsForClient()`

### Index 3: Bookings - Job Applications
**Collection:** `bookings`  
**Fields:**
- `job_id` (Ascending)
- `created_at` (Descending)

**Used in:** `getApplicationsForJob()`

### Index 4: Bookings - Cleaner Accepted Jobs
**Collection:** `bookings`  
**Fields:**
- `provider_id` (Ascending)
- `status` (Ascending)
- `created_at` (Descending)

**Used in:** `getAcceptedJobsForCleaner()`

### Index 5: Cleaner Reviews - Reviews by Cleaner
**Collection:** `cleaner_reviews`  
**Fields:**
- `cleaner_id` (Ascending)
- `date` (Descending)

**Used in:** `getReviewsForCleaner()`

### Index 6: Jobs - Client Jobs
**Collection:** `jobs`  
**Fields:**
- `client_id` (Ascending)
- `is_deleted` (Ascending)
- `posted_date` (Descending)

**Used in:** `getJobsForClient()`

### Index 7: Jobs - Agency Active Jobs
**Collection:** `jobs`  
**Fields:**
- `agency_id` (Ascending)
- `client_id` (Ascending)
- `is_deleted` (Ascending)
- `status` (Ascending)
- `posted_date` (Descending)

**Used in:** `getActiveJobsForAgency()`

### Index 8: Cleaners - Agency Workers
**Collection:** `cleaners`  
**Fields:**
- `agency_id` (Ascending)
- `is_active` (Ascending)
- `jobs_completed` (Descending)

**Used in:** `getCleanersForAgency()`

### Index 9: User Devices - User Tokens
**Collection:** `user_devices`  
**Fields:**
- `user_id` (Ascending)
- `updated_at` (Descending)

**Used in:** `NotificationBackendService.sendToUser()`

---

## D) Testing Checklist

### Scenario 1: Worker Applies → Client Notified
**Steps:**
1. Login as Client
2. Create a new job (status should be `open`)
3. Login as Worker/Agency
4. Browse available jobs (should see the new job)
5. Apply to the job
6. **Expected:**
   - Client receives notification: "New Application Received"
   - Booking created with status `pending`
   - Job remains visible to other workers

**Verify:**
- Check `bookings` collection: new document with `status = 'pending'`
- Check `notifications` collection: notification to client
- Check client's device: push notification received

### Scenario 2: Client Accepts → Worker Notified, Job Disappears for Others
**Steps:**
1. Login as Client
2. View job applicants
3. Accept ONE worker
4. **Expected:**
   - Accepted worker receives notification: "Application Accepted!"
   - Client receives notification: "Worker Assigned"
   - Job status changes to `assigned`
   - Job `assigned_worker_id` set to accepted worker's ID
   - All other applications for this job set to `cancelled`
   - Job disappears from other workers' available jobs list

**Verify:**
- Check `jobs` collection: `status = 'assigned'`, `assigned_worker_id` set
- Check `bookings` collection: accepted booking `status = 'inProgress'`, others `status = 'cancelled'`
- Login as another worker: job should NOT appear in available jobs
- Check notifications: both parties notified

### Scenario 3: Both Confirm Completion → Review Enabled
**Steps:**
1. Login as Worker (assigned to a job)
2. Mark job as finished (`markWorkerDone()`)
3. **Expected:**
   - Job status changes to `completedPendingConfirmation`
   - Client receives notification: "Worker Marked Job Finished"
4. Login as Client
5. Confirm completion (`markClientDone()`)
6. **Expected:**
   - Job status changes to `completed`
   - Both parties receive notification: "Job Completed! You can now leave a review."
   - Review button/option becomes available

**Verify:**
- Check `jobs` collection: `status = 'completed'`, `client_done = 1`, `worker_done = 1`
- Check notifications: both parties notified
- UI shows review option

### Scenario 4: Leave Review → Cleaner Rating Updated
**Steps:**
1. After job is `completed`, login as Client
2. Leave a review for the worker (rating 1-5, comment)
3. **Expected:**
   - Review saved in `cleaner_reviews` collection
   - Cleaner's `rating` in `cleaners` collection automatically updated
   - `rating_avg` and `rating_count` updated

**Verify:**
- Check `cleaner_reviews` collection: new review document
- Check `cleaners` collection: `rating`, `rating_avg`, `rating_count` updated
- Calculate average manually: should match stored value

### Scenario 5: Agency Links Worker → Worker Shows Under Agency
**Steps:**
1. Login as Agency
2. Add a worker to agency (create entry in `cleaners` with `agency_id`)
3. View agency dashboard
4. **Expected:**
   - Worker appears in agency's worker list
   - Worker's `agency_id` matches agency's profile ID

**Verify:**
- Check `cleaners` collection: worker document with `agency_id` set
- Query `getCleanersForAgency(agencyId)`: worker should be in results
- Agency dashboard: worker card displayed

### Scenario 6: Available Jobs Query (No Assigned Jobs)
**Steps:**
1. Create a job as Client (status `open`)
2. Login as Worker A, apply to job
3. Login as Client, accept Worker A
4. Login as Worker B
5. Browse available jobs
6. **Expected:**
   - Job should NOT appear (because `assigned_worker_id` is set)

**Verify:**
- Query `getAvailableJobsForAgency(workerBId)`: job should NOT be in results
- Check query filters: `assigned_worker_id == null` enforced

### Scenario 7: Atomic Accept Application (Race Condition Prevention)
**Steps:**
1. Create a job
2. Two workers apply simultaneously
3. Client accepts Worker A
4. **Expected:**
   - Only Worker A is accepted
   - Worker B's application is rejected
   - Job cannot be accepted twice (transaction prevents)

**Verify:**
- Use Firestore transaction: check `assigned_worker_id == null` before accepting
- If already assigned, transaction fails
- Only one booking has `status = 'inProgress'`

---

## E) Important Notes

### Security Considerations:
1. **FCM Server Key:** Currently stored in `notification_backend_service.dart`. For production, move to:
   - Environment variables
   - Secure backend (Vercel/Netlify Functions)
   - Firebase Cloud Functions (requires Blaze plan)

2. **Firestore Rules:** Ensure proper security rules are set:
   - Users can only read their own notifications
   - Clients can only accept applications for their jobs
   - Workers can only mark their assigned jobs as done

### Performance:
- All heavy operations (notifications, rating calculations) are non-blocking
- Firestore transactions ensure data consistency
- Composite indexes required for complex queries

### Backward Compatibility:
- Legacy statuses (`active`, `booked`, `paused`) are mapped to new statuses
- Existing jobs will work with new code
- Migration script not needed (handled in `fromMap()`)

---

## F) Remaining Optional Enhancements

1. **Worker-to-Client Reviews:** Currently only client can review worker. Add reverse reviews if needed.

2. **Job Cancellation:** Implement proper cancellation flow with notifications.

3. **Job Rescheduling:** Allow clients to reschedule jobs (with notifications).

4. **Bulk Notifications:** Optimize notification sending for multiple recipients.

5. **Notification Preferences:** Allow users to configure notification types.

---

## Conclusion

All core workflow requirements have been implemented:
- ✅ Job lifecycle with proper state transitions
- ✅ Atomic worker acceptance (one worker per job)
- ✅ Completion confirmation (both parties)
- ✅ Notification system (all events)
- ✅ Reviews with auto-updated ratings
- ✅ Agency-worker linking
- ✅ Firestore queries with proper indexes

The system is ready for testing and demonstration.

