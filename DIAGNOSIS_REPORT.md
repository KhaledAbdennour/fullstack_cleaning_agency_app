# DIAGNOSIS REPORT
## CleanSpace App - Notification & Active Jobs Issues

### PROBLEM SUMMARY
1. **Accepted jobs don't appear in worker/agency "Active Jobs" view** after client accepts application
2. **Notifications are delayed/slow** when opening inbox, wrong ordering, timeAgo always "just now"
3. **Type mismatches** causing runtime crashes (int vs bool, int vs string)

---

### ROOT CAUSES IDENTIFIED

#### A) Active Jobs Not Showing (Hypothesis H1)
**Issue:** After `acceptApplication()` updates job with `assigned_worker_id`, worker/agency "Active Listings" tab shows empty.

**Root Cause:**
- `ActiveListingsCubit.loadActiveListings()` calls `getActiveJobsForAgency(agencyId)` which queries:
  - `where agency_id == agencyId` (jobs POSTED BY agency)
  - OR bookings with `provider_id == agencyId` and status `inProgress`
- **BUT** for ASSIGNED jobs (from client accepting worker application), the job has:
  - `assigned_worker_id == workerId` (not `agency_id`)
  - `status == 'assigned'` (not `inProgress` or `active`)
- Therefore, `getActiveJobsForAgency` does NOT return assigned jobs.

**Proof from Code:**
- `lib/logic/cubits/agency_dashboard_cubit.dart:68`: `getActiveJobsForAgency(agencyId)`
- `lib/data/repositories/jobs/jobs_repo_db.dart:69-136`: Query filters for `agency_id` and bookings, not `assigned_worker_id`
- `lib/data/repositories/jobs/jobs_repo_db.dart:1092-1122`: `getActiveJobsForWorker` correctly queries `assigned_worker_id` but is NOT used by dashboard

**Expected Firestore Document After Acceptance:**
```json
{
  "id": 123,
  "status": "assigned",
  "assigned_worker_id": 456,  // int
  "agency_id": null,
  "client_id": 789,
  "is_deleted": false  // bool
}
```

**Worker Query Should Be:**
```dart
jobs
  .where('assigned_worker_id', isEqualTo: workerId)  // workerId is int
  .where('is_deleted', isEqualTo: false)  // bool
  // Filter statuses: assigned, inProgress, completedPendingConfirmation
```

**Type Consistency Issue:**
- `acceptApplication()` writes `assigned_worker_id` as `int` (validated)
- But if legacy docs have `assigned_worker_id` as `String` "456", query with `isEqualTo: 456` (int) won't match
- Diagnostic logs will reveal actual types in Firestore vs query parameter

---

#### B) Notifications Delay/Wrong Ordering (Hypothesis H2)
**Issue:** Opening notifications inbox is slow, items not sorted newest-first, timeAgo always "just now".

**Root Cause:**
- `NotificationsCubit.refreshInbox()` uses `_repo.getStoredNotifications()` which is `Future<List<NotificationItem>>` (one-shot `.get()`)
- No real-time stream subscription, so UI only updates on manual refresh
- Sorting relies on `created_at` field which might be `FieldValue.serverTimestamp()` (null until server resolves)
- TimeAgo formatter may be using `DateTime.now()` fallback instead of actual `notification.createdAt`

**Proof from Code:**
- `lib/logic/cubits/notifications/notifications_cubit.dart:66-100`: `refreshInbox()` is one-shot Future
- `lib/data/repositories/notifications/notifications_repo_db.dart:223-250`: Uses `.get()` instead of `.snapshots()`
- `lib/data/models/notification_item.dart:46-81`: `createdAt` parsing has fallback to `DateTime.now()` if all parsing fails

**Expected Behavior:**
- Use `.snapshots()` stream for real-time updates
- Sort by `created_at_ms` (numeric, stable) DESC as primary, `created_at` DESC as secondary
- TimeAgo should use actual `notification.createdAt`, update every minute via `Timer.periodic`

---

#### C) Type Mismatches (Hypothesis H3)
**Issue:** Runtime crashes: "type 'int' is not a subtype of type 'bool'", "type 'String' is not a subtype of type 'int'".

**Root Cause:**
- Firestore documents may have inconsistent types (legacy data):
  - `is_deleted`: stored as `0` (int) instead of `false` (bool)
  - `assigned_worker_id`: stored as `"456"` (String) instead of `456` (int)
  - `client_id`: stored as `"789"` (String) instead of `789` (int)
- Code uses unsafe casts: `map['is_deleted'] as bool` → crashes if value is `0`
- `Job.fromMap`, `Booking.fromMap`, `NotificationItem.fromMap` need safe type parsers

**Proof from Code:**
- `lib/data/models/job_model.dart:179`: Uses `readBool()` (safe) but other fields may still use `as int?`
- `lib/data/models/booking_model.dart:69-82`: Manual parsing with `int.tryParse`, but inconsistent
- `lib/data/repositories/jobs/jobs_repo_db.dart:1097`: Query uses `isEqualTo: workerId` (int) but doc might have String

**Expected Fix:**
- Create unified `lib/core/utils/firestore_type.dart` with:
  - `int? readInt(dynamic v)`: handles int, String, double, null
  - `bool readBool(dynamic v, {bool defaultValue})`: handles bool, int 0/1, String "true"/"false"
  - `DateTime? readDate(dynamic v)`: handles Timestamp, int ms, ISO String
- Replace ALL `as bool`, `as int?` casts in models with these helpers
- Ensure ALL writes use correct types: `is_deleted` as bool, `assigned_worker_id` as int

---

### EVIDENCE TO COLLECT (Diagnostic Logs)

After adding diagnostic logs, run:
1. Agency applies to 2 jobs
2. Client accepts one application
3. Check logs for:
   - `acceptApplication TX_READ_BOOKING`: booking job_id, provider_id, client_id (value + type)
   - `acceptApplication TX_WRITE_JOB`: updates written (assigned_worker_id type)
   - `acceptApplication TX_READ_JOB_AFTER`: job doc after transaction (assigned_worker_id value + type)
   - `getActiveJobsForWorker QUERY_START`: workerId used (value + type)
   - `getActiveJobsForWorker DOC_FIELDS`: each doc's assigned_worker_id (value + type), status
   - `getActiveJobsForWorker QUERY_COMPLETE`: total jobs returned

**Expected Log Pattern if H1 Confirmed:**
```
[acceptApplication] TX_READ_JOB_AFTER | assigned_worker_id: 456, assigned_worker_id_type: int
[getActiveJobsForWorker] QUERY_START | workerId: 456, workerIdType: int
[getActiveJobsForWorker] DOC_FIELDS | assigned_worker_id: null, status: "open"  ← MISMATCH: job not returned
```

**Expected Log Pattern if Type Mismatch (H3):**
```
[acceptApplication] TX_WRITE_JOB | assigned_worker_id: 456, assigned_worker_id_type: int
[acceptApplication] TX_READ_JOB_AFTER | assigned_worker_id: "456", assigned_worker_id_type: String  ← TYPE MISMATCH
[getActiveJobsForWorker] QUERY_START | workerId: 456, workerIdType: int
[getActiveJobsForWorker] QUERY_RESULT | docCount: 0  ← Query fails because int != String
```

---

### WHICH PAGE IS WRONG?

**"Active Listings" Tab (`lib/screens/agency_dashboard_page.dart:568-623`):**
- Uses `ActiveListingsCubit` → `getActiveJobsForAgency(agencyId)`
- This shows jobs POSTED BY agency (where `agency_id == agencyId`)
- **NOT** jobs ASSIGNED TO agency/worker (where `assigned_worker_id == workerId`)

**Correct Behavior:**
- For workers/agencies: "Active Listings" should show ASSIGNED jobs (using `WorkerActiveJobsCubit`)
- Keep separate "My Posted Jobs" for jobs they posted
- OR merge both: show assigned jobs + posted jobs (if desired)

---

### SUMMARY

| Issue | Root Cause | Fix Location |
|-------|------------|--------------|
| Active jobs empty | `ActiveListingsCubit` queries posted jobs, not assigned | `agency_dashboard_cubit.dart`, `agency_dashboard_page.dart` |
| Notifications slow | One-shot `.get()` instead of `.snapshots()` stream | `notifications_repo_db.dart`, `notifications_cubit.dart` |
| TimeAgo "just now" | `createdAt` fallback to `DateTime.now()`, no Timer | `notification_item.dart`, notification tile widget |
| Type crashes | Unsafe casts on dynamic Firestore data | All models: use `firestore_type.dart` helpers |
| Wrong ordering | Sorting by `created_at` (may be null), not `created_at_ms` | `notifications_repo_db.dart`, sort by `created_at_ms DESC` |

