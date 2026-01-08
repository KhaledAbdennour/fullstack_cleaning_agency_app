# Notification Deep-Link Navigation Implementation

## Summary

Implemented comprehensive deep-link navigation for notifications in the CleanSpace Flutter app. When users tap notifications in the inbox, they are now reliably navigated to the correct existing pages based on notification type and payload data.

## Changes Made

### 1. Created NotificationNavData Helper Class
**File:** `lib/core/services/notification_nav_data.dart`

- Parses notification payload safely
- Extracts route, routeId, jobId, bookingId, senderId, cleanerId from notification data
- Handles missing fields gracefully
- Supports both explicit route data and type-based navigation

### 2. Enhanced NotificationRouter
**File:** `lib/core/services/notification_router.dart`

- Added `navigateFromNotification()` method - main entry point for UI taps
- Implements two navigation strategies:
  - **Strategy A:** Use explicit route if provided in notification data
  - **Strategy B:** Use notification type mapping with fallbacks
- Added error handling with user-friendly SnackBar messages
- Maintains existing `navigateToRoute()` for backward compatibility

### 3. Updated Notifications Inbox Page
**File:** `lib/screens/notifications_inbox_page.dart`

- Updated notification tap handler to:
  - Mark notification as read BEFORE navigation
  - Use new `navigateFromNotification()` method
  - Handle both read and unread notifications
- "Mark all read" button already implemented and working

## Notification Type → Page Mapping

| Notification Type | Target Page | Fallback |
|------------------|-------------|----------|
| `job_published` | `JobDetailsScreen` (with jobId) | Error message if jobId missing |
| `job_accepted` | `JobDetailsScreen` (with jobId) | `BookingDetailsScreen` if bookingId available |
| `job_rejected` | `JobDetailsScreen` (with jobId) | Error message if jobId missing |
| `job_completed` | `JobDetailsScreen` (with jobId) | Error message if jobId missing |
| `review_added` | `CleanerProfilePage` (with cleanerId) | Uses senderId as fallback |

## Files Changed

1. **lib/core/services/notification_nav_data.dart** (NEW)
   - Helper class for parsing notification navigation data

2. **lib/core/services/notification_router.dart** (MODIFIED)
   - Added imports for `NotificationItem` and `NotificationNavData`
   - Added import for `ManageJobPage`
   - Added `navigateFromNotification()` method
   - Added `_showErrorSnackBar()` helper method

3. **lib/screens/notifications_inbox_page.dart** (MODIFIED)
   - Updated notification tap handler to use `navigateFromNotification()`
   - Ensures notification is marked as read before navigation

## Code Patches

### NotificationNavData.fromNotification()

```dart
factory NotificationNavData.fromNotification(NotificationItem notification) {
  // Extracts route, routeId, jobId, bookingId, senderId, cleanerId
  // from notification.data map and direct fields
  // Handles missing fields gracefully
}
```

### NotificationRouter.navigateFromNotification()

```dart
static Future<void> navigateFromNotification(BuildContext context, NotificationItem notification) async {
  // Strategy A: Use explicit route if provided
  // Strategy B: Use notification type mapping
  // Shows error SnackBar if navigation fails
}
```

### Notifications Inbox Tap Handler

```dart
onTap: () async {
  // Mark as read BEFORE navigation
  if (!notification.read) {
    await context.read<NotificationsCubit>().markAsRead(notification.id);
  }
  
  // Navigate using enhanced router
  await NotificationRouter.navigateFromNotification(context, notification);
}
```

## Manual Test Steps

### Test 1: Job Published Notification
1. As a client, create a new job
2. As an agency/worker, check notifications inbox
3. Tap the "New Job Available" notification
4. **Expected:** Navigate to `JobDetailsScreen` showing the job details
5. **Verify:** Notification is marked as read

### Test 2: Job Accepted Notification
1. As a worker, apply to a job
2. As a client, accept the worker's application
3. As the worker, check notifications inbox
4. Tap the "Application Accepted!" notification
5. **Expected:** Navigate to `JobDetailsScreen` showing the accepted job
6. **Verify:** Notification is marked as read

### Test 3: Job Rejected Notification
1. As a worker, apply to a job
2. As a client, reject the worker's application
3. As the worker, check notifications inbox
4. Tap the "Application Rejected" notification
5. **Expected:** Navigate to `JobDetailsScreen` showing the rejected job
6. **Verify:** Notification is marked as read

### Test 4: Job Completed Notification
1. Complete a job (both worker and client mark as done)
2. Check notifications inbox
3. Tap the "Job Completed" notification
4. **Expected:** Navigate to `JobDetailsScreen` showing the completed job
5. **Verify:** Notification is marked as read

### Test 5: Review Added Notification
1. Complete a job
2. As a client, add a review for the cleaner
3. As the cleaner, check notifications inbox
4. Tap the "New Review" notification
5. **Expected:** Navigate to `CleanerProfilePage` showing the cleaner's profile
6. **Verify:** Notification is marked as read

### Test 6: Missing Data Fallback
1. Create a notification manually in Firestore without route or jobId
2. Tap the notification
3. **Expected:** Show error SnackBar: "Cannot open this notification (missing target)."
4. **Verify:** App does not crash

### Test 7: Mark All Read
1. Have multiple unread notifications
2. Tap "Mark all read" button in app bar
3. **Expected:** All notifications marked as read, unread count becomes 0
4. **Verify:** UI updates immediately

### Test 8: Already Read Notification
1. Tap a notification that is already marked as read
2. **Expected:** Navigate to target page without re-marking as read
3. **Verify:** Navigation works correctly

## Error Handling

- Missing route and type: Shows error SnackBar
- Missing jobId for job-related notifications: Shows error SnackBar
- Missing cleanerId for review notifications: Tries senderId as fallback
- Job/booking not found: Shows error SnackBar
- Network errors: Caught and displayed in SnackBar
- All errors are non-blocking - app continues to function

## Backward Compatibility

- Existing `navigateToRoute()` method preserved for FCM push notifications
- Existing notification creation code unchanged (already includes route data)
- All existing notification types supported

## Future Enhancements

- Add navigation to ManageJobPage for clients/agencies when viewing their own jobs
- Add navigation to applications list for job-related notifications
- Add navigation to reviews tab directly for review notifications
- Support deep-linking from push notifications (already partially implemented)

