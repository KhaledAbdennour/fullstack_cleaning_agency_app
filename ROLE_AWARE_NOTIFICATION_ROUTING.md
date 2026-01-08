# Role-Aware Notification Deep-Link Routing

## Summary

Implemented comprehensive role-aware deep-link navigation for notifications. Navigation now routes users to the exact page that matches their role and the notification context, instead of generic JobDetailsScreen for everything.

## Changes Made

### 1. Enhanced Notification Creation
**File:** `lib/core/services/notification_service_enhanced.dart`

- Added parameters: `bookingId`, `workerId`, `clientId`, `agencyId`
- All notification creation now includes comprehensive context data
- Route data stored in `data_json` with all relevant IDs

### 2. Enhanced NotificationNavData
**File:** `lib/core/services/notification_nav_data.dart`

- Added fields: `workerId`, `clientId`, `agencyId`
- Enhanced parsing to extract all IDs from notification data
- Supports both direct fields and data_json extraction

### 3. Role-Aware NotificationRouter
**File:** `lib/core/services/notification_router.dart`

- Added `_getCurrentUserRole()` to detect user role from ProfilesCubit
- Added `_normalizeUserRole()` to standardize role strings
- Completely rewrote `navigateFromNotification()` with role-aware routing
- Added `_navigateToAgencyDashboard()` for worker/agency navigation
- Added `_navigateToMyProfileReviews()` for worker profile navigation

### 4. Updated Notification Creation Calls
**Files:** 
- `lib/data/repositories/bookings/bookings_repo_db.dart`
- `lib/data/repositories/jobs/jobs_repo_db.dart`
- `lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart`

- All notification creation calls now include `bookingId`, `workerId`, `clientId`, `agencyId` where applicable

## Final Mapping Table

| Notification Type | User Role | Target Page | Required Payload Fields |
|------------------|-----------|-------------|------------------------|
| `job_published` | Client | `ManageJobPage` | `job_id`, `client_id` |
| `job_published` | Worker/Cleaner | `JobDetailsScreen` | `job_id` |
| `job_published` | Agency | `JobDetailsScreen` | `job_id` |
| `job_accepted` | Client | `ManageJobPage` | `job_id`, `booking_id`, `worker_id`, `client_id` |
| `job_accepted` | Worker/Cleaner | `AgencyDashboardPage` (Active Listings tab) | `job_id`, `booking_id`, `worker_id` |
| `job_accepted` | Agency | `ManageJobPage` or `AgencyDashboardPage` | `job_id`, `booking_id`, `worker_id`, `agency_id` |
| `job_rejected` | Client | `ManageJobPage` | `job_id`, `client_id` |
| `job_rejected` | Worker/Cleaner | `JobDetailsScreen` | `job_id` |
| `job_completed` | Client | `JobDetailsScreen` | `job_id`, `worker_id`, `client_id` |
| `job_completed` | Worker/Cleaner | `CleanerSelfProfilePage` (History tab) | `job_id`, `worker_id` |
| `job_completed` | Agency | `AgencyDashboardPage` (Past Bookings tab) | `job_id`, `agency_id` |
| `review_added` | Client | `CleanerProfilePage` | `cleaner_id` or `worker_id` |
| `review_added` | Worker/Cleaner | `CleanerSelfProfilePage` (Reviews tab) | `cleaner_id` |
| `review_added` | Agency | `CleanerProfilePage` | `cleaner_id` or `worker_id` |

## Files Changed

1. **lib/core/services/notification_service_enhanced.dart** (MODIFIED)
   - Added `bookingId`, `workerId`, `clientId`, `agencyId` parameters
   - Enhanced `data_json` to include all IDs

2. **lib/core/services/notification_nav_data.dart** (MODIFIED)
   - Added `workerId`, `clientId`, `agencyId` fields
   - Enhanced parsing logic

3. **lib/core/services/notification_router.dart** (MODIFIED)
   - Added role detection and normalization
   - Complete rewrite of `navigateFromNotification()` with role-aware logic
   - Added helper methods for specific navigation targets

4. **lib/data/repositories/bookings/bookings_repo_db.dart** (MODIFIED)
   - Updated `acceptApplication()` and `rejectApplication()` notification calls

5. **lib/data/repositories/jobs/jobs_repo_db.dart** (MODIFIED)
   - Updated `createJob()`, `markWorkerDone()`, `markClientDone()` notification calls

6. **lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart** (MODIFIED)
   - Updated `addReview()` notification calls

## Manual Test Steps

### Test 1: Client - Job Accepted Notification
1. As a client, accept a worker's application
2. Tap the "Worker Assigned" notification
3. **Expected:** Navigate to `ManageJobPage` showing the job with applications list
4. **Verify:** Can see accepted worker and manage the job

### Test 2: Worker - Job Accepted Notification
1. As a worker, have your application accepted
2. Tap the "Application Accepted!" notification
3. **Expected:** Navigate to `AgencyDashboardPage` (Active Listings tab)
4. **Verify:** Can see the accepted job in active jobs list with Start/Pause/Mark Done actions

### Test 3: Client - Job Completed Notification
1. Complete a job (both worker and client mark as done)
2. As the client, tap the "Job Completed!" notification
3. **Expected:** Navigate to `JobDetailsScreen` showing completed job
4. **Verify:** Can see job details and leave review option

### Test 4: Worker - Job Completed Notification
1. Complete a job
2. As the worker, tap the "Job Completed!" notification
3. **Expected:** Navigate to `CleanerSelfProfilePage`
4. **Verify:** Can navigate to History tab to see completed job

### Test 5: Review Added Notification
1. As a client, add a review for a cleaner
2. As the cleaner, tap the "New Review Received" notification
3. **Expected:** Navigate to `CleanerSelfProfilePage`
4. **Verify:** Can navigate to Reviews tab to see the new review

### Test 6: Client - Job Published (Own Job)
1. As a client, create a new job
2. Tap the notification about your own job (if any)
3. **Expected:** Navigate to `ManageJobPage` for that job
4. **Verify:** Can see applications and manage the job

### Test 7: Worker - Job Published (New Opportunity)
1. As a worker, receive notification about a new job
2. Tap the "New Job Available" notification
3. **Expected:** Navigate to `JobDetailsScreen` (apply page)
4. **Verify:** Can view job details and apply

## Implementation Notes

### Role Detection
- Uses `ProfilesCubit` to get current user
- Extracts `user_type` field from user profile
- Normalizes role strings: "Individual Cleaner" / "Worker" / "Agency" / "Client"

### Navigation Targets
- **ManageJobPage**: For clients managing their own jobs (applications list + accept/reject)
- **AgencyDashboardPage**: For workers/agencies (Active Listings = active jobs, Past Bookings = history)
- **CleanerSelfProfilePage**: For workers viewing their own profile (History/Reviews tabs)
- **JobDetailsScreen**: Generic job details (apply page for workers, view page for others)
- **CleanerProfilePage**: Viewing another cleaner's profile

### Tab Navigation Limitations
- Currently navigates to pages but doesn't automatically open specific tabs
- Users may need to manually tap the correct tab after navigation
- Future enhancement: Pass tab index to page constructors or use state management

### Fallback Behavior
- If role cannot be determined, defaults to generic navigation (JobDetailsScreen)
- If required IDs are missing, shows error SnackBar
- All errors are non-blocking

## Error Handling

- Missing role: Defaults to generic navigation
- Missing jobId: Shows error SnackBar
- Missing cleanerId: Tries workerId or senderId as fallback
- Job/booking not found: Shows error SnackBar
- All errors are user-friendly and non-blocking

## Backward Compatibility

- Existing `navigateToRoute()` method preserved
- Existing notification creation code updated but maintains same interface
- All existing notification types supported with enhanced routing

