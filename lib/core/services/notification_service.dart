import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Firebase Cloud Messaging service
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions (iOS)
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          print('Notification permissions not granted');
          return;
        }
      }

      // Initialize local notifications
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
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

      // Get initial token
      final token = await _messaging.getToken();
      if (token != null) {
        print('✅ FCM TOKEN: $token');
        await _saveTokenToSupabase(token);
      } else {
        print('❌ FCM token is null');
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'cleanspace_channel',
      'CleanSpace Notifications',
      channelDescription: 'Notifications for CleanSpace app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'CleanSpace',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification data
    print('Notification tapped: ${response.payload}');
  }

  /// Save FCM token to Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        // Try to get user ID from profiles table if auth not set up
        // For now, skip if no auth user
        return;
      }

      // Get profile ID from auth_user_id
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();
      
      if (profileResponse == null) return;
      
      final profileId = profileResponse['id'] as int;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      await SupabaseConfig.client.from('user_devices').upsert({
        'user_id': profileId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Supabase.initialize();
  // Handle background message if needed
  print('Background message: ${message.messageId}');
}

