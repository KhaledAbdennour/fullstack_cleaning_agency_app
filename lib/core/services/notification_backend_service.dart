import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to send notifications directly via FCM HTTP API (FREE - no Cloud Functions needed)
/// Follows teacher's pattern: All backend calls in service layer
///
/// ⚠️ SECURITY NOTE: FCM Server Key is stored in client code for development.
/// For production, consider using a free alternative like Vercel/Netlify Functions
/// or upgrading to Firebase Blaze plan (which has a generous free tier).
class NotificationBackendService {
  // FCM Server Key - same as in notifications_repo_db.dart
  // Get from: Firebase Console → Project Settings → Cloud Messaging → Server Key
  static const String fcmServerKey =
      '6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0';
  static const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to a specific user by userId
  ///
  /// Example:
  /// ```dart
  /// await NotificationBackendService.sendToUser(
  ///   userId: '123',
  ///   title: 'New Booking',
  ///   body: 'You have a new booking assigned',
  ///   route: '/bookingDetails',
  ///   id: '456',
  /// );
  /// ```
  static Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String body,
    String? route,
    String? id,
    Map<String, dynamic>? additionalData,
    bool skipSave =
        false, // If true, skip saving to Firestore (already saved by caller)
  }) async {
    try {
      // Get FCM tokens for the user from Firestore
      final devicesSnapshot = await _firestore
          .collection('user_devices')
          .where('user_id', isEqualTo: userId.toString())
          .get();

      if (devicesSnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'No devices found for user'};
      }

      final tokens = devicesSnapshot.docs
          .map((doc) => doc.data()['fcm_token'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .toList();

      if (tokens.isEmpty) {
        return {'success': false, 'message': 'No valid FCM tokens found'};
      }

      // Prepare data payload - MUST include user_id for proper filtering
      final dataPayload = <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'user_id': userId
            .toString(), // CRITICAL: Include user_id in FCM payload
        if (route != null) 'route': route,
        if (id != null) 'id': id,
        ...?additionalData,
      };

      // Send to all user devices
      int successCount = 0;
      int failureCount = 0;

      for (final token in tokens) {
        try {
          final response = await http.post(
            Uri.parse(fcmUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$fcmServerKey',
            },
            body: jsonEncode({
              'to': token,
              'notification': {'title': title, 'body': body},
              'data': dataPayload,
            }),
          );

          if (response.statusCode == 200) {
            successCount++;
          } else {
            failureCount++;
            print(
              'FCM error for token: ${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          failureCount++;
          print('Error sending to token: $e');
        }
      }

      // Save notification to Firestore for history (unless skipSave is true)
      if (!skipSave) {
        try {
          final notificationData = <String, dynamic>{
            'user_id': userId.toString(),
            'title': title,
            'body': body,
            'data_json': dataPayload,
            'created_at': FieldValue.serverTimestamp(),
            'read': false,
          };

          // Extract type, sender_id, job_id from additionalData if present
          if (additionalData != null) {
            if (additionalData.containsKey('type')) {
              notificationData['type'] = additionalData['type'];
            }
            if (additionalData.containsKey('sender_id')) {
              notificationData['sender_id'] = additionalData['sender_id'];
            }
            if (additionalData.containsKey('job_id')) {
              final jobId = additionalData['job_id'];
              notificationData['job_id'] = jobId is int
                  ? jobId
                  : int.tryParse(jobId.toString());
            }
          }

          await _firestore.collection('notifications').add(notificationData);
        } catch (e) {
          print('Error saving notification to Firestore: $e');
        }
      }

      return {
        'success': successCount > 0,
        'sent': successCount,
        'failed': failureCount,
      };
    } catch (e) {
      print('Error in sendToUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send notification to a topic
  ///
  /// Example:
  /// ```dart
  /// await NotificationBackendService.sendToTopic(
  ///   topic: 'all_users',
  ///   title: 'New Feature',
  ///   body: 'Check out our new feature!',
  /// );
  /// ```
  static Future<Map<String, dynamic>> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final dataPayload = <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...?data,
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey',
        },
        body: jsonEncode({
          'to': '/topics/$topic',
          'notification': {'title': title, 'body': body},
          'data': dataPayload,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'messageId': responseData['message_id']};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('Error in sendToTopic: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
