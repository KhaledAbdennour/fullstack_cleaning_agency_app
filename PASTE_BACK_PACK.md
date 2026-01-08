# PASTE_BACK_PACK.md
## CleanSpace App - Complete Fix Implementation

### FILES CHANGED

1. `lib/core/utils/firestore_type.dart` - **NEW** unified type helper
2. `lib/data/models/job_model.dart` - Updated to use `firestore_type.dart`
3. `lib/data/models/booking_model.dart` - Updated to use `firestore_type.dart`
4. `lib/data/models/notification_item.dart` - Updated to use `firestore_type.dart`
5. `lib/data/repositories/bookings/bookings_repo_db.dart` - Added diagnostic logs, type fixes
6. `lib/data/repositories/jobs/jobs_repo_db.dart` - Added diagnostic logs, stream method
7. `lib/data/repositories/notifications/notifications_repo_db.dart` - Added stream methods
8. `lib/logic/cubits/agency_dashboard_cubit.dart` - Fixed ActiveListingsCubit to use assigned jobs
9. `lib/logic/cubits/worker_active_jobs_cubit.dart` - Converted to stream-based
10. `lib/logic/cubits/notifications/notifications_cubit.dart` - Converted to stream-based
11. `lib/screens/agency_dashboard_page.dart` - Use WorkerActiveJobsCubit for assigned jobs
12. `firestore.indexes.json` - Added required composite indexes

---

## EXACT CODE PATCHES

### 1. NEW FILE: `lib/core/utils/firestore_type.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Firestore type conversion helpers
/// Use these for ALL Firestore reads/writes to prevent type mismatches

/// Safely read an int value from Firestore dynamic data
/// Handles: int, String (parseable), double (converts to int)
int? readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  return null;
}

/// Safely read a boolean value from Firestore dynamic data
/// Handles: bool, int (0/1), String ("true"/"1"/"false"/"0")
bool readBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final lower = v.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

/// Safely read a DateTime from Firestore dynamic data
/// Handles: Timestamp, int (milliseconds), String (ISO format)
DateTime? readDate(dynamic v) {
  if (v == null) return null;
  
  // Handle Firestore Timestamp
  if (v is Timestamp) {
    return v.toDate();
  }
  
  // Handle int (milliseconds since epoch)
  if (v is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (e) {
      return null;
    }
  }
  
  // Handle String (ISO format)
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (e) {
      return null;
    }
  }
  
  // Handle DateTime (already parsed)
  if (v is DateTime) {
    return v;
  }
  
  return null;
}

/// Safely read a String value from Firestore dynamic data
String? readString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// Safely read a double value from Firestore dynamic data
double? readDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) {
    return double.tryParse(v);
  }
  return null;
}
```

---

### 2. UPDATE: `lib/data/models/job_model.dart`

**Change import:**
```dart
// OLD:
import '../../core/utils/type_helpers.dart';

// NEW:
import '../../core/utils/firestore_type.dart';
```

**Update fromMap (around line 158-170):**
```dart
// OLD:
clientId: map['client_id'] as int?,
agencyId: map['agency_id'] as int?,
assignedWorkerId: map['assigned_worker_id'] as int?,

// NEW:
clientId: readInt(map['client_id']),
agencyId: readInt(map['agency_id']),
assignedWorkerId: readInt(map['assigned_worker_id']),
```

---

### 3. UPDATE: `lib/data/models/booking_model.dart`

**Change import:**
```dart
// OLD:
import '../../core/utils/type_helpers.dart';

// NEW:
import '../../core/utils/firestore_type.dart';
```

**Replace entire fromMap method (lines 41-98):**
```dart
factory Booking.fromMap(Map<String, dynamic> map) {
  // Use unified type helpers for safe parsing
  final jobId = readInt(map['job_id']);
  if (jobId == null) {
    throw Exception('Invalid job_id in booking: ${map['job_id']} (type: ${map['job_id']?.runtimeType})');
  }
  
  final clientId = readInt(map['client_id']);
  if (clientId == null) {
    throw Exception('Invalid client_id in booking: ${map['client_id']} (type: ${map['client_id']?.runtimeType})');
  }
  
  final providerId = readInt(map['provider_id']);
  
  // Parse dates using unified helper
  final createdAt = readDate(map['created_at']) ?? DateTime.now();
  final updatedAt = readDate(map['updated_at']) ?? DateTime.now();
  
  return Booking(
    id: readInt(map['id']),
    jobId: jobId,
    clientId: clientId,
    providerId: providerId,
    status: BookingStatus.values.firstWhere(
      (e) => e.name == map['status']?.toString(),
      orElse: () => BookingStatus.pending,
    ),
    bidPrice: readDouble(map['bid_price']),
    message: readString(map['message']),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
```

---

### 4. UPDATE: `lib/data/models/notification_item.dart`

**Add import:**
```dart
import '../../core/utils/firestore_type.dart';
```

**Replace fromMap method (lines 46-99):**
```dart
factory NotificationItem.fromMap(Map<String, dynamic> map, {DocumentSnapshot? docSnapshot}) {
  // Parse createdAt using unified helper (supports Timestamp/int/String)
  DateTime? parsedDate = readDate(map['created_at']);
  
  // Fallback to created_at_ms if created_at is null
  if (parsedDate == null && map['created_at_ms'] != null) {
    final ms = map['created_at_ms'];
    parsedDate = readDate(ms);
  }
  
  // Final fallback: use current time (but log warning)
  if (parsedDate == null) {
    print('⚠️ Notification missing created_at, using DateTime.now() - id: ${map['id']}');
    parsedDate = DateTime.now();
  }
  
  return NotificationItem(
    id: readString(map['id']) ?? '',
    title: readString(map['title']) ?? '',
    body: readString(map['body']) ?? '',
    createdAt: parsedDate,
    data: map['data'] != null || map['data_json'] != null
        ? Map<String, dynamic>.from(map['data'] ?? map['data_json'] ?? {})
        : null,
    read: readBool(map['read']),
    type: readString(map['type']),
    senderId: readString(map['sender_id']),
    jobId: readInt(map['job_id']),
    userId: readString(map['user_id']) ?? '',
  );
}
```

---

### 5. UPDATE: `lib/data/repositories/bookings/bookings_repo_db.dart`

**Add diagnostic logs to acceptApplication (around line 381-467):**

Find the section starting with `final bookingData = bookingDoc.data()!;` and replace with:

```dart
final bookingData = bookingDoc.data()!;

// TRUTH LOG: Read booking doc
final jobIdRaw = bookingData['job_id'];
final clientIdRaw = bookingData['client_id'];
final providerIdRaw = bookingData['provider_id'];
final statusBefore = bookingData['status']?.toString();

DebugLogger.log('acceptApplication', 'TX_READ_BOOKING', data: {
  'bookingId': bookingId,
  'job_id': jobIdRaw,
  'job_id_type': jobIdRaw?.runtimeType.toString() ?? 'null',
  'client_id': clientIdRaw,
  'client_id_type': clientIdRaw?.runtimeType.toString() ?? 'null',
  'provider_id': providerIdRaw,
  'provider_id_type': providerIdRaw?.runtimeType.toString() ?? 'null',
  'statusBefore': statusBefore,
});

final jobId = (jobIdRaw is int) ? jobIdRaw : (jobIdRaw is String ? int.tryParse(jobIdRaw) : null);
if (jobId == null) {
  throw Exception('Invalid job_id in booking: $jobIdRaw (type: ${jobIdRaw.runtimeType})');
}

final providerId = (providerIdRaw is int) ? providerIdRaw : (providerIdRaw is String ? int.tryParse(providerIdRaw) : null);
if (providerId == null) {
  throw Exception('Booking has no provider_id: $providerIdRaw (type: ${providerIdRaw.runtimeType})');
}

// Get the job
final jobRef = FirebaseConfig.firestore
    .collection('jobs')
    .doc(jobId.toString());
final jobDoc = await transaction.get(jobRef);

if (!jobDoc.exists) {
  throw Exception('Job not found: $jobId');
}

final jobData = jobDoc.data()!;

// TRUTH LOG: Read job doc BEFORE update
DebugLogger.log('acceptApplication', 'TX_READ_JOB_BEFORE', data: {
  'jobId': jobId,
  'status': jobData['status']?.toString(),
  'assigned_worker_id': jobData['assigned_worker_id'],
  'assigned_worker_id_type': jobData['assigned_worker_id']?.runtimeType.toString() ?? 'null',
  'client_id': jobData['client_id'],
  'client_id_type': jobData['client_id']?.runtimeType.toString() ?? 'null',
  'is_deleted': jobData['is_deleted'],
  'is_deleted_type': jobData['is_deleted']?.runtimeType.toString() ?? 'null',
  'worker_done': jobData['worker_done'],
  'worker_done_type': jobData['worker_done']?.runtimeType.toString() ?? 'null',
  'client_done': jobData['client_done'],
  'client_done_type': jobData['client_done']?.runtimeType.toString() ?? 'null',
});

// ... rest of existing code (check if already assigned) ...

// Update booking to accepted
transaction.update(bookingRef, {
  'status': BookingStatus.inProgress.name,
  'updated_at': FieldValue.serverTimestamp(),
});

// Update job: set status to assigned and assign worker
// Ensure assigned_worker_id is written as int (consistent type)
final jobUpdates = {
  'status': JobStatus.assigned.name,
  'assigned_worker_id': providerId, // Ensure this is int (already validated above)
  'updated_at': FieldValue.serverTimestamp(),
};

// TRUTH LOG: Write job updates
DebugLogger.log('acceptApplication', 'TX_WRITE_JOB', data: {
  'jobId': jobId,
  'updates': {
    'status': jobUpdates['status'],
    'assigned_worker_id': jobUpdates['assigned_worker_id'],
    'assigned_worker_id_type': providerId.runtimeType.toString(),
  },
});

transaction.update(jobRef, jobUpdates);
```

**After transaction (around line 486), add:**

```dart
// TRUTH LOG: Re-read job doc AFTER transaction
final jobsRepo = AbstractJobsRepo.getInstance();
final bookingAfter = await getBookingById(bookingId);
if (bookingAfter != null) {
  final jobAfter = await jobsRepo.getJobById(bookingAfter.jobId);
  if (jobAfter != null) {
    // Re-read raw doc to see actual Firestore values
    final jobDocAfter = await FirebaseConfig.firestore
        .collection('jobs')
        .doc(bookingAfter.jobId.toString())
        .get();
    final jobDataAfter = jobDocAfter.data();
    
    DebugLogger.log('acceptApplication', 'TX_READ_JOB_AFTER', data: {
      'jobId': bookingAfter.jobId,
      'status': jobDataAfter?['status']?.toString(),
      'assigned_worker_id': jobDataAfter?['assigned_worker_id'],
      'assigned_worker_id_type': jobDataAfter?['assigned_worker_id']?.runtimeType.toString() ?? 'null',
      'client_id': jobDataAfter?['client_id'],
      'client_id_type': jobDataAfter?['client_id']?.runtimeType.toString() ?? 'null',
      'is_deleted': jobDataAfter?['is_deleted'],
      'is_deleted_type': jobDataAfter?['is_deleted']?.runtimeType.toString() ?? 'null',
      'worker_done': jobDataAfter?['worker_done'],
      'worker_done_type': jobDataAfter?['worker_done']?.runtimeType.toString() ?? 'null',
      'client_done': jobDataAfter?['client_done'],
      'client_done_type': jobDataAfter?['client_done']?.runtimeType.toString() ?? 'null',
    });
  }
}

// Send notifications (after transaction succeeds)
final booking = bookingAfter ?? await getBookingById(bookingId);
if (booking != null && booking.providerId != null) {
  final job = await jobsRepo.getJobById(booking.jobId);
  // ... rest of notification code ...
}
```

---

### 6. UPDATE: `lib/data/repositories/jobs/jobs_repo_db.dart`

**Change import:**
```dart
// OLD:
import '../../../core/utils/type_helpers.dart';

// NEW:
import '../../../core/utils/firestore_type.dart';
```

**Replace getActiveJobsForWorker method (lines 1092-1122):**

```dart
@override
Future<List<Job>> getActiveJobsForWorker(int workerId) async {
  try {
    // TRUTH LOG: Query start
    DebugLogger.log('getActiveJobsForWorker', 'QUERY_START', data: {
      'workerId': workerId,
      'workerIdType': workerId.runtimeType.toString(),
      'filters': 'assigned_worker_id == $workerId (int), is_deleted == false (bool)',
    });
    
    final snapshot = await FirebaseConfig.firestore
        .collection(collectionName)
        .where('assigned_worker_id', isEqualTo: workerId)
        .where('is_deleted', isEqualTo: false)
        .get();
    
    DebugLogger.log('getActiveJobsForWorker', 'QUERY_RESULT', data: {
      'workerId': workerId,
      'docCount': snapshot.docs.length,
    });
    
    final activeSet = {
      JobStatus.assigned.name,
      JobStatus.inProgress.name,
      JobStatus.completedPendingConfirmation.name,
    };
    final jobs = <Job>[];
    
    for (final doc in snapshot.docs) {
      try {
        final raw = doc.data();
        final data = Map<String, dynamic>.from(raw as Map);
        data['id'] = int.tryParse(doc.id) ?? 0;
        
        // TRUTH LOG: Document fields
        final assignedWorkerIdRaw = data['assigned_worker_id'];
        final statusRaw = data['status']?.toString();
        final isDeletedRaw = data['is_deleted'];
        
        DebugLogger.log('getActiveJobsForWorker', 'DOC_FIELDS', data: {
          'docId': doc.id,
          'assigned_worker_id': assignedWorkerIdRaw,
          'assigned_worker_id_type': assignedWorkerIdRaw?.runtimeType.toString() ?? 'null',
          'status': statusRaw,
          'is_deleted': isDeletedRaw,
          'is_deleted_type': isDeletedRaw?.runtimeType.toString() ?? 'null',
        });
        
        final job = Job.fromMap(data);
        if (activeSet.contains(job.status.name)) {
          jobs.add(job);
          DebugLogger.log('getActiveJobsForWorker', 'JOB_ADDED', data: {
            'jobId': job.id,
            'status': job.status.name,
            'assignedWorkerId': job.assignedWorkerId,
          });
        } else {
          DebugLogger.log('getActiveJobsForWorker', 'JOB_FILTERED_STATUS', data: {
            'jobId': job.id,
            'status': job.status.name,
            'expectedStatuses': activeSet.toList(),
          });
        }
      } catch (e, stack) {
        DebugLogger.error('getActiveJobsForWorker', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
      }
    }
    
    jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
    
    DebugLogger.log('getActiveJobsForWorker', 'QUERY_COMPLETE', data: {
      'workerId': workerId,
      'totalJobs': jobs.length,
    });
    
    return jobs;
  } catch (e, stacktrace) {
    DebugLogger.error('getActiveJobsForWorker', 'ERROR', e, stacktrace, data: {'workerId': workerId});
    return [];
  }
}
```

**ADD NEW METHOD: Stream for active jobs (after getActiveJobsForWorker):**

```dart
/// Get active jobs for worker as a stream (real-time updates)
Stream<List<Job>> getActiveJobsForWorkerStream(int workerId) {
  try {
    DebugLogger.log('getActiveJobsForWorkerStream', 'STREAM_START', data: {
      'workerId': workerId,
      'workerIdType': workerId.runtimeType.toString(),
    });
    
    final activeSet = {
      JobStatus.assigned.name,
      JobStatus.inProgress.name,
      JobStatus.completedPendingConfirmation.name,
    };
    
    return FirebaseConfig.firestore
        .collection(collectionName)
        .where('assigned_worker_id', isEqualTo: workerId)
        .where('is_deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      DebugLogger.log('getActiveJobsForWorkerStream', 'STREAM_UPDATE', data: {
        'workerId': workerId,
        'docCount': snapshot.docs.length,
      });
      
      final jobs = <Job>[];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          final data = Map<String, dynamic>.from(raw as Map);
          data['id'] = int.tryParse(doc.id) ?? 0;
          final job = Job.fromMap(data);
          
          if (activeSet.contains(job.status.name)) {
            jobs.add(job);
          }
        } catch (e, stack) {
          DebugLogger.error('getActiveJobsForWorkerStream', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
        }
      }
      
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      
      DebugLogger.log('getActiveJobsForWorkerStream', 'STREAM_COMPLETE', data: {
        'workerId': workerId,
        'totalJobs': jobs.length,
      });
      
      return jobs;
    });
  } catch (e, stacktrace) {
    DebugLogger.error('getActiveJobsForWorkerStream', 'STREAM_ERROR', e, stacktrace, data: {'workerId': workerId});
    return Stream.value([]);
  }
}
```

**ADD to AbstractJobsRepo interface (`lib/data/repositories/jobs/jobs_repo.dart`):**

```dart
// Add after getActiveJobsForWorker:
Stream<List<Job>> getActiveJobsForWorkerStream(int workerId);
```

---

### 7. UPDATE: `lib/data/repositories/notifications/notifications_repo_db.dart`

**ADD stream methods (after existing getStoredNotifications):**

```dart
/// Get stored notifications as a stream (real-time updates)
Stream<List<NotificationItem>> getStoredNotificationsStream(String userId) {
  try {
    DebugLogger.log('getStoredNotificationsStream', 'STREAM_START', data: {
      'userId': userId,
      'userIdType': userId.runtimeType.toString(),
    });
    
    return FirebaseConfig.firestore
        .collection(collectionName)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at_ms', descending: true)
        .limit(50)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      DebugLogger.log('getStoredNotificationsStream', 'STREAM_UPDATE', data: {
        'userId': userId,
        'docCount': snapshot.docs.length,
        'fromCache': snapshot.metadata.isFromCache,
      });
      
      final notifications = <NotificationItem>[];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          
          // Pass docSnapshot for metadata fallback
          final notification = NotificationItem.fromMap(data, docSnapshot: doc);
          notifications.add(notification);
        } catch (e, stack) {
          DebugLogger.error('getStoredNotificationsStream', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
        }
      }
      
      // Secondary sort by createdAt (in case created_at_ms missing)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      DebugLogger.log('getStoredNotificationsStream', 'STREAM_COMPLETE', data: {
        'userId': userId,
        'totalNotifications': notifications.length,
      });
      
      return notifications;
    });
  } catch (e, stacktrace) {
    DebugLogger.error('getStoredNotificationsStream', 'STREAM_ERROR', e, stacktrace, data: {'userId': userId});
    return Stream.value([]);
  }
}

/// Get unread count as a stream
Stream<int> getUnreadCountStream(String userId) {
  try {
    return FirebaseConfig.firestore
        .collection(collectionName)
        .where('user_id', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  } catch (e) {
    return Stream.value(0);
  }
}
```

**UPDATE createNotification in NotificationServiceEnhanced to always write created_at_ms:**

Ensure this line exists in `lib/core/services/notification_service_enhanced.dart` (around line 144-165):

```dart
'created_at': FieldValue.serverTimestamp(),
'created_at_ms': DateTime.now().millisecondsSinceEpoch, // Add fallback numeric timestamp
'read': false,
```

**ADD to AbstractNotificationsRepo interface (`lib/data/repositories/notifications/notifications_repo.dart`):**

```dart
/// Get stored notifications as a stream (real-time updates)
Stream<List<NotificationItem>> getStoredNotificationsStream(String userId);

/// Get unread count as a stream
Stream<int> getUnreadCountStream(String userId);
```

---

### 8. UPDATE: `lib/logic/cubits/worker_active_jobs_cubit.dart`

**Replace entire file:**

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';

abstract class WorkerActiveJobsState {}

class WorkerActiveJobsInitial extends WorkerActiveJobsState {}

class WorkerActiveJobsLoading extends WorkerActiveJobsState {}

class WorkerActiveJobsLoaded extends WorkerActiveJobsState {
  final List<Job> activeJobs;
  WorkerActiveJobsLoaded(this.activeJobs);
}

class WorkerActiveJobsError extends WorkerActiveJobsState {
  final String message;
  WorkerActiveJobsError(this.message);
}

class WorkerActiveJobsCubit extends Cubit<WorkerActiveJobsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();
  StreamSubscription<List<Job>>? _jobsSubscription;

  WorkerActiveJobsCubit() : super(WorkerActiveJobsInitial());

  /// Start listening to active jobs stream
  void startListening(int workerId) {
    emit(WorkerActiveJobsLoading());
    
    // Cancel existing subscription if any
    _jobsSubscription?.cancel();
    
    // Subscribe to stream
    _jobsSubscription = _jobsRepo.getActiveJobsForWorkerStream(workerId).listen(
      (jobs) {
        emit(WorkerActiveJobsLoaded(jobs));
      },
      onError: (error) {
        emit(WorkerActiveJobsError('Failed to load active jobs: $error'));
      },
    );
  }

  /// Stop listening to stream
  void stopListening() {
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
  }

  /// Refresh (one-shot for pull-to-refresh)
  Future<void> refresh(int workerId) async {
    try {
      final jobs = await _jobsRepo.getActiveJobsForWorker(workerId);
      emit(WorkerActiveJobsLoaded(jobs));
    } catch (e) {
      emit(WorkerActiveJobsError('Failed to refresh active jobs: $e'));
    }
  }

  @override
  Future<void> close() {
    stopListening();
    return super.close();
  }
}
```

---

### 9. UPDATE: `lib/logic/cubits/notifications/notifications_cubit.dart`

**Replace refreshInbox method and add stream subscription:**

```dart
StreamSubscription<List<NotificationItem>>? _notificationsSubscription;
StreamSubscription<int>? _unreadCountSubscription;

/// Start listening to notifications stream
void startListening() {
  final prefs = SharedPreferences.getInstance();
  prefs.then((prefs) {
    final userId = prefs.getInt('current_user_id');
    if (userId == null) return;
    
    // Cancel existing subscriptions
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    
    // Subscribe to notifications stream
    _notificationsSubscription = _repo.getStoredNotificationsStream(userId.toString()).listen(
      (notifications) {
        if (state is NotificationsReady) {
          final currentState = state as NotificationsReady;
          emit(currentState.copyWith(
            notifications: notifications,
            unreadCount: notifications.where((n) => !n.read).length,
          ));
        } else {
          emit(NotificationsReady(
            permissionGranted: true,
            notifications: notifications,
            unreadCount: notifications.where((n) => !n.read).length,
          ));
        }
      },
      onError: (error) {
        emit(NotificationsError('Failed to load notifications: $error'));
      },
    );
    
    // Subscribe to unread count stream
    _unreadCountSubscription = _repo.getUnreadCountStream(userId.toString()).listen(
      (count) {
        if (state is NotificationsReady) {
          final currentState = state as NotificationsReady;
          emit(currentState.copyWith(unreadCount: count));
        }
      },
    );
  });
}

/// Refresh notifications inbox (one-shot for pull-to-refresh)
Future<void> refreshInbox() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    
    if (userId == null) {
      emit(NotificationsReady(
        permissionGranted: (state as NotificationsReady?)?.permissionGranted ?? false,
        fcmToken: (state as NotificationsReady?)?.fcmToken,
        notifications: [],
        unreadCount: 0,
      ));
      return;
    }
    
    final notifications = await _repo.getStoredNotifications(userId.toString());
    final unreadCount = await _repo.getUnreadCount(userId.toString());
    
    if (state is NotificationsReady) {
      final currentState = state as NotificationsReady;
      emit(currentState.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } else {
      emit(NotificationsReady(
        permissionGranted: true,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    }
  } catch (e) {
    emit(NotificationsError('Failed to refresh inbox: $e'));
  }
}

@override
Future<void> close() {
  _notificationsSubscription?.cancel();
  _unreadCountSubscription?.cancel();
  return super.close();
}
```

**UPDATE initialize method to call startListening after init:**

```dart
/// Initialize notifications system
Future<void> initialize() async {
  emit(NotificationsLoading());
  
  try {
    // Initialize messaging
    await _repo.initMessaging();
    
    // Request permissions
    final permissionGranted = await _repo.requestPermission();
    
    // Get FCM token
    final token = await _repo.getFcmToken();
    
    // Save token to backend if user is logged in
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      if (userId != null) {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await _repo.saveTokenToBackend(userId.toString(), token, platform);
      }
    }
    
    // Start listening to stream (replaces one-shot load)
    startListening();
    
  } catch (e) {
    emit(NotificationsError('Failed to initialize notifications: $e'));
  }
}
```

---

### 10. UPDATE: `lib/screens/agency_dashboard_page.dart`

**In _loadAgencyId method, add check for user type and use WorkerActiveJobsCubit for assigned jobs:**

```dart
Future<void> _loadAgencyId() async {
  final cubit = context.read<ProfilesCubit>();
  await cubit.loadCurrentUser();
  if (!mounted) return;
  final state = cubit.state;
  if (state is ProfilesLoaded && state.currentUser != null) {
    setState(() {
      _agencyId = state.currentUser!['id'] as int?;
    });
    if (_agencyId != null && mounted) {
      final userType = state.currentUser!['user_type'] as String?;
      
      // For workers/agencies, load ASSIGNED jobs (not posted jobs)
      if (userType == 'Individual Cleaner' || userType == 'Agency') {
        context.read<WorkerActiveJobsCubit>().startListening(_agencyId!);
      } else {
        // For clients, use posted jobs
        context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
      }
    }
  }
}
```

**Update _buildActiveListingsTab to use WorkerActiveJobsCubit for workers/agencies:**

```dart
Widget _buildActiveListingsTab() {
  if (_agencyId == null) {
    return const Center(child: CircularProgressIndicator());
  }

  final userType = _getUserType();
  
  // For workers/agencies: show ASSIGNED jobs
  if (userType == 'Individual Cleaner' || userType == 'Agency') {
    return BlocBuilder<WorkerActiveJobsCubit, WorkerActiveJobsState>(
      builder: (context, state) {
        if (state is WorkerActiveJobsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorkerActiveJobsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<WorkerActiveJobsCubit>().refresh(_agencyId!);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is WorkerActiveJobsLoaded) {
          if (state.activeJobs.isEmpty) {
            return const Center(
              child: Text(
                'No active jobs assigned yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<WorkerActiveJobsCubit>().refresh(_agencyId!);
            },
            child: ListView.builder(
              controller: _activeListingsScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.activeJobs.length,
              itemBuilder: (context, index) {
                final job = state.activeJobs[index];
                final highlight = widget.highlightJobId != null && job.id == widget.highlightJobId;
                return _buildJobCard(job, highlight: highlight);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  // For clients: show posted jobs (existing code)
  return BlocBuilder<ActiveListingsCubit, ActiveListingsState>(
    // ... existing code ...
  );
}
```

**Add import at top:**

```dart
import '../logic/cubits/worker_active_jobs_cubit.dart';
```

---

### 11. UPDATE: `firestore.indexes.json`

**Add these indexes:**

```json
{
  "indexes": [
    {
      "collectionGroup": "jobs",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "assigned_worker_id",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "is_deleted",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "user_id",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "created_at_ms",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "user_id",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "read",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

---

## REPAIR LEGACY DATA (Optional)

Add to `lib/screens/data_doctor_page.dart` repair function:

```dart
Future<void> _repairLegacyData() async {
  // ... existing confirmation dialog ...
  
  try {
    int jobsRepaired = 0;
    var batch = FirebaseConfig.firestore.batch();
    int batchCount = 0;
    
    final jobsSnapshot = await FirebaseConfig.firestore.collection('jobs').get();
    for (final doc in jobsSnapshot.docs) {
      final data = doc.data();
      bool needsRepair = false;
      final updates = <String, dynamic>{};
      
      // Fix assigned_worker_id: String -> int
      if (data['assigned_worker_id'] is String) {
        final parsed = int.tryParse(data['assigned_worker_id'] as String);
        if (parsed != null) {
          updates['assigned_worker_id'] = parsed;
          needsRepair = true;
        }
      }
      
      // Fix is_deleted: int -> bool
      if (data['is_deleted'] is int) {
        updates['is_deleted'] = (data['is_deleted'] as int) == 1;
        needsRepair = true;
      }
      
      // Fix client_id: String -> int
      if (data['client_id'] is String) {
        final parsed = int.tryParse(data['client_id'] as String);
        if (parsed != null) {
          updates['client_id'] = parsed;
          needsRepair = true;
        }
      }
      
      if (needsRepair) {
        batch.update(doc.reference, updates);
        batchCount++;
        jobsRepaired++;
        
        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseConfig.firestore.batch();
          batchCount = 0;
        }
      }
    }
    
    if (batchCount > 0) {
      await batch.commit();
    }
    
    // Similar for bookings...
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Repaired $jobsRepaired jobs')),
    );
  } catch (e) {
    // Error handling...
  }
}
```

---

## SUMMARY

- **12 files changed**
- **3 new stream methods** (notifications, unread count, worker active jobs)
- **All models updated** to use unified `firestore_type.dart` helpers
- **Active Listings fixed** to show assigned jobs for workers
- **Diagnostic logs added** for acceptApplication and getActiveJobsForWorker
- **Firestore indexes** added for performance

**Next Steps:**
1. Apply all patches
2. Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
3. Run repair legacy data (optional, if type mismatches exist)
4. Test end-to-end flow (see TEST_REPORT.md)
