import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'notification_repo.dart';

class NotificationRepoDB extends AbstractNotificationRepo {
  static const String tableName = 'notifications';

  @override
  Future<List<Map<String, dynamic>>> getNotificationsForUser(String userId) async {
    // Convert string userId to int if needed
    final userIdInt = int.tryParse(userId) ?? 0;
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('user_id', userIdInt)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final userIdInt = int.tryParse(userId) ?? 0;
      await SupabaseConfig.client
          .from(tableName)
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userIdInt)
          .isFilter('read_at', null);
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final userIdInt = int.tryParse(userId) ?? 0;
      final response = await SupabaseConfig.client
          .from(tableName)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userIdInt)
          .isFilter('read_at', null);
      
      return response.count ?? 0;
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
      final userIdInt = int.tryParse(userId) ?? 0;
      // Call Supabase Edge Function to send push notification
      await SupabaseConfig.client.functions.invoke(
        'send_push',
        body: {
          'user_id': userIdInt.toString(),
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      // Also save to notifications table for history
      await SupabaseConfig.client.from(tableName).insert({
        'user_id': userIdInt,
        'title': title,
        'body': body,
        'data_json': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }
}

