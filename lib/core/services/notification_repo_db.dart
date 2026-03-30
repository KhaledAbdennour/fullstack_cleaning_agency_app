import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/firebase_config.dart';
import 'notification_repo.dart';

class NotificationRepoDB extends AbstractNotificationRepo {
  static const String collectionName = 'notifications';
  static const String devicesCollectionName = 'user_devices';

  static const String fcmServerKey =
      '6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0';

  @override
  Future<List<Map<String, dynamic>>> getNotificationsForUser(
    String userId,
  ) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(notificationId)
          .update({'read_at': FieldValue.serverTimestamp()});
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
          .where('read_at', isNull: true)
          .get();

      final batch = FirebaseConfig.firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read_at': FieldValue.serverTimestamp()});
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
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .where('read_at', isNull: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final devicesSnapshot = await FirebaseConfig.firestore
          .collection(devicesCollectionName)
          .where('user_id', isEqualTo: userId)
          .get();

      final tokens = devicesSnapshot.docs
          .map((doc) => doc.data()['fcm_token'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .toList();

      if (tokens.isEmpty) {
        print('No FCM tokens found for user $userId');
        return;
      }

      for (final token in tokens) {
        await _sendFCMNotification(
          token: token!,
          title: title,
          body: body,
          data: data,
        );
      }

      await FirebaseConfig.firestore.collection(collectionName).add({
        'user_id': userId,
        'title': title,
        'body': body,
        'data_json': data ?? {},
        'created_at': FieldValue.serverTimestamp(),
        'read_at': null,
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {'title': title, 'body': body},
          'data': {...?data, 'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
          'priority': 'high',
        }),
      );

      if (response.statusCode != 200) {
        print('FCM error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      rethrow;
    }
  }
}
