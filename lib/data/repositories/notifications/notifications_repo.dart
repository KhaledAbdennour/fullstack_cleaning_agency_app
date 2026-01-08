import '../../models/notification_item.dart';
import 'notifications_repo_db.dart';

/// Abstract repository for notifications
/// Follows teacher's pattern: UI never talks to Firebase directly
abstract class AbstractNotificationsRepo {
  static AbstractNotificationsRepo? _instance;

  /// Get singleton instance
  static AbstractNotificationsRepo getInstance() {
    _instance ??= NotificationsRepoDB();
    return _instance!;
  }

  /// Initialize Firebase Messaging
  /// Sets up foreground/background handlers
  Future<void> initMessaging();

  /// Request notification permissions (iOS)
  Future<bool> requestPermission();

  /// Get FCM token
  Future<String?> getFcmToken();

  /// Save FCM token to backend (Firestore)
  Future<void> saveTokenToBackend(String userId, String token, String platform);

  /// Store received notification locally (Firestore)
  Future<void> storeReceivedNotification(NotificationItem notification);

  /// Get stored notifications for user (uses role-based selector)
  Future<List<NotificationItem>> getStoredNotifications(String userId);
  
  /// Get notifications for Worker role
  Future<List<NotificationItem>> getNotificationsForWorker(String userId);
  
  /// Get notifications for Agency role
  Future<List<NotificationItem>> getNotificationsForAgency(String userId);
  
  /// Get notifications for Client role
  Future<List<NotificationItem>> getNotificationsForClient(String userId);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId);

  /// Get unread count for user
  Future<int> getUnreadCount(String userId);

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic);
  
  /// Get diagnostics info for debugging (dev mode only)
  Future<Map<String, dynamic>> getDiagnostics(String userId);
}

