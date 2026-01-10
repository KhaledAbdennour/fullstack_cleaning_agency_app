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
import 'notifications_repo.dart';

/// Firestore implementation of notifications repository
/// All Firebase Messaging APIs are called here (teacher's pattern)
class NotificationsRepoDB extends AbstractNotificationsRepo {
  static const String collectionName = 'notifications';
  static const String devicesCollectionName = 'user_devices';
  
  // FCM Server Key - should be stored securely in production
  static const String fcmServerKey = '6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0';
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  @override
  Future<void> initMessaging() async {
    if (_initialized) return;
    
    try {
      // Initialize local notifications for foreground display
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

      // Configure foreground notification display
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Configure background message handler (must be top-level)
      // Note: Background handler is defined at the bottom of this file
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle token refresh
      _messaging.onTokenRefresh.listen((token) {
        // Token refreshed - save to backend if user is logged in
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
      // Android permissions are granted by default
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
  Future<void> saveTokenToBackend(String userId, String token, String platform) async {
    try {
      final deviceId = '${platform}_${userId}'; // Unique device ID per user+platform

      await FirebaseConfig.firestore
          .collection(devicesCollectionName)
          .doc(deviceId)
          .set({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ FCM token saved to Firestore for user $userId');
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
    // Use role-based selector via NotificationServiceEnhanced
    try {
      DebugFlags.debugPrint('🔔 [getStoredNotifications] START - userId: $userId');
      
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      DebugFlags.debugPrint('🔔 [getStoredNotifications] Profiles loaded: ${profiles.length}');
      
      final userProfile = profiles.firstWhere(
        (p) => p['id'].toString() == userId,
        orElse: () => <String, dynamic>{},
      );
      
      final userType = userProfile['user_type']?.toString() ?? '';
      DebugFlags.debugPrint('🔔 [getStoredNotifications] User type: $userType, userId: $userId');
      
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
          DebugFlags.debugPrint('🔔 [getStoredNotifications] Unknown user type, using fallback query');
          // Fallback: return all notifications for this user
          try {
            final snapshot = await FirebaseConfig.firestore
                .collection(collectionName)
                .where('user_id', isEqualTo: userId)
                .orderBy('created_at', descending: true)
                .limit(50)
                .get();
            
            DebugFlags.debugPrint('🔔 [getStoredNotifications] Fallback query returned ${snapshot.docs.length} docs');
            result = snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              return NotificationItem.fromMap({
                ...data,
                'id': doc.id,
              });
            }).toList();
          } catch (e2) {
            DebugFlags.debugPrint('🔔 [getStoredNotifications] Fallback query failed: $e2');
            // Last resort: query without orderBy
            try {
              final snapshot = await FirebaseConfig.firestore
                  .collection(collectionName)
                  .where('user_id', isEqualTo: userId)
                  .limit(50)
                  .get();
              
              result = snapshot.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data() as Map);
                return NotificationItem.fromMap({
                  ...data,
                  'id': doc.id,
                });
              }).toList();
              
              // Sort client-side
              result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              DebugFlags.debugPrint('🔔 [getStoredNotifications] Last resort query returned ${result.length} notifications');
            } catch (e3) {
              DebugFlags.debugPrint('🔔 [getStoredNotifications] All queries failed: $e3');
              result = [];
            }
          }
      }
      
      DebugFlags.debugPrint('🔔 [getStoredNotifications] SUCCESS - Returning ${result.length} notifications');
      return result;
    } catch (e, stackTrace) {
      DebugFlags.debugPrint('🔔 [getStoredNotifications] ERROR: $e');
      DebugFlags.debugPrint('🔔 [getStoredNotifications] Stack: $stackTrace');
      return [];
    }
  }
  
  @override
  Future<List<NotificationItem>> getNotificationsForWorker(String userId) async {
    // Use enhanced service which filters by job interaction
    return await NotificationServiceEnhanced.getNotificationsForWorker(userId);
  }
  
  @override
  Future<List<NotificationItem>> getNotificationsForAgency(String userId) async {
    // Use enhanced service which filters by job interaction
    return await NotificationServiceEnhanced.getNotificationsForAgency(userId);
  }
  
  @override
  Future<List<NotificationItem>> getNotificationsForClient(String userId) async {
    // Use enhanced service which filters by job ownership
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
    // Use the same role-based selector as getStoredNotifications to ensure consistency
    try {
      final notifications = await getStoredNotifications(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Get diagnostics info for debugging (dev mode only)
  Future<Map<String, dynamic>> getDiagnostics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('current_user_id');
      
      // Get user profile to determine role
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      final userProfile = profiles.firstWhere(
        (p) => p['id'].toString() == userId,
        orElse: () => <String, dynamic>{},
      );
      final userType = userProfile['user_type']?.toString() ?? 'Unknown';
      
      // Get all notifications for this user (no type filter)
      final allNotificationsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .get();
      
      // Get unread count (all notifications)
      final unreadSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      // Get filtered notifications (role-based)
      final filteredNotifications = await getStoredNotifications(userId);
      
      // Sample notification doc to check structure
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
        'unreadCount_filtered': filteredNotifications.where((n) => !n.read).length,
        'sampleNotification': sampleDoc,
        'collectionName': collectionName,
      };
    } catch (e, stackTrace) {
      return {
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
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

  /// Handle foreground messages - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Show local notification
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

      // DO NOT store notification here - it's already saved server-side in NotificationServiceEnhanced.createNotification()
      // Storing here would create duplicates
      // The notification is already in Firestore, we just need to show the local notification
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigation will be handled by NotificationRouter
    print('Notification tapped: ${response.payload}');
  }

  /// Save token to backend if user is logged in
  Future<void> _saveTokenToBackendIfLoggedIn(String token) async {
    try {
      // Get current user ID from SharedPreferences (same pattern as profiles repo)
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

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase should already be initialized in main()
  print('Background message: ${message.messageId}');
  
  // DO NOT store notification here - it's already saved server-side in NotificationServiceEnhanced.createNotification()
  // Storing here would create duplicates
  // The notification is already in Firestore, we just need to handle the background message
}
