# TEST_REPORT.md
## CleanSpace App - Manual Test Steps

### PREREQUISITES

1. **Deploy Firestore indexes:**
   ```bash
   firebase deploy --only firestore:indexes
   ```
   Wait until indexes are built (check Firebase Console → Firestore → Indexes)

2. **Run repair legacy data (optional):**
   - Open app → Long press app title → Data Doctor page
   - Tap "Repair Legacy Data" button
   - Wait for completion message

3. **Clear app data / Fresh install** (optional, for clean test)

---

### TEST 1: Agency Applies → Client Accepts → Job Appears in Agency Active Jobs

#### Steps:
1. **Login as Client**
   - Create a new job (e.g., "Deep Clean Apartment")
   - Note the job ID from logs or UI

2. **Login as Agency/Worker**
   - Navigate to "Available Jobs" tab
   - Find the job created in step 1
   - Tap "Apply" or "Submit Bid"
   - Verify notification appears (optional)

3. **Login as Client again**
   - Navigate to "My Jobs" → Open the job
   - Tap "View Applications" or "Manage"
   - Verify agency application appears in list
   - Tap "Accept" on the agency application

4. **Login as Agency again (IMPORTANT: Don't logout first, switch accounts if possible)**
   - Navigate to "Active Listings" / "Active Jobs" tab
   - **EXPECTED:** Job should appear IMMEDIATELY (within 1-2 seconds)
   - Verify job shows correct status: "Assigned" or "Active"

#### Verification:
- ✅ Job appears in agency "Active Listings" tab without logout/login
- ✅ Job has `assigned_worker_id` matching agency ID in Firestore
- ✅ Job status is `"assigned"` in Firestore
- ✅ Check logs for:
  ```
  [acceptApplication] TX_READ_JOB_AFTER | assigned_worker_id: <agencyId>, assigned_worker_id_type: int
  [getActiveJobsForWorkerStream] STREAM_UPDATE | docCount: 1
  ```

---

### TEST 2: Notifications Appear Instantly + Correct Ordering

#### Steps:
1. **Login as any user (e.g., Client)**

2. **Generate notifications:**
   - Have another user accept your job application (if worker)
   - OR have a worker apply to your job (if client)
   - OR complete a job and trigger review notification

3. **Open notifications inbox:**
   - Tap bell icon in top-right
   - **EXPECTED:** Inbox opens instantly (< 500ms when cached, < 1s cold start)
   - **EXPECTED:** Notifications appear sorted newest-first (most recent at top)

4. **Verify timeAgo:**
   - Check "time ago" display (e.g., "5 minutes ago", "2 hours ago")
   - **EXPECTED:** Correct relative time, NOT always "just now"
   - Wait 1 minute, reopen inbox
   - **EXPECTED:** Time updates (e.g., "6 minutes ago" → "7 minutes ago")

#### Verification:
- ✅ Inbox opens instantly
- ✅ Notifications sorted newest-first
- ✅ TimeAgo shows correct relative time (not "just now" for old notifications)
- ✅ TimeAgo updates live (without reopening)
- ✅ Check Firestore: `notifications` collection has `created_at_ms` field (numeric)

---

### TEST 3: Worker Marks Done → Client Confirms → Review Opens

#### Steps:
1. **Login as Worker (with active assigned job)**
   - Navigate to "Active Jobs"
   - Open an assigned job
   - Tap "Mark Job Done" or "Complete"
   - Verify job status changes to "Completed - Pending Confirmation"

2. **Login as Client**
   - Navigate to "My Jobs"
   - Open the same job
   - Tap "Confirm Completion" or "Mark Done"
   - **EXPECTED:** Job status becomes "Completed"
   - **EXPECTED:** Review page opens automatically (or button enabled)

3. **Submit Review:**
   - Fill review form (rating, comment)
   - Tap "Submit Review"
   - **EXPECTED:** Review submits successfully (no error about "completedPendingConfirmation")

#### Verification:
- ✅ Job status transitions: `assigned` → `completedPendingConfirmation` → `completed`
- ✅ Review page only opens when status is `completed`
- ✅ Review submission succeeds
- ✅ Check logs:
  ```
  [markClientDone] POST_TX_READ | status: completed, worker_done: true, client_done: true
  ```

---

### TEST 4: Type Safety (No Runtime Crashes)

#### Steps:
1. **Create job as Client**
   - Fill all fields
   - Submit
   - **EXPECTED:** No crashes

2. **Worker applies**
   - Submit bid/application
   - **EXPECTED:** No "Converting object to encodable object failed: FieldValue" error

3. **Client accepts**
   - Tap "Accept" on application
   - **EXPECTED:** No "type 'int' is not a subtype of type 'bool'" error

4. **Check Firestore Console:**
   - Open `jobs` collection
   - Verify fields are correct types:
     - `assigned_worker_id`: number (not string)
     - `is_deleted`: boolean (not 0/1)
     - `client_id`: number (not string)

#### Verification:
- ✅ No runtime type crashes
- ✅ All Firestore fields have correct types
- ✅ Check logs for type information:
  ```
  [acceptApplication] TX_WRITE_JOB | assigned_worker_id_type: int
  [getActiveJobsForWorker] DOC_FIELDS | assigned_worker_id_type: int
  ```

---

### TEST 5: Stream Updates (Real-time)

#### Steps:
1. **Login as Worker/Agency**
   - Navigate to "Active Listings" tab
   - Note current job count

2. **In another session (or have another user):**
   - Client accepts worker application
   - OR job status changes

3. **Back in worker session:**
   - **EXPECTED:** Job list updates automatically (within 1-2 seconds)
   - No manual refresh needed
   - New job appears OR status changes reflect

4. **Test notifications stream:**
   - Open notifications inbox
   - In another session, send a notification to this user
   - **EXPECTED:** Notification appears in inbox automatically

#### Verification:
- ✅ Job list updates in real-time (no manual refresh)
- ✅ Notifications appear instantly (no manual refresh)
- ✅ Stream subscriptions are active (check logs for `STREAM_UPDATE`)

---

### EXPECTED LOG OUTPUTS

#### After Client Accepts Application:
```
[acceptApplication] TX_READ_BOOKING | bookingId: 123, provider_id: 456, provider_id_type: int
[acceptApplication] TX_READ_JOB_BEFORE | jobId: 789, assigned_worker_id: null
[acceptApplication] TX_WRITE_JOB | updates: {status: assigned, assigned_worker_id: 456, assigned_worker_id_type: int}
[acceptApplication] TX_READ_JOB_AFTER | assigned_worker_id: 456, assigned_worker_id_type: int, status: assigned
[getActiveJobsForWorkerStream] STREAM_START | workerId: 456
[getActiveJobsForWorkerStream] STREAM_UPDATE | docCount: 1
[getActiveJobsForWorkerStream] STREAM_COMPLETE | totalJobs: 1
```

#### When Opening Notifications Inbox:
```
[getStoredNotificationsStream] STREAM_START | userId: 789
[getStoredNotificationsStream] STREAM_UPDATE | docCount: 5, fromCache: false
[getStoredNotificationsStream] STREAM_COMPLETE | totalNotifications: 5
```

#### When Worker Opens Active Jobs:
```
[getActiveJobsForWorker] QUERY_START | workerId: 456, workerIdType: int
[getActiveJobsForWorker] QUERY_RESULT | docCount: 2
[getActiveJobsForWorker] DOC_FIELDS | assigned_worker_id: 456, assigned_worker_id_type: int, status: assigned
[getActiveJobsForWorker] JOB_ADDED | jobId: 789, status: assigned
[getActiveJobsForWorker] QUERY_COMPLETE | totalJobs: 2
```

---

### FAILURE SCENARIOS TO CHECK

#### If Active Jobs Still Empty:
- **Check:** Firestore `jobs` collection → job doc → `assigned_worker_id` field:
  - ✅ Value matches worker ID used in query
  - ✅ Type is `number` (not `string`)
  - ✅ `status` is `"assigned"`, `"inProgress"`, or `"completedPendingConfirmation"`
  - ✅ `is_deleted` is `false` (boolean, not 0)
- **Check logs:** `getActiveJobsForWorker DOC_FIELDS` → verify types match query parameter
- **Action:** Run "Repair Legacy Data" if types are wrong

#### If Notifications Slow:
- **Check:** Firestore `notifications` collection → verify `created_at_ms` field exists (numeric)
- **Check logs:** `getStoredNotificationsStream STREAM_UPDATE` → verify `fromCache: false` after first load
- **Action:** Ensure stream subscription is active (check `startListening()` called)

#### If TimeAgo Always "just now":
- **Check:** Notification doc → `created_at` field:
  - ✅ Is `Timestamp` or numeric `created_at_ms`
  - ✅ Not null
- **Check:** `NotificationItem.fromMap` parsing → verify `parsedDate` is not `DateTime.now()` fallback
- **Action:** Verify `created_at_ms` is written when creating notifications

#### If Type Crashes Occur:
- **Check:** Firestore doc fields → verify types match expected:
  - `is_deleted`: boolean (not int)
  - `assigned_worker_id`: number (not string)
  - `client_id`: number (not string)
- **Action:** Run "Repair Legacy Data", verify all models use `firestore_type.dart` helpers

---

### ACCEPTANCE CRITERIA

✅ **All 5 tests pass**
✅ **No runtime crashes**
✅ **Stream updates work in real-time**
✅ **Notifications appear instantly and sorted correctly**
✅ **Active jobs show immediately after acceptance**
✅ **Type safety: no int/bool/string mismatches**
✅ **Logs show correct types and query results**

---

### POST-TEST CHECKLIST

1. ✅ Deploy Firestore indexes (if not done)
2. ✅ Run repair legacy data (if types were wrong)
3. ✅ Verify all diagnostic logs show correct types
4. ✅ Confirm stream subscriptions are active (no manual refresh needed)
5. ✅ Verify Firestore documents have correct types (boolean, number, not string/int/0)

---

## NOTES

- **Logs location:** `.cursor/debug.log` (NDJSON format)
- **Firestore Console:** https://console.firebase.google.com → Your Project → Firestore Database
- **If tests fail:** Check logs for diagnostic output, verify Firestore field types, run repair if needed
