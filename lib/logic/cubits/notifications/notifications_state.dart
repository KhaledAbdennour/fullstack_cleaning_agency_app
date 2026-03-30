import '../../../data/models/notification_item.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsReady extends NotificationsState {
  final bool permissionGranted;
  final String? fcmToken;
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationsReady({
    required this.permissionGranted,
    this.fcmToken,
    required this.notifications,
    required this.unreadCount,
  });

  NotificationsReady copyWith({
    bool? permissionGranted,
    String? fcmToken,
    List<NotificationItem>? notifications,
    int? unreadCount,
  }) {
    return NotificationsReady(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      fcmToken: fcmToken ?? this.fcmToken,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
