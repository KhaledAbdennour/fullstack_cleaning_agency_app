import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/bookings/bookings_repo.dart';
import '../../data/repositories/cleaners/cleaners_repo.dart';
import 'notification_backend_service.dart';

/// Enhanced notification service with role-based selectors and lifecycle triggers
class NotificationServiceEnhanced {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'notifications';

  /// Create and send a notification with proper schema
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? senderId,
    int? jobId,
    int? bookingId,
    int? workerId,
    int? clientId,
    int? agencyId,
    String? route,
    String? routeId,
  }) async {
    try {
      // Prepare notification data
      // Store both serverTimestamp (for accurate server time) and client timestamp (for immediate ordering)
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final notificationData = <String, dynamic>{
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'sender_id': senderId,
        'job_id': jobId,
        'created_at': FieldValue.serverTimestamp(),
        'created_at_ms': nowMillis, // Fallback for immediate sorting before serverTimestamp resolves
        'read': false,
      };

      // Build comprehensive route data for navigation
      final routeData = <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        if (route != null) 'route': route,
        if (routeId != null) 'id': routeId,
        if (jobId != null) 'job_id': jobId.toString(),
        if (bookingId != null) 'booking_id': bookingId.toString(),
        if (workerId != null) 'worker_id': workerId.toString(),
        if (clientId != null) 'client_id': clientId.toString(),
        if (agencyId != null) 'agency_id': agencyId.toString(),
      };

      if (routeData.isNotEmpty) {
        notificationData['data_json'] = routeData;
      }

      // Save to Firestore
      await _firestore.collection(collectionName).add(notificationData);

      // Send push notification via FCM (skip saving since we already saved above)
      await NotificationBackendService.sendToUser(
        userId: userId,
        title: title,
        body: body,
        route: route,
        id: routeId,
        skipSave: true, // Already saved to Firestore above, skip duplicate save
        additionalData: {
          'type': type.value,
          'sender_id': senderId,
          'job_id': jobId?.toString(),
        },
      );
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notifications for Worker role
  /// Workers receive notifications for jobs they interacted with (applied, assigned, or reviewed)
  /// - job_assigned (when client assigns job to them)
  /// - job_completed (when job they worked on is completed)
  /// - job_marked_done (when client marks job as done)
  /// - job_deleted (when job they interacted with is deleted)
  /// - review_received (when someone reviews them)
  static Future<List<NotificationItem>> getNotificationsForWorker(String userId) async {
    try {
      // Get all notifications for this worker
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobAssigned.value,
            NotificationType.jobCompleted.value,
            NotificationType.jobMarkedDone.value,
            NotificationType.jobDeleted.value,
            NotificationType.reviewReceived.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(100) // Get more to filter by job interaction
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      // Filter: Only show notifications for jobs this worker interacted with
      // A worker interacts with a job if:
      // - They applied to it (booking exists)
      // - They were assigned to it (job.assigned_worker_id == userId)
      // - They reviewed it (review exists)
      final jobsRepo = AbstractJobsRepo.getInstance();
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      
      final filteredNotifications = <NotificationItem>[];
      final userIdInt = int.tryParse(userId);
      
      for (final notification in allNotifications) {
        // Only process notifications that have a jobId (required for filtering)
        if (notification.jobId == null) {
          // Skip notifications without jobId - they can't be verified
          continue;
        }
        
        bool shouldInclude = false;
        
        try {
          // Check if worker was assigned to this job
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null && job.assignedWorkerId == userIdInt) {
            shouldInclude = true;
          }
          
          // If not assigned, check if worker applied to this job
          if (!shouldInclude) {
            final bookings = await bookingsRepo.getApplicationsForJob(notification.jobId!);
            if (bookings.any((b) => b.providerId == userIdInt)) {
              shouldInclude = true;
            }
          }
          
          // For review_received, verify it's actually for this worker
          if (!shouldInclude && notification.type == NotificationType.reviewReceived.value) {
            // Review received notifications are sent to the worker who was reviewed
            // The notification.userId should already match, but verify via job if possible
            if (job != null && job.assignedWorkerId == userIdInt) {
              shouldInclude = true;
            }
          }
          
          // Only include if verified
          if (shouldInclude) {
            filteredNotifications.add(notification);
          }
        } catch (e) {
          print('Error checking job interaction for notification ${notification.id}: $e');
          // If check fails, DO NOT include notification - be strict about filtering
          // This prevents wrong users from seeing notifications
        }
      }
      
      // Sort by date and limit to 50
      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for worker: $e');
      return [];
    }
  }

  /// Get notifications for Agency role
  /// Agencies receive notifications for jobs they interacted with (applied, assigned, or reviewed)
  /// - job_assigned (when client assigns job to their worker)
  /// - job_completed (when job their worker worked on is completed)
  /// - job_marked_done (when client marks job as done)
  /// - job_deleted (when job they interacted with is deleted)
  /// - review_received (when someone reviews their worker)
  static Future<List<NotificationItem>> getNotificationsForAgency(String userId) async {
    try {
      // Get all notifications for this agency
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobAssigned.value,
            NotificationType.jobCompleted.value,
            NotificationType.jobMarkedDone.value,
            NotificationType.jobDeleted.value,
            NotificationType.reviewReceived.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(100) // Get more to filter by job interaction
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      // Filter: Only show notifications for jobs this agency interacted with
      // An agency interacts with a job if:
      // - Their worker applied to it (booking exists with provider_id from their team)
      // - Their worker was assigned to it (job.assigned_worker_id is in their team)
      // - Their worker reviewed it (review exists)
      final jobsRepo = AbstractJobsRepo.getInstance();
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final cleanersRepo = AbstractCleanersRepo.getInstance();
      final userIdInt = int.tryParse(userId);
      
      // Get all cleaners in this agency's team
      final teamCleaners = userIdInt != null ? await cleanersRepo.getCleanersForAgency(userIdInt) : [];
      final teamCleanerIds = teamCleaners.map((c) => c.id).whereType<int>().toSet();
      
      final filteredNotifications = <NotificationItem>[];
      
      for (final notification in allNotifications) {
        // Only process notifications that have a jobId (required for filtering)
        if (notification.jobId == null) {
          // Skip notifications without jobId - they can't be verified
          continue;
        }
        
        bool shouldInclude = false;
        
        try {
          // Check if any worker from this agency was assigned to this job
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null && job.assignedWorkerId != null && teamCleanerIds.contains(job.assignedWorkerId)) {
            shouldInclude = true;
          }
          
          // If not assigned, check if any worker from this agency applied to this job
          if (!shouldInclude) {
            final bookings = await bookingsRepo.getApplicationsForJob(notification.jobId!);
            if (bookings.any((b) => b.providerId != null && teamCleanerIds.contains(b.providerId))) {
              shouldInclude = true;
            }
          }
          
          // For review_received, verify it's for a worker in their team
          if (!shouldInclude && notification.type == NotificationType.reviewReceived.value) {
            if (job != null && job.assignedWorkerId != null && teamCleanerIds.contains(job.assignedWorkerId)) {
              shouldInclude = true;
            }
          }
          
          // Only include if verified
          if (shouldInclude) {
            filteredNotifications.add(notification);
          }
        } catch (e) {
          print('Error checking job interaction for notification ${notification.id}: $e');
          // If check fails, DO NOT include notification - be strict about filtering
        }
      }
      
      // Sort by date and limit to 50
      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for agency: $e');
      return [];
    }
  }

  /// Get notifications for Client role
  /// Clients receive notifications only for jobs they created (their posts)
  /// - job_application (when cleaner/agency applies to their job)
  /// - job_assigned (when they assign job to cleaner/agency)
  /// - job_marked_done (when cleaner/agency marks job as done)
  /// - job_completed (when job is completed)
  /// - job_deleted (when they delete a post)
  static Future<List<NotificationItem>> getNotificationsForClient(String userId) async {
    try {
      // Get all notifications for this client
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobApplication.value,
            NotificationType.jobAssigned.value,
            NotificationType.jobMarkedDone.value,
            NotificationType.jobCompleted.value,
            NotificationType.jobDeleted.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(100) // Get more to filter by job ownership
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      // Filter: Only show notifications for jobs this client created
      final jobsRepo = AbstractJobsRepo.getInstance();
      final userIdInt = int.tryParse(userId);
      
      final filteredNotifications = <NotificationItem>[];
      
      for (final notification in allNotifications) {
        // Only process notifications that have a jobId (required for filtering)
        if (notification.jobId == null) {
          // Skip notifications without jobId - they can't be verified
          continue;
        }
        
        try {
          // Check if this job belongs to the client
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null && job.clientId == userIdInt) {
            // Only include if the job actually belongs to this client
            filteredNotifications.add(notification);
          }
          // If job doesn't belong to client, don't include it
        } catch (e) {
          print('Error checking job ownership for notification ${notification.id}: $e');
          // If check fails, DO NOT include notification - be strict about filtering
          // This prevents wrong users from seeing notifications
        }
      }
      
      // Sort by date and limit to 50
      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for client: $e');
      return [];
    }
  }

  /// Get notifications based on user role (auto-detects role)
  static Future<List<NotificationItem>> getNotificationsForUser(String userId) async {
    try {
      // Get user profile to determine role
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      final userProfile = profiles.firstWhere(
        (p) => p['id'].toString() == userId,
        orElse: () => <String, dynamic>{},
      );

      final userType = userProfile['user_type']?.toString() ?? '';

      switch (userType) {
        case 'Individual Cleaner':
          return await getNotificationsForWorker(userId);
        case 'Agency':
          return await getNotificationsForAgency(userId);
        case 'Client':
          return await getNotificationsForClient(userId);
        default:
          // Fallback: return all notifications
          final snapshot = await _firestore
              .collection(collectionName)
              .where('user_id', isEqualTo: userId)
              .orderBy('created_at', descending: true)
              .limit(50)
              .get();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return NotificationItem.fromMap(data);
          }).toList();
      }
    } catch (e) {
      print('Error getting notifications for user: $e');
      return [];
    }
  }

  /// Get unread count for user (role-based)
  static Future<int> getUnreadCountForUser(String userId) async {
    try {
      final notifications = await getNotificationsForUser(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }
}

