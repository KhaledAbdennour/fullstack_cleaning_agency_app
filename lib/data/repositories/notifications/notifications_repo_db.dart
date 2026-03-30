import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/config/firebase_config.dart';
import '../../../core/debug/debug_flags.dart';
import '../../../core/services/notification_service_enhanced.dart';
import '../../models/notification_item.dart';
import '../../repositories/profiles/profile_repo.dart';
import '../../../local_db/dao/notifications_dao.dart';
import 'notifications_repo.dart';

class NotificationsRepoDB extends AbstractNotificationsRepo {
  static const String collectionName = 'notifications';
  static const String devicesCollectionName = 'user_devices';

  static const String fcmServerKey =
      '6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  @override
  Future<void> initMessaging() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      _messaging.onTokenRefresh.listen((token) {
        _saveTokenToBackendIfLoggedIn(token);
      });

      _initialized = true;
    } catch (e) {
      print('Error initializing messaging: $e');
      rethrow;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }

      return true;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  @override
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Future<void> saveTokenToBackend(
    String userId,
    String token,
    String platform,
  ) async {
    try {
      final deviceId = '${platform}_$userId';

      await FirebaseConfig.firestore
          .collection(devicesCollectionName)
          .doc(deviceId)
          .set({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
        '[NotificationsRepo] FCM token saved to Firestore for user $userId',
      );
    } catch (e) {
      print('Error saving FCM token: $e');
      rethrow;
    }
  }

  @override
  Future<void> storeReceivedNotification(NotificationItem notification) async {
    try {
      await FirebaseConfig.firestore.collection(collectionName).add({
        'user_id': notification.data?['user_id']?.toString() ?? '',
        'title': notification.title,
        'body': notification.body,
        'data_json': notification.data,
        'created_at': Timestamp.fromDate(notification.createdAt),
        'read': notification.read,
      });
    } catch (e) {
      print('Error storing notification: $e');
      rethrow;
    }
  }

  @override
  Future<List<NotificationItem>> getStoredNotifications(String userId) async {
    try {
      final cached = await NotificationsDao.getNotificationsForUser(userId);

      try {
        final profiles =
            await AbstractProfileRepo.getInstance().getAllProfiles();

        final userProfile = profiles.firstWhere(
          (p) => p['id'].toString() == userId,
          orElse: () => <String, dynamic>{},
        );

        final userType = userProfile['user_type']?.toString() ?? '';

        List<NotificationItem> result;
        switch (userType) {
          case 'Individual Cleaner':
            result = await getNotificationsForWorker(userId);
            break;
          case 'Agency':
            result = await getNotificationsForAgency(userId);
            break;
          case 'Client':
            result = await getNotificationsForClient(userId);
            break;
          default:
            try {
              final snapshot = await FirebaseConfig.firestore
                  .collection(collectionName)
                  .where('user_id', isEqualTo: userId)
                  .orderBy('created_at', descending: true)
                  .limit(50)
                  .get();

              result = snapshot.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data() as Map);
                return NotificationItem.fromMap({...data, 'id': doc.id});
              }).toList();
            } catch (e2) {
              try {
                final snapshot = await FirebaseConfig.firestore
                    .collection(collectionName)
                    .where('user_id', isEqualTo: userId)
                    .limit(50)
                    .get();

                result = snapshot.docs.map((doc) {
                  final data = Map<String, dynamic>.from(doc.data() as Map);
                  return NotificationItem.fromMap({...data, 'id': doc.id});
                }).toList();

                result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              } catch (e3) {
                result = cached.isNotEmpty ? cached : [];
              }
            }
        }

        if (result.isNotEmpty) {
          await NotificationsDao.insertNotifications(result);
        }

        return result;
      } catch (e) {
        return cached.isNotEmpty ? cached : [];
      }
    } catch (e, stackTrace) {
      DebugFlags.debugPrint('[getStoredNotifications] ERROR: $e');
      DebugFlags.debugPrint('[getStoredNotifications] Stack: $stackTrace');
      return [];
    }
  }

  @override
  Future<List<NotificationItem>> getNotificationsForWorker(
    String userId,
  ) async {
    return await NotificationServiceEnhanced.getNotificationsForWorker(userId);
  }

  @override
  Future<List<NotificationItem>> getNotificationsForAgency(
    String userId,
  ) async {
    return await NotificationServiceEnhanced.getNotificationsForAgency(userId);
  }

  @override
  Future<List<NotificationItem>> getNotificationsForClient(
    String userId,
  ) async {
    return await NotificationServiceEnhanced.getNotificationsForClient(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseConfig.firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await getStoredNotifications(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnostics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('current_user_id');

      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      final userProfile = profiles.firstWhere(
        (p) => p['id'].toString() == userId,
        orElse: () => <String, dynamic>{},
      );
      final userType = userProfile['user_type']?.toString() ?? 'Unknown';

      final allNotificationsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .get();

      final unreadSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final filteredNotifications = await getStoredNotifications(userId);

      Map<String, dynamic>? sampleDoc;
      if (allNotificationsSnapshot.docs.isNotEmpty) {
        final doc = allNotificationsSnapshot.docs.first;
        final data = doc.data();
        sampleDoc = {
          'id': doc.id,
          'user_id': data['user_id'],
          'user_id_type': data['user_id']?.runtimeType.toString(),
          'type': data['type'],
          'read': data['read'],
          'title': data['title'],
        };
      }

      return {
        'currentUserId_fromPrefs': currentUserId?.toString(),
        'currentUserId_fromQuery': userId,
        'userType': userType,
        'totalNotifications': allNotificationsSnapshot.docs.length,
        'unreadCount_all': unreadSnapshot.docs.length,
        'filteredNotifications': filteredNotifications.length,
        'unreadCount_filtered':
            filteredNotifications.where((n) => !n.read).length,
        'sampleNotification': sampleDoc,
        'collectionName': collectionName,
      };
    } catch (e, stackTrace) {
      return {'error': e.toString(), 'stackTrace': stackTrace.toString()};
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
      rethrow;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'CleanSpace',
        message.notification?.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cleanspace_channel',
            'CleanSpace Notifications',
            channelDescription: 'Notifications for CleanSpace app',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> _saveTokenToBackendIfLoggedIn(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId != null) {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await saveTokenToBackend(userId.toString(), token, platform);
      }
    } catch (e) {
      print('Error saving refreshed token: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
