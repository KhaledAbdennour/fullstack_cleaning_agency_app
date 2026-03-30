import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/bookings/bookings_repo.dart';
import '../../data/repositories/cleaners/cleaners_repo.dart';
import 'notification_backend_service.dart';

class NotificationServiceEnhanced {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'notifications';

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
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final notificationData = <String, dynamic>{
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'sender_id': senderId,
        'job_id': jobId,
        'created_at': FieldValue.serverTimestamp(),
        'created_at_ms': nowMillis,
        'read': false,
      };

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

      await _firestore.collection(collectionName).add(notificationData);

      await NotificationBackendService.sendToUser(
        userId: userId,
        title: title,
        body: body,
        route: route,
        id: routeId,
        skipSave: true,
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

  static Future<List<NotificationItem>> getNotificationsForWorker(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where(
            'type',
            whereIn: [
              NotificationType.jobAssigned.value,
              NotificationType.jobCompleted.value,
              NotificationType.jobMarkedDone.value,
              NotificationType.jobDeleted.value,
              NotificationType.reviewReceived.value,
            ],
          )
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      final jobsRepo = AbstractJobsRepo.getInstance();
      final bookingsRepo = AbstractBookingsRepo.getInstance();

      final filteredNotifications = <NotificationItem>[];
      final userIdInt = int.tryParse(userId);

      for (final notification in allNotifications) {
        if (notification.jobId == null) {
          continue;
        }

        bool shouldInclude = false;

        try {
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null && job.assignedWorkerId == userIdInt) {
            shouldInclude = true;
          }

          if (!shouldInclude) {
            final bookings = await bookingsRepo.getApplicationsForJob(
              notification.jobId!,
            );
            if (bookings.any((b) => b.providerId == userIdInt)) {
              shouldInclude = true;
            }
          }

          if (!shouldInclude &&
              notification.type == NotificationType.reviewReceived.value) {
            if (job != null && job.assignedWorkerId == userIdInt) {
              shouldInclude = true;
            }
          }

          if (shouldInclude) {
            filteredNotifications.add(notification);
          }
        } catch (e) {
          print(
            'Error checking job interaction for notification ${notification.id}: $e',
          );
        }
      }

      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for worker: $e');
      return [];
    }
  }

  static Future<List<NotificationItem>> getNotificationsForAgency(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where(
            'type',
            whereIn: [
              NotificationType.jobAssigned.value,
              NotificationType.jobCompleted.value,
              NotificationType.jobMarkedDone.value,
              NotificationType.jobDeleted.value,
              NotificationType.reviewReceived.value,
            ],
          )
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      final jobsRepo = AbstractJobsRepo.getInstance();
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final cleanersRepo = AbstractCleanersRepo.getInstance();
      final userIdInt = int.tryParse(userId);

      final teamCleaners = userIdInt != null
          ? await cleanersRepo.getCleanersForAgency(userIdInt)
          : [];
      final teamCleanerIds =
          teamCleaners.map((c) => c.id).whereType<int>().toSet();

      final filteredNotifications = <NotificationItem>[];

      for (final notification in allNotifications) {
        if (notification.jobId == null) {
          continue;
        }

        bool shouldInclude = false;

        try {
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null &&
              job.assignedWorkerId != null &&
              teamCleanerIds.contains(job.assignedWorkerId)) {
            shouldInclude = true;
          }

          if (!shouldInclude) {
            final bookings = await bookingsRepo.getApplicationsForJob(
              notification.jobId!,
            );
            if (bookings.any(
              (b) =>
                  b.providerId != null && teamCleanerIds.contains(b.providerId),
            )) {
              shouldInclude = true;
            }
          }

          if (!shouldInclude &&
              notification.type == NotificationType.reviewReceived.value) {
            if (job != null &&
                job.assignedWorkerId != null &&
                teamCleanerIds.contains(job.assignedWorkerId)) {
              shouldInclude = true;
            }
          }

          if (shouldInclude) {
            filteredNotifications.add(notification);
          }
        } catch (e) {
          print(
            'Error checking job interaction for notification ${notification.id}: $e',
          );
        }
      }

      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for agency: $e');
      return [];
    }
  }

  static Future<List<NotificationItem>> getNotificationsForClient(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where(
            'type',
            whereIn: [
              NotificationType.jobApplication.value,
              NotificationType.jobAssigned.value,
              NotificationType.jobMarkedDone.value,
              NotificationType.jobCompleted.value,
              NotificationType.jobDeleted.value,
            ],
          )
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final allNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationItem.fromMap(data);
      }).toList();

      final jobsRepo = AbstractJobsRepo.getInstance();
      final userIdInt = int.tryParse(userId);

      final filteredNotifications = <NotificationItem>[];

      for (final notification in allNotifications) {
        if (notification.jobId == null) {
          continue;
        }

        try {
          final job = await jobsRepo.getJobById(notification.jobId!);
          if (job != null && job.clientId == userIdInt) {
            filteredNotifications.add(notification);
          }
        } catch (e) {
          print(
            'Error checking job ownership for notification ${notification.id}: $e',
          );
        }
      }

      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications.take(50).toList();
    } catch (e) {
      print('Error getting notifications for client: $e');
      return [];
    }
  }

  static Future<List<NotificationItem>> getNotificationsForUser(
    String userId,
  ) async {
    try {
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

  static Future<int> getUnreadCountForUser(String userId) async {
    try {
      final notifications = await getNotificationsForUser(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(collectionName).doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

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
