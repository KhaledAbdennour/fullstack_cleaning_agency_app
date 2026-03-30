import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      print('DEBUG: NotificationService already initialized');
      return;
    }

    print('DEBUG: NotificationService.initialize() called');

    try {
      final logFile = File(
        r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
      );
      final logEntry = jsonEncode({
        "sessionId": "debug-session",
        "runId": "run1",
        "hypothesisId": "C",
        "location": "notification_service.dart:17",
        "message": "NotificationService.initialize() entry",
        "data": {"platform": Platform.operatingSystem},
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      print('DEBUG: Log write failed: $e');
    }

    try {
      print('DEBUG: Platform check - isIOS: ${Platform.isIOS}');

      try {
        final logFile = File(
          r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
        );
        final logEntry = jsonEncode({
          "sessionId": "debug-session",
          "runId": "run1",
          "hypothesisId": "C",
          "location": "notification_service.dart:25",
          "message": "Before iOS permission check",
          "data": {"isIOS": Platform.isIOS},
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('DEBUG: Log write failed: $e');
      }

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

      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      print('DEBUG: About to call getToken()...');

      try {
        final firebaseApps = Firebase.apps;
        print('DEBUG: Firebase apps available: ${firebaseApps.length}');
        if (firebaseApps.isEmpty) {
          print('ERROR: Firebase not initialized! Cannot get FCM token.');

          try {
            final logFile = File(
              r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
            );
            final logEntry = jsonEncode({
              "sessionId": "debug-session",
              "runId": "run1",
              "hypothesisId": "E",
              "location": "notification_service.dart:66",
              "message": "Firebase not initialized before getToken",
              "data": {},
              "timestamp": DateTime.now().millisecondsSinceEpoch,
            });
            logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
          } catch (e) {
            print('DEBUG: Log write failed: $e');
          }

          return;
        }
      } catch (e) {
        print('DEBUG: Error checking Firebase apps: $e');
      }

      try {
        final logFile = File(
          r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
        );
        final logEntry = jsonEncode({
          "sessionId": "debug-session",
          "runId": "run1",
          "hypothesisId": "D",
          "location": "notification_service.dart:78",
          "message": "Before getToken() call",
          "data": {},
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('DEBUG: Log write failed: $e');
      }

      final token = await _messaging.getToken();
      print(
        'DEBUG: getToken() returned: ${token != null ? "token exists (${token.length} chars)" : "null"}',
      );

      try {
        final logFile = File(
          r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
        );
        final logEntry = jsonEncode({
          "sessionId": "debug-session",
          "runId": "run1",
          "hypothesisId": "D",
          "location": "notification_service.dart:68",
          "message": "After getToken() call",
          "data": {
            "token": token,
            "isNull": token == null,
            "tokenLength": token?.length,
          },
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('DEBUG: Log write failed: $e');
      }

      if (token != null) {
        print('FCM TOKEN: $token');

        try {
          final logFile = File(
            r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
          );
          final logEntry = jsonEncode({
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "D",
            "location": "notification_service.dart:73",
            "message": "Token received, saving to Firestore",
            "data": {"tokenLength": token.length},
            "timestamp": DateTime.now().millisecondsSinceEpoch,
          });
          logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
        } catch (e) {
          print('DEBUG: Log write failed: $e');
        }

        await _saveTokenToFirestore(token);
      } else {
        print('FCM token is null');

        try {
          final logFile = File(
            r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
          );
          final logEntry = jsonEncode({
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "D",
            "location": "notification_service.dart:80",
            "message": "Token is null",
            "data": {},
            "timestamp": DateTime.now().millisecondsSinceEpoch,
          });
          logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
        } catch (e) {
          print('DEBUG: Log write failed: $e');
        }
      }

      _initialized = true;
      print('DEBUG: NotificationService initialization complete');

      try {
        final logFile = File(
          r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
        );
        final logEntry = jsonEncode({
          "sessionId": "debug-session",
          "runId": "run1",
          "hypothesisId": "C",
          "location": "notification_service.dart:88",
          "message": "NotificationService initialized successfully",
          "data": {},
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('DEBUG: Log write failed: $e');
      }
    } catch (e, stackTrace) {
      print('Error initializing notifications: $e');
      print('Stack trace: $stackTrace');

      try {
        final logFile = File(
          r'c:\Users\wailo\Desktop\mob_dev_project\.cursor\debug.log',
        );
        final logEntry = jsonEncode({
          "sessionId": "debug-session",
          "runId": "run1",
          "hypothesisId": "C",
          "location": "notification_service.dart:94",
          "message": "NotificationService initialization error",
          "data": {
            "error": e.toString(),
            "errorType": e.runtimeType.toString(),
          },
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
      } catch (logErr) {
        print('DEBUG: Log write failed: $logErr');
      }
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

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

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        return;
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';
      final deviceId = '${platform}_$userId';

      await FirebaseConfig.firestore
          .collection('user_devices')
          .doc(deviceId)
          .set({
        'user_id': userId.toString(),
        'fcm_token': token,
        'platform': platform,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM token saved to Firestore for user $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
