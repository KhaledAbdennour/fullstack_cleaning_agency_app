import '../../models/notification_item.dart';
import 'notifications_repo_db.dart';

abstract class AbstractNotificationsRepo {
  static AbstractNotificationsRepo? _instance;

  static AbstractNotificationsRepo getInstance() {
    _instance ??= NotificationsRepoDB();
    return _instance!;
  }

  Future<void> initMessaging();

  Future<bool> requestPermission();

  Future<String?> getFcmToken();

  Future<void> saveTokenToBackend(String userId, String token, String platform);

  Future<void> storeReceivedNotification(NotificationItem notification);

  Future<List<NotificationItem>> getStoredNotifications(String userId);

  Future<List<NotificationItem>> getNotificationsForWorker(String userId);

  Future<List<NotificationItem>> getNotificationsForAgency(String userId);

  Future<List<NotificationItem>> getNotificationsForClient(String userId);

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead(String userId);

  Future<int> getUnreadCount(String userId);

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Future<Map<String, dynamic>> getDiagnostics(String userId);
}
