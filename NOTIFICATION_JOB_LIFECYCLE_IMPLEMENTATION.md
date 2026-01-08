# Notification and Job Lifecycle System - Implementation Plan

## Summary

This document outlines the complete implementation of the notification and job lifecycle system for CleanSpace.

## Implementation Status

### ✅ Already Implemented
- Notification model with type field (`NotificationItem`)
- NotificationServiceEnhanced with role-based selectors
- Job lifecycle methods (acceptApplication, markClientDone, markWorkerDone)
- History addition methods (`_addJobToHistory`)
- Active/completed job query methods (private in JobsDB)

### ❌ Needs Fixing
- Notification triggers not using NotificationServiceEnhanced
- Notification repository not using role-based selectors
- Active/completed job methods not exposed in abstract repo
- Review system not updating ratings
- Dummy data in listings cubit
- UI not showing notifications properly grouped

## Files to Modify

1. `lib/data/repositories/notifications/notifications_repo_db.dart` - Add role-based selectors
2. `lib/data/repositories/notifications/notifications_repo.dart` - Add role-based selector methods
3. `lib/logic/cubits/notifications/notifications_cubit.dart` - Use role-based selectors
4. `lib/data/repositories/jobs/jobs_repo_db.dart` - Fix notification triggers, expose active/completed methods
5. `lib/data/repositories/jobs/jobs_repo.dart` - Add active/completed method signatures
6. `lib/data/repositories/bookings/bookings_repo_db.dart` - Fix notification triggers
7. `lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart` - Fix rating updates
8. `lib/screens/notifications_inbox_page.dart` - Group notifications by type
9. `lib/logic/cubits/listings_cubit.dart` - Remove dummy data
10. Create new screens: `active_jobs_page.dart`, `completed_jobs_page.dart`

