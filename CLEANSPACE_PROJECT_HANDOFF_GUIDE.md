# CleanSpace Flutter/Firebase Project Handoff Guide

**Project:** CleanSpace - Mobile Development Project  
**Tech Stack:** Flutter 3.9.2, Firebase (Firestore, FCM), BLoC/Cubit State Management  
**Date:** Generated from codebase analysis

---

## Table of Contents

1. [High-level Architecture](#1-high-level-architecture)
2. [Directory Map](#2-directory-map)
3. [File-by-file Responsibilities](#3-file-by-file-responsibilities)
4. [Firestore Schema (As Implemented)](#4-firestore-schema-as-implemented)
5. [Notifications System (Deep Dive)](#5-notifications-system-deep-dive)
6. [Jobs / Bookings Flow (Deep Dive)](#6-jobs--bookings-flow-deep-dive)
7. [Reviews Flow (Deep Dive)](#7-reviews-flow-deep-dive)
8. [Firestore Indexes & Rules](#8-firestore-indexes--rules)
9. [Debug/Diagnostics Tooling](#9-debugdiagnostics-tooling)
10. [If You Only Have 1 Hour: Quick Start](#10-if-you-only-have-1-hour-quick-start)
11. [Known Bugs / Risk Areas](#11-known-bugs--risk-areas)
12. [Actionable TODO Backlog](#12-actionable-todo-backlog)

---

## 1. High-level Architecture

### App Overview

**CleanSpace** is a marketplace connecting:
- **Clients**: Post jobs and hire cleaners
- **Individual Cleaners**: Apply to jobs, complete work, earn reviews
- **Agencies**: Post jobs on behalf of clients, manage teams

### Main Data Flows

```
Client Flow:
  Create Job → Job Posted (status: 'open') → Workers Apply → 
  Client Accepts Application → Job Assigned (assigned_worker_id set) → 
  Work Done → Client Marks Done → Worker Marks Done → 
  Both Confirm → Job Completed → Reviews Enabled

Worker Flow:
  Browse Available Jobs (status='open', assigned_worker_id=null) → 
  Apply (create Booking) → Wait for Acceptance → 
  Job Assigned → Complete Work → Mark Done → Wait for Client Confirmation → 
  Both Done → Job Completed → Receive Reviews

Agency Flow:
  Similar to Worker + Can Post Jobs (agency_id set, client_id=null)
```

### State Management Approach

**Pattern:** BLoC (Business Logic Component) using `flutter_bloc` package with **Cubit** pattern.

**All Cubits (registered in `main.dart`):**

| Cubit Class | File Path | What It Controls |
|------------|-----------|------------------|
| `ProfilesCubit` | `lib/logic/cubits/profiles_cubit.dart` | Current logged-in user, profile loading |
| `ActiveListingsCubit` | `lib/logic/cubits/agency_dashboard_cubit.dart` | Agency's active jobs (assigned/in-progress) |
| `PastBookingsCubit` | `lib/logic/cubits/agency_dashboard_cubit.dart` | Agency's completed/cancelled jobs |
| `CleanerTeamCubit` | `lib/logic/cubits/agency_dashboard_cubit.dart` | Agency's team members (cleaners) |
| `ListingsCubit` | `lib/logic/cubits/listings_cubit.dart` | Homepage: available jobs, top agencies, top cleaners |
| `SearchCubit` | `lib/logic/cubits/search_cubit.dart` | Search functionality |
| `ClientBookingsCubit` | `lib/logic/cubits/client_bookings_cubit.dart` | Client's bookings/applications |
| `AvailableJobsCubit` | `lib/logic/cubits/available_jobs_cubit.dart` | Available jobs for workers (open jobs) |
| `CleanerHistoryCubit` | `lib/logic/cubits/cleaner_history_cubit.dart` | Worker's job history |
| `CleanerReviewsCubit` | `lib/logic/cubits/cleaner_reviews_cubit.dart` | Reviews for a cleaner (reads `cleaner_reviews` collection) |
| `ClientJobsCubit` | `lib/logic/cubits/client_jobs_cubit.dart` | Client's active/past jobs |
| `JobApplicationsCubit` | `lib/logic/cubits/job_applications_cubit.dart` | Applications for a specific job |
| `WorkerActiveJobsCubit` | `lib/logic/cubits/worker_active_jobs_cubit.dart` | Worker's assigned active jobs |
| `NotificationsCubit` | `lib/logic/cubits/notifications/notifications_cubit.dart` | Notification state, unread count, inbox |

---

## 2. Directory Map

```
lib/
├── core/
│   ├── config/
│   │   └── firebase_config.dart          # Firebase initialization, Firestore instance
│   ├── debug/
│   │   ├── debug_flags.dart              # Debug toggles (enableDebugLogs, enableUIDiagnostics)
│   │   └── debug_logger.dart             # DebugLogger: logs to console + file (.cursor/debug.log)
│   ├── di/
│   │   └── service_locator.dart          # GetIt setup: registers AbstractNotificationsRepo
│   ├── navigation/
│   │   └── app_navigator.dart            # Global navigatorKey for navigation from anywhere
│   ├── routes/
│   │   └── app_routes.dart               # Route definitions (if used)
│   ├── services/
│   │   ├── job_update_notifier.dart      # Job update notifications (if used)
│   │   ├── locale_service.dart           # Localization: save/load locale (en/ar/fr), RTL detection
│   │   ├── notification_backend_service.dart  # FCM HTTP API: sendToUser(), sendToTopic()
│   │   ├── notification_nav_data.dart    # Extract route/jobId/workerId from NotificationItem
│   │   ├── notification_repo.dart        # AbstractNotificationsRepo interface
│   │   ├── notification_repo_db.dart     # ⚠️ Legacy/duplicate? Check usage
│   │   ├── notification_router.dart      # Role-aware routing: navigateFromNotification()
│   │   ├── notification_service.dart     # ⚠️ Legacy/duplicate? Check usage
│   │   └── notification_service_enhanced.dart  # Role-based notification filtering (getNotificationsForWorker/Agency/Client)
│   └── utils/
│       ├── firestore_type.dart           # Type helpers: readInt(), readBool(), readDate(), readString(), readDouble()
│       ├── json_safe.dart                # Safe JSON encoding for Firestore types (FieldValue, Timestamp)
│       └── type_helpers.dart             # Additional type conversion utilities
│
├── data/
│   ├── databases/
│   │   └── database_seeder.dart          # Seeds Firestore with dummy data (jobs, profiles, bookings)
│   ├── models/
│   │   ├── booking_model.dart            # Booking class, BookingStatus enum (pending/inProgress/completed/cancelled)
│   │   ├── cleaner_model.dart            # ⚠️ Check usage (may be legacy)
│   │   ├── cleaner_review.dart           # CleanerReview class (legacy, int cleanerId, date field)
│   │   ├── cleaning_history_item.dart    # CleaningHistoryItem (legacy?)
│   │   ├── job_history_item.dart         # JobHistoryItem (for job_history collection)
│   │   ├── job_model.dart                # Job class, JobStatus enum, toMap/fromMap
│   │   ├── notification_item.dart        # NotificationItem class, NotificationType enum
│   │   ├── profile_model.dart            # ProfileModel class (profiles collection)
│   │   └── review_model.dart             # Review class (new "reviews" collection)
│   │
│   └── repositories/
│       ├── bookings/
│       │   ├── bookings_repo.dart        # AbstractBookingsRepo interface
│       │   └── bookings_repo_db.dart     # BookingsDB: Firestore implementation
│       ├── cleaner_reviews/
│       │   ├── cleaner_reviews_repo.dart # AbstractCleanerReviewsRepo interface
│       │   └── cleaner_reviews_repo_db.dart  # CleanerReviewsDB: reads cleaner_reviews collection
│       ├── cleaners/
│       │   ├── cleaners_repo.dart        # AbstractCleanersRepo interface
│       │   └── cleaners_repo_db.dart     # CleanersDB: Firestore implementation
│       ├── cleaning_history/
│       │   ├── cleaning_history_repo.dart # AbstractCleaningHistoryRepo interface
│       │   └── cleaning_history_repo_db.dart  # CleaningHistoryDB: reads cleaning_history collection
│       ├── jobs/
│       │   ├── jobs_repo.dart            # AbstractJobsRepo interface
│       │   └── jobs_repo_db.dart         # JobsDB: Firestore implementation (CRUD, status transitions)
│       ├── notifications/
│       │   ├── notifications_repo.dart   # AbstractNotificationsRepo interface
│       │   └── notifications_repo_db.dart # NotificationsRepoDB: FCM token management, notification storage
│       ├── profiles/
│       │   ├── profile_repo.dart         # AbstractProfileRepo interface
│       │   └── profile_repo_db.dart      # ProfileDB: Firestore implementation
│       ├── reviews/
│       │   ├── reviews_repo.dart         # AbstractReviewsRepo interface
│       │   └── reviews_repo_db.dart      # ReviewsDB: writes to "reviews" + "cleaner_reviews", updates profile aggregates
│       └── storage/
│           ├── storage_repo.dart         # AbstractStorageRepo interface (Firebase Storage)
│           └── storage_repo_db.dart      # StorageDB: upload/download images
│
├── logic/
│   └── cubits/
│       ├── agency_dashboard_cubit.dart   # ActiveListingsCubit, PastBookingsCubit, CleanerTeamCubit
│       ├── available_jobs_cubit.dart     # AvailableJobsCubit: loads open jobs for workers
│       ├── cleaner_history_cubit.dart    # CleanerHistoryCubit: loads job_history for worker
│       ├── cleaner_reviews_cubit.dart    # CleanerReviewsCubit: loads cleaner_reviews for cleaner
│       ├── client_bookings_cubit.dart    # ClientBookingsCubit: loads bookings for client
│       ├── client_jobs_cubit.dart        # ClientJobsCubit: loads active/past jobs for client
│       ├── job_applications_cubit.dart   # JobApplicationsCubit: loads applications for a job
│       ├── listings_cubit.dart           # ListingsCubit: homepage data (jobs, top agencies, top cleaners)
│       ├── notifications/
│       │   ├── notifications_cubit.dart  # NotificationsCubit: manages notification state
│       │   └── notifications_state.dart  # NotificationsState classes
│       ├── profiles_cubit.dart           # ProfilesCubit: current user management
│       ├── search_cubit.dart             # SearchCubit: search functionality
│       └── worker_active_jobs_cubit.dart # WorkerActiveJobsCubit: loads assigned active jobs for worker
│
├── screens/
│   ├── add-post.dart                     # CreateJobPage: client posts new job
│   ├── add_cleaner_page.dart             # AddCleanerPage: agency adds cleaner to team
│   ├── agency_dashboard_page.dart        # AgencyDashboardPage: main screen for workers/agencies (tabs: Active Listings, Past Bookings, Available Jobs, Profile/Team)
│   ├── booking_details_page.dart         # BookingDetailsPage: shows booking details (requires job Map)
│   ├── bookingdetails.dart               # BookingDetailsScreen: shows booking details
│   ├── cleaner_profile_page.dart         # CleanerProfilePage: public cleaner profile (view by others)
│   ├── cleaner_self_profile_page.dart    # CleanerSelfProfilePage: worker's own profile (tabs: Overview, History, Reviews)
│   ├── client_profile_page.dart          # ClientProfilePage: client's profile/home
│   ├── create_account_page.dart          # CreateAccountPage: user registration
│   ├── data_doctor_page.dart             # DataDoctorPage: diagnostic tool (shows types, repairs legacy data)
│   ├── EditProfilePage.dart              # EditProfilePage: edit user profile
│   ├── experience_page.dart              # ExperiencePage: onboarding screen?
│   ├── feature_page.dart                 # FeaturePage: onboarding screen?
│   ├── find_cleaner_page.dart            # FindCleanerPage: browse cleaners
│   ├── forgot_password.dart              # ForgotPasswordPage: password reset
│   ├── homescreen.dart                   # HomeScreen: main screen for clients
│   ├── job_details_bid_page.dart         # JobDetailsBidPage: worker applies to job
│   ├── jobdetails.dart                   # JobDetailsScreen: shows job details, allows apply/accept/mark done
│   ├── launch_page.dart                  # LaunchPage: splash screen?
│   ├── login.dart                        # LoginPage: user login
│   ├── manage_job_page.dart              # ManageJobPage: client manages job (view applications, accept/reject, mark done)
│   ├── my_listings_page.dart             # MyListingsPage: client's job listings
│   ├── mylistings.dart                   # MyListingsScreen: client's job listings (alternative?)
│   ├── notifications_inbox_page.dart     # NotificationsInboxPage: notification inbox UI
│   ├── onboarding_screen.dart            # OnboardingScreen: first-time user onboarding
│   ├── review_page.dart                  # ReviewPage: submit review for completed job
│   ├── settings_page.dart                # SettingsPage: app settings (locale, etc.)
│   └── welcome_inside.dart               # WelcomeInsidePage: welcome screen?
│
├── utils/
│   ├── age_helper.dart                   # AgeHelper: calculate age from birthdate string
│   ├── algerian_addresses.dart           # Algerian addresses helper (if used)
│   ├── image_helper.dart                 # ImageHelper: image utilities
│   ├── role_based_home.dart              # RoleBasedHome: returns appropriate home screen by role
│   ├── role_based_router.dart            # RoleBasedRouter: route by role (if used)
│   └── validators.dart                   # Form validators
│
├── widgets/
│   ├── notification_bell_widget.dart     # NotificationBellWidget: reusable notification bell with badge
│   └── profile_avatar_widget.dart        # ProfileAvatarWidget: profile picture widget
│
├── l10n/                                 # Localization: app_ar.arb, app_en.arb, app_fr.arb + generated files
└── main.dart                             # App entry point, BlocProvider setup, Firebase init
```

---

## 3. File-by-file Responsibilities

### Data Models

#### `lib/data/models/job_model.dart`
- **Classes:** `Job`, `JobStatus` (enum)
- **What it does:**
  - Represents a job listing with fields: id, title, city, country, description, status, postedDate, jobDate, coverImageUrl, clientId, agencyId, assignedWorkerId, clientDone, workerDone, budgetMin, budgetMax, estimatedHours, requiredServices, isDeleted, createdAt, updatedAt
  - JobStatus enum: `open`, `pending`, `assigned`, `inProgress`, `completedPendingConfirmation`, `completed`, `cancelled` (+ legacy: `active`, `paused`, `booked`)
  - Methods: `toMap()`, `fromMap()`, `copyWith()`, getters: `isAvailableForApplication`, `isCompleted`, `statusLabel`, `fullLocation`
- **Firestore collections:** `jobs`
- **Field type assumptions:**
  - `assigned_worker_id`: `int?` (can be null)
  - `client_done`: `bool` (legacy may have `int` 0/1)
  - `worker_done`: `bool` (legacy may have `int` 0/1)
  - `is_deleted`: `bool` (legacy may have `int` 0/1)
  - `posted_date`: `DateTime` (stored as ISO string)
  - `status`: `String` (enum name, e.g., "open", "assigned")
- **Who calls it:** All job-related repositories, cubits, screens

#### `lib/data/models/booking_model.dart`
- **Classes:** `Booking`, `BookingStatus` (enum)
- **What it does:**
  - Represents a job application/booking with: id, jobId, clientId, providerId, status, bidPrice, message, createdAt, updatedAt
  - BookingStatus enum: `pending`, `inProgress`, `completed`, `cancelled`
  - Methods: `toMap()`, `fromMap()`, `copyWith()`
- **Firestore collections:** `bookings`
- **Field type assumptions:**
  - `job_id`: `int` (required)
  - `client_id`: `int` (required)
  - `provider_id`: `int?` (worker/agency ID)
  - `created_at`: `DateTime` (Firestore Timestamp)
- **Who calls it:** BookingsRepoDB, JobApplicationsCubit, ManageJobPage

#### `lib/data/models/notification_item.dart`
- **Classes:** `NotificationItem`, `NotificationType` (enum)
- **What it does:**
  - Represents a notification with: id, title, body, createdAt, data (route/jobId/etc.), read, type, senderId, jobId, userId
  - NotificationType enum: `jobPublished`, `jobAccepted`, `jobRejected`, `jobCompleted`, `reviewAdded`
  - Methods: `toMap()`, `fromMap()`, `copyWith()`
- **Firestore collections:** `notifications`
- **Field type assumptions:**
  - `user_id`: `String` (recipient user ID)
  - `created_at`: `DateTime` (Firestore Timestamp, may be null - falls back to DateTime.now())
  - `created_at_ms`: `int?` (milliseconds, optional for sorting fallback)
  - `type`: `String?` (e.g., "job_published", "job_accepted")
  - `job_id`: `int?`
- **Who calls it:** NotificationsRepoDB, NotificationsCubit, NotificationRouter

#### `lib/data/models/review_model.dart`
- **Classes:** `Review`
- **What it does:**
  - New review model for "reviews" collection with: id, jobId, bookingId?, reviewerId, reviewerRole, revieweeId, revieweeRole, rating (1-5), comment, photos, createdAt, createdAtMs, status, reviewerUserIdInt?, revieweeUserIdInt?
  - Methods: `toMap()`, `fromMap()`
- **Firestore collections:** `reviews` (new), also written to `cleaner_reviews` (legacy)
- **Field type assumptions:**
  - `reviewer_id`: `String` (user ID as string)
  - `reviewee_id`: `String` (user ID as string, must be parseable to int)
  - `rating`: `int` (1-5)
  - `created_at`: `DateTime?` (set by repository using FieldValue.serverTimestamp())
  - `created_at_ms`: `int?` (milliseconds for stable sorting)
- **Who calls it:** ReviewsRepoDB, ReviewPage

#### `lib/data/models/cleaner_review.dart`
- **Classes:** `CleanerReview`
- **What it does:**
  - Legacy review model for "cleaner_reviews" collection with: id, cleanerId (int), jobId?, reviewerName, rating (double), date (DateTime), comment, hasPhotos, photoUrls, reviewerId?
  - Methods: `toMap()`, `fromMap()`
- **Firestore collections:** `cleaner_reviews` (legacy, still used by profile pages)
- **Field type assumptions:**
  - `cleaner_id`: `int` (required, must be int for queries)
  - `date`: `String` (ISO format) or `DateTime` (Firestore Timestamp) - supports both
  - `rating`: `double`
  - `has_photos`: `int` (0/1, legacy)
- **Who calls it:** CleanerReviewsRepoDB, CleanerReviewsCubit, ReviewsRepoDB (for backward compatibility writes)

#### `lib/data/models/profile_model.dart`
- **Classes:** `ProfileModel`
- **What it does:**
  - Represents user profile with: id, username, password, fullName, email, phone, birthdate, address, bio, gender, userType, agencyName, businessId, services, experienceLevel, hourlyRate, profilePicturePath, idVerificationPath, createdAt, updatedAt
- **Firestore collections:** `profiles`
- **Field type assumptions:**
  - `user_type`: `String` ("Client", "Individual Cleaner", "Agency")
  - `rating_avg`: `double?` (aggregate, updated by ReviewsRepoDB)
  - `rating_count`: `int?` (aggregate, updated by ReviewsRepoDB)
- **Who calls it:** ProfileRepoDB, ProfilesCubit

### Data Repositories

#### `lib/data/repositories/jobs/jobs_repo_db.dart`
- **Classes:** `JobsDB` extends `AbstractJobsRepo`
- **What it does:**
  - CRUD operations for jobs: `createJob()`, `getJobById()`, `updateJob()`, `deleteJob()` (soft delete via `is_deleted`)
  - Query methods: `getAllJobsForAgency()`, `getActiveJobsForAgency()`, `getPastJobsForAgency()`, `getRecentClientJobs()`, `getActiveJobsForWorker()`, `getActiveJobsForClient()`
  - Status transitions: `acceptApplication()` (sets `assigned_worker_id`, status to `assigned`), `markJobStarted()` (status to `inProgress`), `markClientDone()`, `markWorkerDone()` (both update flags and status to `completedPendingConfirmation` or `completed`)
  - Job history: `_addJobToHistory()` (creates entries in `job_history` collection for worker, client, agency)
- **Key functions:**
  - `createJob(Job job)`: Creates job, sends `job_published` notification to agencies, returns created job
  - `acceptApplication(int bookingId)`: Updates job with `assigned_worker_id`, status to `assigned`, sends notifications (called from BookingsRepoDB)
  - `markClientDone(int jobId)`: Uses transaction, sets `client_done=true`, updates status, creates history if both done
  - `markWorkerDone(int jobId)`: Uses transaction, sets `worker_done=true`, updates status, creates history if both done
  - `getActiveJobsForWorker(int workerId)`: Queries `jobs` where `assigned_worker_id==workerId`, `status` in [assigned, inProgress, completedPendingConfirmation], `is_deleted==false`
  - `getActiveJobsForClient(int clientId)`: Queries `jobs` where `client_id==clientId`, `status` not in [completed, cancelled], `is_deleted==false`
- **Firestore collections:** `jobs`, `job_history`, `notifications` (via NotificationBackendService)
- **Who calls it:** All job-related cubits, screens (ManageJobPage, JobDetailsScreen, etc.)

#### `lib/data/repositories/bookings/bookings_repo_db.dart`
- **Classes:** `BookingsDB` extends `AbstractBookingsRepo`
- **What it does:**
  - CRUD operations for bookings: `createBooking()`, `getBookingById()`, `updateBooking()`, `getBookingsForAgency()`, `getBookingsForClient()`, `getApplicationsForJob()`
  - Application acceptance: `acceptApplication(int bookingId)` - uses Firestore transaction to update booking status, set job's `assigned_worker_id`, reject other applications, send notifications
  - Application rejection: `rejectApplication(int bookingId)`
- **Key functions:**
  - `createBooking(Booking booking)`: Creates booking, updates job's `budget_min` if bid is lower, sends notification to client
  - `acceptApplication(int bookingId)`: **Critical function** - uses transaction to atomically:
    1. Read booking → get `job_id`, `provider_id`
    2. Read job → check not already assigned
    3. Update booking status to `inProgress`
    4. Update job: `status='assigned'`, `assigned_worker_id=providerId` (int type)
    5. Reject all other pending applications
    6. Send notifications to worker and client
  - `getApplicationsForJob(int jobId)`: Queries `bookings` where `job_id==jobId`, ordered by `created_at` desc
- **Firestore collections:** `bookings`, `jobs` (updates), `notifications` (via NotificationBackendService)
- **Field type assumptions:**
  - `assigned_worker_id` written as `int` (validated in transaction)
- **Who calls it:** JobApplicationsCubit, ManageJobPage

#### `lib/data/repositories/notifications/notifications_repo_db.dart`
- **Classes:** `NotificationsRepoDB` extends `AbstractNotificationsRepo`
- **What it does:**
  - FCM token management: `initMessaging()`, `requestPermission()`, `getFcmToken()`, `saveTokenToBackend()`
  - Notification storage: `storeReceivedNotification()`, `getStoredNotifications()`, `getUnreadCount()`, `markAsRead()`, `markAllAsRead()`
  - Role-based queries: `getNotificationsForWorker()`, `getNotificationsForAgency()`, `getNotificationsForClient()` (via NotificationServiceEnhanced)
- **Key functions:**
  - `initMessaging()`: Initializes FirebaseMessaging, local notifications, foreground/background handlers
  - `saveTokenToBackend(String userId, String token, String platform)`: Saves to `user_devices` collection with doc ID `${platform}_${userId}`
  - `getStoredNotifications(String userId)`: Uses role-based filtering via NotificationServiceEnhanced, queries `notifications` collection
  - `getUnreadCount(String userId)`: Uses same role-based query, counts `read==false`
- **Firestore collections:** `notifications`, `user_devices`
- **Known issues:**
  - ⚠️ Uses `.get()` (Future) instead of `.snapshots()` (Stream) - UI doesn't update in real-time
  - ⚠️ `created_at` may be null (serverTimestamp not resolved) - falls back to DateTime.now()
- **Who calls it:** NotificationsCubit

#### `lib/data/repositories/reviews/reviews_repo_db.dart`
- **Classes:** `ReviewsDB` extends `AbstractReviewsRepo`
- **What it does:**
  - Review creation: `addReview()` - validates job is completed, writes to BOTH `reviews` (new) and `cleaner_reviews` (legacy), updates profile aggregates
  - Profile aggregate updates: Reads from both collections, deduplicates, calculates `rating_avg` and `rating_count`, updates profile document
- **Key functions:**
  - `addReview({jobId, revieweeId, rating, comment})`:
    1. Validates job exists and is completed (status='completed', clientDone=true, workerDone=true)
    2. Gets reviewer info from SharedPreferences + profile
    3. Writes to `reviews` collection with doc ID `job_{jobId}_reviewer_{reviewerId}`
    4. Also writes to `cleaner_reviews` collection (legacy, for backward compatibility)
    5. Updates profile aggregates in transaction: reads both collections, deduplicates, calculates new averages, updates profile
  - Profile aggregate update uses transaction to ensure consistency
- **Firestore collections:** `reviews`, `cleaner_reviews`, `profiles` (updates), `jobs` (reads for validation)
- **Field type assumptions:**
  - `reviewee_id` must be parseable to int (validated)
  - Profile aggregates: `rating_avg` (double), `rating_count` (int)
- **Who calls it:** ReviewPage

#### `lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart`
- **Classes:** `CleanerReviewsDB` extends `AbstractCleanerReviewsRepo`
- **What it does:**
  - Reads from legacy `cleaner_reviews` collection: `getReviewsForCleaner(int cleanerId)`
  - Used by profile pages that haven't migrated to new `reviews` collection
- **Key functions:**
  - `getReviewsForCleaner(int cleanerId)`: Queries `cleaner_reviews` where `cleaner_id==cleanerId`, ordered by `date` desc (with fallback if index missing)
- **Firestore collections:** `cleaner_reviews`
- **Field type assumptions:**
  - `cleaner_id` must be `int` (validated in query)
  - `date` field can be String (ISO) or Timestamp (supports both)
- **Who calls it:** CleanerReviewsCubit, CleanerProfilePage

### Core Services

#### `lib/core/services/notification_backend_service.dart`
- **Classes:** `NotificationBackendService`
- **What it does:**
  - Sends FCM notifications via HTTP API (FREE - no Cloud Functions needed)
  - Gets FCM tokens from `user_devices` collection, sends push notification, saves notification to Firestore
- **Key functions:**
  - `sendToUser({userId, title, body, route?, id?, additionalData?})`: Gets tokens for user, sends FCM notification, saves to `notifications` collection
  - `sendToTopic({topic, title, body, data?})`: Sends to FCM topic
- **Firestore collections:** `user_devices` (reads), `notifications` (writes)
- **Security note:** FCM Server Key hardcoded (should be moved to environment variable or Cloud Functions in production)
- **Who calls it:** JobsRepoDB, BookingsRepoDB, ReviewsRepoDB

#### `lib/core/services/notification_router.dart`
- **Classes:** `NotificationRouter`
- **What it does:**
  - Role-aware navigation from notifications: `navigateFromNotification()`, `navigateToRoute()`, `handleMessage()`, `handleInitialMessage()`
  - Maps notification types + user roles to appropriate screens
- **Key functions:**
  - `navigateFromNotification(BuildContext context, NotificationItem notification)`: Main entry point - parses notification data, determines user role, routes to appropriate screen based on type + role:
    - `job_published`: Client → ManageJobPage, Worker/Agency → JobDetailsScreen
    - `job_accepted`: Client → ManageJobPage, Worker → AgencyDashboardPage (Active Listings tab), Agency → ManageJobPage or AgencyDashboardPage
    - `job_completed`: Client → ReviewPage (if fully completed), Worker → CleanerSelfProfilePage (History tab), Agency → AgencyDashboardPage (Past Bookings tab)
    - `review_added`: Worker → CleanerSelfProfilePage (Reviews tab), Client/Agency → CleanerProfilePage
  - `_normalizeUserRole(String? role)`: Normalizes role strings ("Individual Cleaner", "Worker", "Agency", "Client")
- **Who calls it:** NotificationsInboxPage, main.dart (FirebaseMessaging.onMessageOpenedApp)

#### `lib/core/services/notification_service_enhanced.dart`
- **Classes:** `NotificationServiceEnhanced`
- **What it does:**
  - Role-based notification filtering: `getNotificationsForWorker()`, `getNotificationsForAgency()`, `getNotificationsForClient()`
  - Filters notifications by `type` field based on user role (e.g., workers get `job_accepted`, clients get `job_published`)
- **Who calls it:** NotificationsRepoDB

### Logic Cubits

#### `lib/logic/cubits/profiles_cubit.dart`
- **Classes:** `ProfilesCubit` extends `Cubit<ProfilesState>`
- **What it does:**
  - Manages current logged-in user: `loadCurrentUser()` (reads from SharedPreferences key `current_user_id`)
  - State: `ProfilesInitial`, `ProfilesLoading`, `ProfilesLoaded(currentUser)`, `ProfilesError`
- **Who calls it:** main.dart (_CheckAuthScreen), all screens that need current user

#### `lib/logic/cubits/notifications/notifications_cubit.dart`
- **Classes:** `NotificationsCubit` extends `Cubit<NotificationsState>`
- **What it does:**
  - Manages notification state: `initialize()`, `refreshInbox()`, `markAsRead()`, `markAllAsRead()`
  - State: `NotificationsInitial`, `NotificationsLoading`, `NotificationsReady(permissionGranted, fcmToken, notifications, unreadCount)`, `NotificationsError`
- **Known issues:**
  - ⚠️ Uses `.get()` instead of streams - UI doesn't update in real-time when new notifications arrive
- **Who calls it:** NotificationsInboxPage, NotificationBellWidget

#### `lib/logic/cubits/worker_active_jobs_cubit.dart`
- **Classes:** `WorkerActiveJobsCubit` extends `Cubit<WorkerActiveJobsState>`
- **What it does:**
  - Loads active jobs for worker: `loadActiveJobs(int workerId)` - calls `JobsRepoDB.getActiveJobsForWorker()`
  - State: `WorkerActiveJobsInitial`, `WorkerActiveJobsLoading`, `WorkerActiveJobsLoaded(jobs)`, `WorkerActiveJobsError`
- **Known issues:**
  - ⚠️ Uses `.get()` instead of streams - UI doesn't update when job status changes
- **Who calls it:** AgencyDashboardPage (Active Listings tab)

#### `lib/logic/cubits/client_jobs_cubit.dart`
- **Classes:** `ClientJobsCubit` extends `Cubit<ClientJobsState>`
- **What it does:**
  - Loads active/past jobs for client: `loadClientJobs(int clientId)`, `refresh(int clientId)` - calls `JobsRepoDB.getActiveJobsForClient()`
  - State: `ClientJobsInitial`, `ClientJobsLoading`, `ClientJobsLoaded(activeJobs, pastJobs)`, `ClientJobsError`
- **Known issues:**
  - ⚠️ Uses `.get()` instead of streams - UI doesn't update when job status changes
- **Who calls it:** ClientProfilePage, ManageJobPage, HomeScreen

### Screens

#### `lib/screens/manage_job_page.dart`
- **Classes:** `ManageJobPage` extends `StatefulWidget`
- **What it does:**
  - Client's job management screen: view applications, accept/reject, mark job done, submit review
  - Shows job details, list of applications (via JobApplicationsCubit), action buttons
  - Key flows:
    - Accept application: calls `JobApplicationsCubit.acceptApplication()` → `BookingsRepoDB.acceptApplication()` → updates job `assigned_worker_id`
    - Mark client done: calls `JobsRepoDB.markClientDone()`
    - Submit review: navigates to ReviewPage (only if job is completed and both flags true)
- **Who calls it:** NotificationRouter (for `job_published`, `job_accepted` when user is client)

#### `lib/screens/review_page.dart`
- **Classes:** `ReviewPage` extends `StatefulWidget`
- **What it does:**
  - Review submission screen: rating (1-5 stars), comment, submit
  - Validates job is completed (status='completed', clientDone=true, workerDone=true) before allowing submission
  - Calls `ReviewsRepoDB.addReview()` on submit
- **Who calls it:** ManageJobPage, NotificationRouter (for `job_completed` when user is client)

#### `lib/screens/notifications_inbox_page.dart`
- **Classes:** `NotificationsInboxPage` extends `StatefulWidget`
- **What it does:**
  - Notification inbox UI: lists notifications, marks as read, navigates on tap via `NotificationRouter.navigateFromNotification()`
  - Uses `NotificationsCubit` to load notifications
- **Who calls it:** NotificationBellWidget, NotificationRouter

#### `lib/screens/data_doctor_page.dart`
- **Classes:** `DataDoctorPage` extends `StatefulWidget`
- **What it does:**
  - Diagnostic tool: shows current user ID, collection counts, last 5 jobs/bookings with type information
  - Repair function: fixes legacy data (String → int conversions, missing fields, type mismatches)
  - Copy diagnostics to clipboard
- **Usage:** Navigate manually for debugging (not exposed in production UI)

---

## 4. Firestore Schema (As Implemented)

### Collection: `jobs`

**Document ID:** Integer as string (e.g., "123")

**Required fields:**
- `id`: `int` (same as doc ID)
- `title`: `String`
- `city`: `String`
- `country`: `String`
- `description`: `String`
- `status`: `String` (enum: "open", "pending", "assigned", "inProgress", "completedPendingConfirmation", "completed", "cancelled")
- `posted_date`: `String` (ISO format) or `DateTime` (Timestamp)
- `job_date`: `String` (ISO format) or `DateTime` (Timestamp)

**Optional fields:**
- `client_id`: `int?` (null if agency-owned)
- `agency_id`: `int?` (null if client-owned)
- `assigned_worker_id`: `int?` (null if not assigned, set when application accepted)
- `client_done`: `bool` (default: false, legacy may have `int` 0/1)
- `worker_done`: `bool` (default: false, legacy may have `int` 0/1)
- `is_deleted`: `bool` (default: false, legacy may have `int` 0/1)
- `cover_image_url`: `String?`
- `budget_min`: `double?`
- `budget_max`: `double?`
- `estimated_hours`: `int?`
- `required_services`: `String?` (comma-separated)
- `created_at`: `String?` (ISO format) or `DateTime` (Timestamp)
- `updated_at`: `String?` (ISO format) or `DateTime` (Timestamp)

**Example:**
```json
{
  "id": 123,
  "title": "House Cleaning",
  "city": "Algiers",
  "country": "Algeria",
  "description": "Deep cleaning needed",
  "status": "assigned",
  "posted_date": "2024-01-15T10:00:00Z",
  "job_date": "2024-01-20T09:00:00Z",
  "client_id": 1,
  "agency_id": null,
  "assigned_worker_id": 5,
  "client_done": false,
  "worker_done": false,
  "is_deleted": false,
  "budget_min": 2000.0,
  "budget_max": 3000.0,
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

### Collection: `bookings`

**Document ID:** Integer as string (e.g., "456")

**Required fields:**
- `id`: `int` (same as doc ID)
- `job_id`: `int` (must be int, not string)
- `client_id`: `int` (must be int, not string)
- `status`: `String` (enum: "pending", "inProgress", "completed", "cancelled")
- `created_at`: `DateTime` (Timestamp)
- `updated_at`: `DateTime` (Timestamp)

**Optional fields:**
- `provider_id`: `int?` (worker/agency ID)
- `bid_price`: `double?`
- `message`: `String?`

**Example:**
```json
{
  "id": 456,
  "job_id": 123,
  "client_id": 1,
  "provider_id": 5,
  "status": "pending",
  "bid_price": 2500.0,
  "message": "I can start tomorrow",
  "created_at": "2024-01-16T14:00:00Z",
  "updated_at": "2024-01-16T14:00:00Z"
}
```

### Collection: `notifications`

**Document ID:** Auto-generated (Firestore-generated ID)

**Required fields:**
- `user_id`: `String` (recipient user ID)
- `title`: `String`
- `body`: `String`
- `read`: `bool` (default: false)
- `created_at`: `DateTime` (Timestamp, may be null if serverTimestamp not resolved)

**Optional fields:**
- `type`: `String?` ("job_published", "job_accepted", "job_rejected", "job_completed", "review_added")
- `sender_id`: `String?`
- `job_id`: `int?`
- `created_at_ms`: `int?` (milliseconds, for stable sorting fallback)
- `data_json`: `Map<String, dynamic>?` (contains route, id, etc.)

**Example:**
```json
{
  "user_id": "5",
  "title": "Application Accepted!",
  "body": "Congratulations! Your application for \"House Cleaning\" has been accepted.",
  "type": "job_accepted",
  "sender_id": "1",
  "job_id": 123,
  "read": false,
  "created_at": "2024-01-16T15:00:00Z",
  "data_json": {
    "route": "/jobDetails",
    "id": "123"
  }
}
```

### Collection: `profiles`

**Document ID:** Integer as string (e.g., "1")

**Required fields:**
- `id`: `int` (same as doc ID)
- `username`: `String`
- `password`: `String` (⚠️ stored in plaintext - should be hashed in production)
- `full_name`: `String`
- `user_type`: `String` ("Client", "Individual Cleaner", "Agency")
- `created_at`: `String` (ISO format)

**Optional fields:**
- `email`: `String?`
- `phone`: `String?`
- `birthdate`: `String?`
- `address`: `String?`
- `bio`: `String?`
- `gender`: `String?`
- `agency_name`: `String?`
- `business_id`: `String?`
- `services`: `String?`
- `experience_level`: `String?`
- `hourly_rate`: `String?`
- `profile_picture_path`: `String?`
- `id_verification_path`: `String?`
- `rating_avg`: `double?` (aggregate, updated by ReviewsRepoDB)
- `rating_count`: `int?` (aggregate, updated by ReviewsRepoDB)
- `updated_at`: `String?` (ISO format)

### Collection: `reviews` (NEW)

**Document ID:** Deterministic ID format: `job_{jobId}_reviewer_{reviewerId}`

**Required fields:**
- `job_id`: `int`
- `reviewer_id`: `String` (user ID as string)
- `reviewer_role`: `String` ("Client", "Agency", "Individual Cleaner")
- `reviewee_id`: `String` (user ID as string, must be parseable to int)
- `reviewee_role`: `String` ("Agency", "Individual Cleaner")
- `rating`: `int` (1-5)
- `comment`: `String`
- `status`: `String` (default: "active")
- `created_at`: `DateTime` (Timestamp, set by repository)
- `created_at_ms`: `int` (milliseconds, for stable sorting)

**Optional fields:**
- `booking_id`: `int?`
- `photos`: `List<String>` (default: empty)
- `reviewer_user_id_int`: `int?` (numeric user ID for backward compatibility)
- `reviewee_user_id_int`: `int?` (numeric user ID for backward compatibility)

### Collection: `cleaner_reviews` (LEGACY)

**Document ID:** Deterministic ID format: `job_{jobId}_reviewer_{reviewerId}` (same as reviews)

**Required fields:**
- `cleaner_id`: `int` (must be int for queries)
- `rating`: `double`
- `date`: `String` (ISO format) - primary field for ordering
- `comment`: `String`

**Optional fields:**
- `id`: `int?`
- `job_id`: `int?`
- `reviewer_name`: `String?`
- `reviewer_id`: `int?`
- `has_photos`: `int` (0/1, legacy)
- `photo_urls`: `String?` (comma-separated)
- `created_at`: `DateTime?` (Timestamp, for future use)
- `created_at_ms`: `int?` (milliseconds, for stable sorting fallback)

**Note:** ReviewsRepoDB writes to BOTH collections for backward compatibility.

### Collection: `job_history`

**Document ID:** Auto-generated (Firestore-generated ID)

**Required fields:**
- `job_id`: `int`
- `participant_user_id`: `int` (worker/client/agency ID)
- `role`: `String` ("Client", "Individual Cleaner", "Agency")
- `completed_at`: `DateTime` (Timestamp)

**Optional fields:**
- `title`: `String?`
- `other_party_id`: `int?`

### Collection: `user_devices`

**Document ID:** Format: `${platform}_${userId}` (e.g., "android_5")

**Required fields:**
- `user_id`: `String`
- `fcm_token`: `String`
- `platform`: `String` ("android" or "ios")
- `updated_at`: `DateTime` (Timestamp)

---

## 5. Notifications System (Deep Dive)

### FCM Token Generation & Storage

**Where:** `NotificationsRepoDB.initMessaging()` → `FirebaseMessaging.instance.getToken()`

**Storage:** `saveTokenToBackend(userId, token, platform)` → saves to `user_devices` collection with doc ID `${platform}_${userId}`

**When:** Called from `NotificationsCubit.initialize()` when app starts (if user is logged in)

### Notification Creation Flow

1. **Event occurs** (job created, application accepted, job completed, review added)
2. **Service calls** `NotificationBackendService.sendToUser()` or similar
3. **Backend service:**
   - Gets FCM tokens from `user_devices` collection for the user
   - Sends FCM push notification via HTTP API (FCM Server Key in code)
   - Saves notification document to `notifications` collection with:
     - `user_id` (recipient)
     - `type` (e.g., "job_accepted")
     - `job_id`, `sender_id` (if applicable)
     - `created_at` (FieldValue.serverTimestamp())
     - `data_json` (route, id for navigation)
4. **Device receives** FCM notification:
   - **Foreground:** `FirebaseMessaging.onMessage` → shows local notification
   - **Background:** `firebaseMessagingBackgroundHandler` (top-level function)
   - **Terminated:** `FirebaseMessaging.instance.getInitialMessage()` → handled in `main.dart`

### Navigation Routing

**Entry point:** `NotificationRouter.navigateFromNotification(context, notification)`

**Process:**
1. Parse notification data via `NotificationNavData.fromNotification()`
2. Get current user role from `ProfilesCubit`
3. Route based on `type` + `role`:
   - `job_published` + Client → `ManageJobPage`
   - `job_published` + Worker/Agency → `JobDetailsScreen`
   - `job_accepted` + Client → `ManageJobPage`
   - `job_accepted` + Worker → `AgencyDashboardPage` (tab 0: Active Listings)
   - `job_completed` + Client → `ReviewPage` (if fully completed)
   - `job_completed` + Worker → `CleanerSelfProfilePage` (tab 1: History)
   - `review_added` + Worker → `CleanerSelfProfilePage` (tab 2: Reviews)

**Screens:** `lib/screens/notifications_inbox_page.dart` uses `NotificationRouter.navigateFromNotification()` when user taps notification

### Role-based Filtering

**Service:** `NotificationServiceEnhanced`

**Methods:**
- `getNotificationsForWorker(userId)`: Filters by `type` in ["job_accepted", "job_rejected", "job_completed", "review_added"]
- `getNotificationsForAgency(userId)`: Filters by `type` in ["job_published", "job_accepted", "job_completed", "review_added"]
- `getNotificationsForClient(userId)`: Filters by `type` in ["job_published", "job_accepted", "job_completed", "review_added"]

**Used by:** `NotificationsRepoDB.getStoredNotifications()`

### Why Delays Happen

1. **Future.get() vs Streams:** ⚠️ NotificationsRepoDB uses `.get()` instead of `.snapshots()` - UI doesn't update in real-time when new notifications arrive. User must manually refresh.
2. **serverTimestamp null issue:** When notification is created, `created_at` is set to `FieldValue.serverTimestamp()`. If read immediately, it may be `null` (not resolved yet). Code falls back to `DateTime.now()` but this can cause sorting issues.
3. **Missing indexes:** Queries with `orderBy('created_at')` require composite indexes. If missing, queries may fail or use fallback (no orderBy).
4. **Incorrect sorting:** If `created_at` is null or not properly set, notifications may appear in wrong order.

### Current Implementation Status

- ✅ FCM token generation and storage
- ✅ Notification creation and sending
- ✅ Role-based filtering
- ✅ Navigation routing
- ⚠️ **MISSING:** Real-time streams (uses `.get()` instead of `.snapshots()`)
- ⚠️ **MISSING:** Proper handling of serverTimestamp null values in queries
- ⚠️ **TODO:** Add `created_at_ms` field and use it for stable sorting when `created_at` is null

---

## 6. Jobs / Bookings Flow (Deep Dive)

### Create Job Flow (Client)

1. **Screen:** `add-post.dart` (CreateJobPage)
2. **User fills form:** title, city, country, description, job date, budget, etc.
3. **Submit:** Calls `JobsRepoDB.createJob(Job(...))`
4. **Repository:**
   - Creates job document in `jobs` collection
   - Sets `status='open'`, `client_id=currentUserId`, `agency_id=null`
   - Sends `job_published` notification to all agencies (via NotificationBackendService)
5. **UI refresh:** Calls `ClientJobsCubit.refresh()` → reloads client's jobs

### Apply/Bid Flow (Worker/Agency)

1. **Screen:** `job_details_bid_page.dart` or `jobdetails.dart` (JobDetailsScreen)
2. **User views job:** Clicks "Apply" or "Bid"
3. **Submit:** Calls `BookingsRepoDB.createBooking(Booking(...))`
4. **Repository:**
   - Creates booking document in `bookings` collection
   - Sets `status='pending'`, `job_id`, `client_id`, `provider_id=currentUserId`
   - Updates job's `budget_min` if bid is lower than current min
   - Sends notification to client (new application received)
5. **UI refresh:** Client sees new application in ManageJobPage

### Accept Application Flow (Client)

1. **Screen:** `manage_job_page.dart` (ManageJobPage)
2. **Client views applications:** List of bookings with status='pending' for the job
3. **Client clicks "Accept":** Calls `JobApplicationsCubit.acceptApplication(bookingId, jobId)`
4. **Cubit:** Calls `BookingsRepoDB.acceptApplication(bookingId)`
5. **Repository (uses Firestore transaction):**
   - Read booking → get `job_id`, `provider_id`
   - Read job → verify not already assigned
   - Update booking: `status='inProgress'`
   - Update job: `status='assigned'`, `assigned_worker_id=providerId` (int type)
   - Reject all other pending applications (set status='cancelled')
   - Send notifications to worker and client
6. **UI refresh:** 
   - Job disappears from "Available Jobs" (status changed, assigned_worker_id set)
   - Job appears in worker's "Active Listings" (if using streams, otherwise requires refresh)
   - Client's job status updates to "Assigned"

**Where `assigned_worker_id` is set:** `BookingsRepoDB.acceptApplication()` → updates job document with `assigned_worker_id=providerId` (int type, validated in transaction)

### Active Jobs Queries

**For Worker:** `JobsRepoDB.getActiveJobsForWorker(workerId)`
- Query: `jobs` where `assigned_worker_id==workerId`, `status` in ["assigned", "inProgress", "completedPendingConfirmation"], `is_deleted==false`
- Used by: `WorkerActiveJobsCubit`, AgencyDashboardPage (Active Listings tab)

**For Client:** `JobsRepoDB.getActiveJobsForClient(clientId)`
- Query: `jobs` where `client_id==clientId`, `status` not in ["completed", "cancelled"], `is_deleted==false`
- Used by: `ClientJobsCubit`, ClientProfilePage, ManageJobPage

**For Agency:** `JobsRepoDB.getActiveJobsForAgency(agencyId)`
- Query: `jobs` where `agency_id==agencyId`, `client_id==null`, plus jobs with bookings for agency
- Used by: `ActiveListingsCubit`, AgencyDashboardPage (Active Listings tab)

### Known Mismatch: ActiveListings vs Assigned Jobs

**Issue:** AgencyDashboardPage "Active Listings" tab may show jobs that are not assigned to the worker.

**Current behavior:**
- `ActiveListingsCubit` uses `JobsRepoDB.getActiveJobsForAgency()` which includes:
  - Agency-owned jobs (where `agency_id==agencyId`, `client_id==null`)
  - Jobs with bookings for the agency (where agency has a booking with status='pending' or 'inProgress')
- This may include jobs where `assigned_worker_id` is null or different worker

**Expected behavior (for Individual Cleaner):**
- Should only show jobs where `assigned_worker_id==currentUserId`

**Fix needed:**
- For Individual Cleaner role, use `WorkerActiveJobsCubit` instead of `ActiveListingsCubit`
- Or modify `getActiveJobsForAgency()` to filter by `assigned_worker_id` when user is Individual Cleaner

---

## 7. Reviews Flow (Deep Dive)

### ReviewPage Submission Path

1. **Screen:** `review_page.dart` (ReviewPage)
2. **User fills form:** rating (1-5 stars), comment
3. **Validation:** Checks job is completed:
   - `job.status == JobStatus.completed`
   - `job.clientDone == true`
   - `job.workerDone == true`
4. **Submit:** Calls `ReviewsRepoDB.addReview({jobId, revieweeId, rating, comment})`

### Validation Rules

**Only completed jobs:** Review can only be submitted if:
- Job status is "completed"
- Both `client_done` and `worker_done` are `true`

**Enforced in:**
- `ReviewPage._loadJob()`: Shows error message if job not completed
- `ReviewsRepoDB.addReview()`: Throws exception if job not completed

### Where Review is Written

**ReviewsRepoDB.addReview()** writes to BOTH collections:

1. **NEW collection: `reviews`**
   - Doc ID: `job_{jobId}_reviewer_{reviewerId}`
   - Fields: `job_id`, `reviewer_id` (string), `reviewee_id` (string), `rating` (int 1-5), `comment`, `created_at` (Timestamp), `created_at_ms` (int)
   - Used for: Future use, proper data model

2. **LEGACY collection: `cleaner_reviews`**
   - Doc ID: `job_{jobId}_reviewer_{reviewerId}` (same format)
   - Fields: `cleaner_id` (int), `rating` (double), `date` (ISO string), `comment`
   - Used for: Backward compatibility with existing profile pages that use CleanerReviewsCubit

**Why both:** Profile pages still read from `cleaner_reviews` collection. ReviewsRepoDB writes to both to ensure reviews appear immediately on profiles.

### Profile Aggregate Updates

**Process:**
1. Review is saved to both collections
2. `ReviewsRepoDB.addReview()` reads current profile aggregates (`rating_avg`, `rating_count`)
3. Queries BOTH collections for all reviews for this reviewee:
   - `reviews` where `reviewee_id==revieweeId`
   - `cleaner_reviews` where `cleaner_id==revieweeIdInt`
4. Deduplicates by `job_id + reviewer_id` (same review may exist in both collections)
5. Calculates new aggregates:
   - `rating_avg = sum(ratings) / count`
   - `rating_count = count`
6. Updates profile document in transaction to ensure consistency

**Fields updated:** `rating_avg` (double), `rating_count` (int)

### Why Reviews Might Not Appear on Profile

1. **Collection mismatch:** ⚠️ Profile pages use `CleanerReviewsCubit` which reads from `cleaner_reviews` collection. If review was only written to `reviews`, it won't appear. **Fix:** ReviewsRepoDB writes to both (already implemented).

2. **cleaner_id type mismatch:** ⚠️ `cleaner_reviews` queries require `cleaner_id` to be `int`. If `revieweeId` is a string that can't be parsed to int, write will fail. **Fix:** ReviewsRepoDB validates `revieweeId` is parseable to int (already implemented).

3. **Query/index issues:** ⚠️ `cleaner_reviews` query uses `orderBy('date')`. If index is missing, query may fail or use fallback (no orderBy). **Fix:** Index is in `firestore.indexes.json` (needs to be deployed).

4. **Profile aggregate update failed:** ⚠️ If transaction fails or profile document doesn't exist, aggregates won't update. **Fix:** ReviewsRepoDB uses transaction and handles errors (already implemented).

### Required Indexes

**For `reviews` collection:**
- `reviewee_id` (Ascending), `created_at` (Descending)
- `reviewer_id` (Ascending), `created_at` (Descending)
- `job_id` (Ascending)

**For `cleaner_reviews` collection:**
- `cleaner_id` (Ascending), `date` (Descending)

**All indexes are defined in `firestore.indexes.json` and need to be deployed:**
```bash
firebase deploy --only firestore:indexes
```

---

## 8. Firestore Indexes & Rules

### Composite Indexes (from firestore.indexes.json)

**Already defined (need to be deployed):**

1. **Notifications:**
   - `user_id` (Asc), `type` (Asc), `created_at` (Desc)
   - `user_id` (Asc), `read` (Asc), `created_at` (Desc)

2. **Jobs:**
   - `assigned_worker_id` (Asc), `status` (Asc), `is_deleted` (Asc), `posted_date` (Desc) - for worker active jobs
   - `client_id` (Asc), `status` (Asc), `is_deleted` (Asc), `posted_date` (Desc) - for client active jobs
   - `client_id` (Asc), `is_deleted` (Asc), `posted_date` (Desc) - for client all jobs
   - `agency_id` (Asc), `status` (Asc), `is_deleted` (Asc), `assigned_worker_id` (Asc) - for agency jobs
   - `assigned_worker_id` (Asc), `is_deleted` (Asc), `status` (Asc) - for worker jobs (alternative)

3. **Job History:**
   - `participant_user_id` (Asc), `role` (Asc), `completed_at` (Desc)

4. **Bookings:**
   - `job_id` (Asc), `created_at` (Desc)

5. **Reviews:**
   - `reviewee_id` (Asc), `created_at` (Desc)
   - `reviewer_id` (Asc), `created_at` (Desc)

6. **Cleaner Reviews (Legacy):**
   - `cleaner_id` (Asc), `date` (Desc)

**Deploy command:**
```bash
firebase deploy --only firestore:indexes
```

### Firestore Rules (firestore.rules)

**Current rules (permissive - for development only):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ SECURITY WARNING:** Current rules allow any authenticated user to read/write all documents. For production, implement proper rules based on:
- User ownership (client_id, assigned_worker_id, user_id)
- Role-based permissions
- Field validation

**Recommended rules structure:**
- `jobs`: Users can read jobs where they are client/worker/agency, can create if client, can update if owner/assigned worker
- `bookings`: Users can read bookings for their jobs, can create if worker, can update if client/worker
- `notifications`: Users can only read their own notifications
- `profiles`: Users can read any profile, can update only their own (or aggregate fields via transaction)
- `reviews`: Users can read any review, can create if reviewer and job is completed

---

## 9. Debug/Diagnostics Tooling

### DebugLogger

**File:** `lib/core/debug/debug_logger.dart`

**What it does:**
- Logs to console (via `print()`)
- Logs to in-memory ring buffer (max 500 entries)
- Logs to file: `.cursor/debug.log` (NDJSON format, one line per log entry)

**Usage:**
```dart
DebugLogger.log('TagName', 'MESSAGE', data: {'key': 'value'});
DebugLogger.error('TagName', 'MESSAGE', exception, stackTrace, data: {'key': 'value'});
```

**Safe for Firestore types:** Uses `JsonSafe` to handle FieldValue, Timestamp, etc.

**Dump logs:**
```dart
String allLogs = DebugLogger.dump(); // Returns NDJSON string
```

### DataDoctorPage

**File:** `lib/screens/data_doctor_page.dart`

**What it shows:**
- Current user ID (from SharedPreferences and Cubit)
- Collection counts (jobs, bookings, profiles)
- Last 5 jobs with field types (client_id, assigned_worker_id, status, is_deleted, etc.)
- Last 5 bookings with field types (job_id, client_id, provider_id, status, etc.)

**Repair function:**
- Scans all jobs and bookings
- Fixes type mismatches: String → int conversions
- Adds missing fields: `is_deleted=false`, `assigned_worker_id=null`, `created_at` (serverTimestamp), etc.
- Shows repair count after completion

**How to use:**
1. Navigate to DataDoctorPage (not exposed in production UI - add manually or via debug menu)
2. View diagnostics (auto-loaded on init)
3. Click "Repair Legacy Data" button to fix type mismatches
4. Click copy icon to copy all diagnostics to clipboard

**Where logs are checked:**
- Console output: Standard Flutter console
- File: `.cursor/debug.log` (NDJSON format)
- In-memory buffer: `DebugLogger.dump()` returns all logs as string

### Debug Flags

**File:** `lib/core/debug/debug_flags.dart`

**Flags:**
- `enableDebugLogs`: Enable detailed debug logging (default: false)
- `enableUIDiagnostics`: Enable UI diagnostic overlays (default: false)

**Usage:**
```dart
if (DebugFlags.debugPrint) {
  print('Debug message');
}
```

---

## 10. If You Only Have 1 Hour: Quick Start

### Environment Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Firebase setup:**
   - Ensure `android/app/google-services.json` exists (for Android)
   - Ensure Firebase project is configured in Firebase Console
   - **Deploy Firestore indexes (CRITICAL):**
     ```bash
     firebase deploy --only firestore:indexes
     ```

3. **Run app:**
   ```bash
   flutter run
   ```

### Where Secrets/Config Are

- **FCM Server Key:** Hardcoded in `lib/core/services/notification_backend_service.dart` and `lib/data/repositories/notifications/notifications_repo_db.dart` (line 21)
  - ⚠️ **SECURITY:** Move to environment variable or Cloud Functions in production
- **Firebase config:** `android/app/google-services.json` (auto-generated from Firebase Console)
- **Debug log file:** `.cursor/debug.log` (created automatically)

### Most Important Flows to Test

1. **Job creation → Application → Acceptance:**
   - Login as Client → Create job → Logout
   - Login as Worker → Browse available jobs → Apply to job
   - Login as Client → View applications → Accept application
   - **Verify:** Job appears in worker's "Active Listings" (may require refresh if not using streams)

2. **Job completion → Review:**
   - Worker marks job done → Client marks job done
   - **Verify:** Both flags true, status="completed"
   - Client navigates to ReviewPage → Submit review
   - **Verify:** Review appears on worker's profile (check both `reviews` and `cleaner_reviews` collections)
   - **Verify:** Worker's `rating_avg` and `rating_count` updated in profile

3. **Notifications:**
   - Trigger notification (accept application, complete job, etc.)
   - **Verify:** Notification appears in inbox (may require manual refresh)
   - Tap notification → **Verify:** Routes to correct screen based on role + type

### Common Gotchas

1. **Type mismatches:** Legacy data may have String IDs instead of int, bool as int (0/1). Use `DataDoctorPage` to repair.

2. **serverTimestamp ordering:** When notification is created with `FieldValue.serverTimestamp()`, if read immediately, `created_at` may be `null`. Code falls back to `DateTime.now()` but sorting may be incorrect. Use `created_at_ms` field for stable sorting.

3. **Missing indexes:** Queries with `orderBy()` require composite indexes. If missing, queries fail or use fallback (no orderBy). **Deploy indexes before testing.**

4. **Soft delete:** Jobs are soft-deleted (`is_deleted=true`), not actually deleted. Queries filter by `is_deleted==false`.

5. **Assigned jobs not showing:** For Individual Cleaner, "Active Listings" may use `ActiveListingsCubit` which shows agency jobs, not assigned jobs. Use `WorkerActiveJobsCubit` instead.

6. **Reviews not appearing:** Ensure review is written to BOTH `reviews` and `cleaner_reviews` collections (ReviewsRepoDB does this, but verify).

7. **Notification delays:** Notifications use `.get()` instead of streams, so UI doesn't update in real-time. User must manually refresh inbox.

---

## 11. Known Bugs / Risk Areas

### Critical Issues

1. **Notifications not updating in real-time:**
   - **Issue:** `NotificationsRepoDB` uses `.get()` instead of `.snapshots()` (streams)
   - **Impact:** UI doesn't update when new notifications arrive. User must manually refresh.
   - **Files:** `lib/data/repositories/notifications/notifications_repo_db.dart`
   - **Fix:** Replace `.get()` with `.snapshots()` in `getStoredNotifications()`, `getUnreadCount()`, and update `NotificationsCubit` to listen to stream

2. **serverTimestamp null in notifications:**
   - **Issue:** When notification is created with `FieldValue.serverTimestamp()`, if read immediately, `created_at` may be `null`
   - **Impact:** Sorting by `created_at` fails, notifications may appear in wrong order
   - **Files:** `lib/data/repositories/notifications/notifications_repo_db.dart`, `lib/data/models/notification_item.dart`
   - **Fix:** Always set `created_at_ms` field (milliseconds) and use it for sorting when `created_at` is null

3. **ActiveListings vs Assigned Jobs mismatch:**
   - **Issue:** For Individual Cleaner, "Active Listings" tab shows agency jobs instead of assigned jobs
   - **Impact:** Worker doesn't see their assigned jobs in Active Listings
   - **Files:** `lib/screens/agency_dashboard_page.dart`, `lib/logic/cubits/agency_dashboard_cubit.dart`
   - **Fix:** For Individual Cleaner role, use `WorkerActiveJobsCubit` instead of `ActiveListingsCubit`

4. **Reviews collections mismatch (partially fixed):**
   - **Issue:** Profile pages read from `cleaner_reviews`, new reviews written to `reviews`
   - **Status:** Fixed - ReviewsRepoDB writes to both collections
   - **Risk:** If write to `cleaner_reviews` fails, review won't appear on profile
   - **Files:** `lib/data/repositories/reviews/reviews_repo_db.dart`

5. **Type mismatches in legacy data:**
   - **Issue:** Legacy jobs/bookings may have String IDs instead of int, bool as int (0/1)
   - **Impact:** Queries fail, type errors
   - **Fix:** Use `DataDoctorPage` to repair, or add migration script

### Medium Priority Issues

6. **FCM Server Key hardcoded:**
   - **Issue:** FCM Server Key is hardcoded in two files
   - **Security risk:** Exposed in client code
   - **Files:** `lib/core/services/notification_backend_service.dart`, `lib/data/repositories/notifications/notifications_repo_db.dart`
   - **Fix:** Move to environment variable or Cloud Functions

7. **Password stored in plaintext:**
   - **Issue:** `profiles` collection stores password in plaintext
   - **Security risk:** Passwords are visible in Firestore
   - **File:** `lib/data/models/profile_model.dart`
   - **Fix:** Hash passwords before storing (use bcrypt or similar)

8. **Missing Firestore security rules:**
   - **Issue:** Current rules allow any authenticated user to read/write all documents
   - **Security risk:** Users can modify other users' data
   - **File:** `firestore.rules`
   - **Fix:** Implement proper role-based rules

9. **Worker active jobs not updating in real-time:**
   - **Issue:** `WorkerActiveJobsCubit` uses `.get()` instead of streams
   - **Impact:** UI doesn't update when job status changes
   - **Files:** `lib/logic/cubits/worker_active_jobs_cubit.dart`, `lib/data/repositories/jobs/jobs_repo_db.dart`
   - **Fix:** Replace `.get()` with `.snapshots()` and listen to stream in cubit

10. **Client jobs not updating in real-time:**
    - **Issue:** `ClientJobsCubit` uses `.get()` instead of streams
    - **Impact:** UI doesn't update when job status changes
    - **Files:** `lib/logic/cubits/client_jobs_cubit.dart`, `lib/data/repositories/jobs/jobs_repo_db.dart`
    - **Fix:** Replace `.get()` with `.snapshots()` and listen to stream in cubit

### Low Priority Issues

11. **Duplicate notification services:**
    - **Issue:** Multiple notification service files (`notification_service.dart`, `notification_service_enhanced.dart`, `notification_repo_db.dart`)
    - **Impact:** Confusion about which to use
    - **Fix:** Consolidate or document which is primary

12. **Legacy review model still used:**
    - **Issue:** `CleanerReview` model and `cleaner_reviews` collection still used by profile pages
    - **Impact:** Need to maintain two review systems
    - **Fix:** Migrate profile pages to use new `reviews` collection, then remove legacy code

13. **Missing error handling:**
    - **Issue:** Some repository methods don't handle Firestore errors gracefully
    - **Impact:** App may crash on network errors or missing data
    - **Fix:** Add try-catch blocks, return empty lists/null instead of throwing

---

## 12. Actionable TODO Backlog

### High Priority (Fix Immediately)

1. **Replace Future.get() with Streams for Notifications:**
   - **Files:** `lib/data/repositories/notifications/notifications_repo_db.dart`, `lib/logic/cubits/notifications/notifications_cubit.dart`
   - **Change:** Replace `getStoredNotifications()` and `getUnreadCount()` to return `Stream<List<NotificationItem>>` and `Stream<int>`, update cubit to listen to streams
   - **Impact:** Notifications update in real-time

2. **Fix serverTimestamp null handling:**
   - **Files:** `lib/data/repositories/notifications/notifications_repo_db.dart`, `lib/core/services/notification_backend_service.dart`
   - **Change:** Always set `created_at_ms` field when creating notification, use it for sorting when `created_at` is null
   - **Impact:** Notifications sort correctly even if serverTimestamp not resolved

3. **Fix ActiveListings for Individual Cleaner:**
   - **Files:** `lib/screens/agency_dashboard_page.dart`
   - **Change:** For Individual Cleaner role, use `WorkerActiveJobsCubit` instead of `ActiveListingsCubit` for Active Listings tab
   - **Impact:** Workers see their assigned jobs correctly

4. **Deploy Firestore indexes:**
   - **Command:** `firebase deploy --only firestore:indexes`
   - **Impact:** Queries with orderBy() work correctly

### Medium Priority (Fix Soon)

5. **Replace Future.get() with Streams for Worker Active Jobs:**
   - **Files:** `lib/data/repositories/jobs/jobs_repo_db.dart`, `lib/logic/cubits/worker_active_jobs_cubit.dart`
   - **Change:** `getActiveJobsForWorker()` returns `Stream<List<Job>>`, cubit listens to stream
   - **Impact:** Active jobs update in real-time when status changes

6. **Replace Future.get() with Streams for Client Jobs:**
   - **Files:** `lib/data/repositories/jobs/jobs_repo_db.dart`, `lib/logic/cubits/client_jobs_cubit.dart`
   - **Change:** `getActiveJobsForClient()` returns `Stream<List<Job>>`, cubit listens to stream
   - **Impact:** Client jobs update in real-time when status changes

7. **Move FCM Server Key to environment variable:**
   - **Files:** `lib/core/services/notification_backend_service.dart`, `lib/data/repositories/notifications/notifications_repo_db.dart`
   - **Change:** Use `flutter_dotenv` or similar to load FCM Server Key from `.env` file
   - **Impact:** Security improvement

8. **Implement Firestore security rules:**
   - **File:** `firestore.rules`
   - **Change:** Add role-based rules for each collection (jobs, bookings, notifications, profiles, reviews)
   - **Impact:** Security improvement

9. **Hash passwords before storing:**
   - **Files:** `lib/data/repositories/profiles/profile_repo_db.dart`, `lib/screens/create_account_page.dart`
   - **Change:** Use `bcrypt` or similar to hash passwords before saving to Firestore
   - **Impact:** Security improvement

### Low Priority (Future Improvements)

10. **Migrate profile pages to new reviews collection:**
    - **Files:** `lib/logic/cubits/cleaner_reviews_cubit.dart`, `lib/screens/cleaner_profile_page.dart`, `lib/screens/cleaner_self_profile_page.dart`
    - **Change:** Use `ReviewsRepoDB` instead of `CleanerReviewsRepoDB`, remove legacy `cleaner_reviews` writes
    - **Impact:** Single source of truth for reviews

11. **Consolidate notification services:**
    - **Files:** `lib/core/services/notification_service.dart`, `lib/core/services/notification_service_enhanced.dart`
    - **Change:** Document which is primary, remove duplicates if not used
    - **Impact:** Code clarity

12. **Add comprehensive error handling:**
    - **Files:** All repository files
    - **Change:** Add try-catch blocks, return empty lists/null instead of throwing, log errors
    - **Impact:** Better user experience, fewer crashes

13. **Add integration tests:**
    - **Files:** `test/` directory
    - **Change:** Add tests for critical flows (job creation, application acceptance, review submission)
    - **Impact:** Prevents regressions

---

## Appendix: Quick Reference

### Key File Locations

- **Main entry:** `lib/main.dart`
- **Firebase config:** `lib/core/config/firebase_config.dart`
- **Debug logging:** `lib/core/debug/debug_logger.dart`
- **Type helpers:** `lib/core/utils/firestore_type.dart`
- **Notification routing:** `lib/core/services/notification_router.dart`
- **Job repository:** `lib/data/repositories/jobs/jobs_repo_db.dart`
- **Booking repository:** `lib/data/repositories/bookings/bookings_repo_db.dart`
- **Review repository:** `lib/data/repositories/reviews/reviews_repo_db.dart`
- **Notification repository:** `lib/data/repositories/notifications/notifications_repo_db.dart`

### Common Type Conversions

Use helpers from `lib/core/utils/firestore_type.dart`:
- `readInt(dynamic v)` - Converts int/String/double to int
- `readBool(dynamic v)` - Converts bool/int/String to bool
- `readDate(dynamic v)` - Converts Timestamp/int/String to DateTime
- `readString(dynamic v)` - Converts any to String
- `readDouble(dynamic v)` - Converts double/int/String to double

### Debug Log Format

Logs are written to `.cursor/debug.log` in NDJSON format:
```json
{"timestamp":1234567890,"tag":"ReviewsDB","message":"addReview_START","data":{"jobId":123,"revieweeId":"5","rating":5}}
```

### Firestore Collection Names

- `jobs`
- `bookings`
- `notifications`
- `profiles`
- `reviews` (new)
- `cleaner_reviews` (legacy)
- `job_history`
- `user_devices`

---

**End of Handoff Guide**
