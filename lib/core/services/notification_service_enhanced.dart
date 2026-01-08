import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../config/firebase_config.dart';
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

      // Send push notification via FCM
      await NotificationBackendService.sendToUser(
        userId: userId,
        title: title,
        body: body,
        route: route,
        id: routeId,
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
  /// Workers receive:
  /// - job_accepted (when their application is accepted)
  /// - job_rejected (when their application is rejected)
  /// - job_completed (when job they worked on is completed)
  /// - review_added (when someone reviews them)
  static Future<List<NotificationItem>> getNotificationsForWorker(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobAccepted.value,
            NotificationType.jobRejected.value,
            NotificationType.jobCompleted.value,
            NotificationType.reviewAdded.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting notifications for worker: $e');
      return [];
    }
  }

  /// Get notifications for Agency role
  /// Agencies receive:
  /// - job_published (when new jobs are posted by clients)
  /// - job_accepted (when their worker's application is accepted)
  /// - job_rejected (when their worker's application is rejected)
  /// - job_completed (when their worker completes a job)
  /// - review_added (when someone reviews their worker)
  static Future<List<NotificationItem>> getNotificationsForAgency(String userId) async {
    try {
      // Get all notifications for agency
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobPublished.value,
            NotificationType.jobAccepted.value,
            NotificationType.jobRejected.value,
            NotificationType.jobCompleted.value,
            NotificationType.reviewAdded.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting notifications for agency: $e');
      return [];
    }
  }

  /// Get notifications for Client role
  /// Clients receive:
  /// - job_accepted (when a worker accepts their job)
  /// - job_rejected (when a worker rejects their job)
  /// - job_completed (when their job is completed)
  /// - review_added (when worker reviews them)
  static Future<List<NotificationItem>> getNotificationsForClient(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: [
            NotificationType.jobAccepted.value,
            NotificationType.jobRejected.value,
            NotificationType.jobCompleted.value,
            NotificationType.reviewAdded.value,
          ])
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();
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

