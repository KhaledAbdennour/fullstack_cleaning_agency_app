import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
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
    if (_initialized) {
      print('🔍 DEBUG: NotificationService already initialized');
      return;
    }

    print('🔍 DEBUG: NotificationService.initialize() called');
    // #region agent log
    try {
      final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
      final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"notification_service.dart:17","message":"NotificationService.initialize() entry","data":{"platform":Platform.operatingSystem},"timestamp":DateTime.now().millisecondsSinceEpoch});
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      print('🔍 DEBUG: Log write failed: $e');
    }
    // #endregion

    try {
      print('🔍 DEBUG: Platform check - isIOS: ${Platform.isIOS}');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"notification_service.dart:25","message":"Before iOS permission check","data":{"isIOS":Platform.isIOS},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('🔍 DEBUG: Log write failed: $e');
      }
      // #endregion
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
      print('🔍 DEBUG: About to call getToken()...');
      // Check if Firebase is initialized
      try {
        final firebaseApps = Firebase.apps;
        print('🔍 DEBUG: Firebase apps available: ${firebaseApps.length}');
        if (firebaseApps.isEmpty) {
          print('❌ ERROR: Firebase not initialized! Cannot get FCM token.');
          // #region agent log
          try {
            final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
            final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"notification_service.dart:66","message":"Firebase not initialized before getToken","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
            logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
          } catch (e) {
            print('🔍 DEBUG: Log write failed: $e');
          }
          // #endregion
          return;
        }
      } catch (e) {
        print('🔍 DEBUG: Error checking Firebase apps: $e');
      }
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"notification_service.dart:78","message":"Before getToken() call","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('🔍 DEBUG: Log write failed: $e');
      }
      // #endregion
      final token = await _messaging.getToken();
      print('🔍 DEBUG: getToken() returned: ${token != null ? "token exists (${token.length} chars)" : "null"}');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"notification_service.dart:68","message":"After getToken() call","data":{"token":token,"isNull":token==null,"tokenLength":token?.length},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('🔍 DEBUG: Log write failed: $e');
      }
      // #endregion
      if (token != null) {
        print('✅ FCM TOKEN: $token');
        // #region agent log
        try {
          final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
          final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"notification_service.dart:73","message":"Token received, saving to Supabase","data":{"tokenLength":token.length},"timestamp":DateTime.now().millisecondsSinceEpoch});
          logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
        } catch (e) {
          print('🔍 DEBUG: Log write failed: $e');
        }
        // #endregion
        await _saveTokenToSupabase(token);
      } else {
        print('❌ FCM token is null');
        // #region agent log
        try {
          final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
          final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"notification_service.dart:80","message":"Token is null","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
          logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
        } catch (e) {
          print('🔍 DEBUG: Log write failed: $e');
        }
        // #endregion
      }

      _initialized = true;
      print('🔍 DEBUG: NotificationService initialization complete');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"notification_service.dart:88","message":"NotificationService initialized successfully","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('🔍 DEBUG: Log write failed: $e');
      }
      // #endregion
    } catch (e, stackTrace) {
      print('❌ Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
      // #region agent log
      try {
        final logFile = File(r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log');
        final logEntry = jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"notification_service.dart:94","message":"NotificationService initialization error","data":{"error":e.toString(),"errorType":e.runtimeType.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch});
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (logErr) {
        print('🔍 DEBUG: Log write failed: $logErr');
      }
      // #endregion
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
  // Supabase should already be initialized in main(), but ensure it's available
  // Handle background message if needed
  print('Background message: ${message.messageId}');
}

