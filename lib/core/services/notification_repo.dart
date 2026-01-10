import 'notification_repo_db.dart';

abstract class AbstractNotificationRepo {
  Future<List<Map<String, dynamic>>> getNotificationsForUser(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });

  static AbstractNotificationRepo? _instance;
  static AbstractNotificationRepo getInstance() {
    _instance ??= NotificationRepoDB();
    return _instance!;
  }
}
