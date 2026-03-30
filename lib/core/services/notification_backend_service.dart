import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationBackendService {
  static const String fcmServerKey =
      '6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0';
  static const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String body,
    String? route,
    String? id,
    Map<String, dynamic>? additionalData,
    bool skipSave = false,
  }) async {
    try {
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

      final dataPayload = <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'user_id': userId.toString(),
        if (route != null) 'route': route,
        if (id != null) 'id': id,
        ...?additionalData,
      };

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

          if (additionalData != null) {
            if (additionalData.containsKey('type')) {
              notificationData['type'] = additionalData['type'];
            }
            if (additionalData.containsKey('sender_id')) {
              notificationData['sender_id'] = additionalData['sender_id'];
            }
            if (additionalData.containsKey('job_id')) {
              final jobId = additionalData['job_id'];
              notificationData['job_id'] =
                  jobId is int ? jobId : int.tryParse(jobId.toString());
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
