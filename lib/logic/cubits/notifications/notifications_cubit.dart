import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/notifications/notifications_repo.dart';
import '../../../data/models/notification_item.dart';
import 'notifications_state.dart';

/// Cubit for managing notification state
/// Follows teacher's pattern: UI triggers Cubit, Cubit calls repo
class NotificationsCubit extends Cubit<NotificationsState> {
  final AbstractNotificationsRepo _repo;
  
  AbstractNotificationsRepo get repo => _repo;

  NotificationsCubit(this._repo) : super(NotificationsInitial()) {
    initialize();
  }

  /// Initialize notifications system
  Future<void> initialize() async {
    emit(NotificationsLoading());
    
    try {
      // Initialize messaging
      await _repo.initMessaging();
      
      // Request permissions
      final permissionGranted = await _repo.requestPermission();
      
      // Get FCM token
      final token = await _repo.getFcmToken();
      
      // Save token to backend if user is logged in
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('current_user_id');
        if (userId != null) {
          final platform = Platform.isAndroid ? 'android' : 'ios';
          await _repo.saveTokenToBackend(userId.toString(), token, platform);
        }
      }
      
      // Load notifications if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      List<NotificationItem> notifications = [];
      int unreadCount = 0;
      
      if (userId != null) {
        notifications = await _repo.getStoredNotifications(userId.toString());
        unreadCount = await _repo.getUnreadCount(userId.toString());
      }
      
      emit(NotificationsReady(
        permissionGranted: permissionGranted,
        fcmToken: token,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to initialize notifications: $e'));
    }
  }

  /// Refresh notifications inbox
  Future<void> refreshInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId == null) {
        emit(NotificationsReady(
          permissionGranted: (state as NotificationsReady?)?.permissionGranted ?? false,
          fcmToken: (state as NotificationsReady?)?.fcmToken,
          notifications: [],
          unreadCount: 0,
        ));
        return;
      }
      
      final notifications = await _repo.getStoredNotifications(userId.toString());
      final unreadCount = await _repo.getUnreadCount(userId.toString());
      
      if (state is NotificationsReady) {
        final currentState = state as NotificationsReady;
        emit(currentState.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      } else {
        emit(NotificationsReady(
          permissionGranted: true,
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      }
    } catch (e) {
      emit(NotificationsError('Failed to refresh inbox: $e'));
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repo.markAsRead(notificationId);
      await refreshInbox(); // Refresh to update unread count
    } catch (e) {
      emit(NotificationsError('Failed to mark as read: $e'));
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId == null) return;
      
      await _repo.markAllAsRead(userId.toString());
      await refreshInbox();
    } catch (e) {
      emit(NotificationsError('Failed to mark all as read: $e'));
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _repo.subscribeToTopic(topic);
    } catch (e) {
      emit(NotificationsError('Failed to subscribe to topic: $e'));
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _repo.unsubscribeFromTopic(topic);
    } catch (e) {
      emit(NotificationsError('Failed to unsubscribe from topic: $e'));
    }
  }
}

