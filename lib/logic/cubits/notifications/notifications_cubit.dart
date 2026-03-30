import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/notifications/notifications_repo.dart';
import '../../../data/models/notification_item.dart';
import '../../../local_db/dao/notifications_dao.dart';
import '../../../core/services/crashlytics_service.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final AbstractNotificationsRepo _repo;

  AbstractNotificationsRepo get repo => _repo;

  NotificationsCubit(this._repo) : super(NotificationsInitial()) {
    initialize();
  }

  Future<void> initialize() async {
    emit(NotificationsLoading());

    try {
      await _repo.initMessaging();

      final permissionGranted = await _repo.requestPermission();

      final token = await _repo.getFcmToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('current_user_id');
        if (userId != null) {
          final platform = Platform.isAndroid ? 'android' : 'ios';
          await _repo.saveTokenToBackend(userId.toString(), token, platform);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      List<NotificationItem> notifications = [];
      int unreadCount = 0;

      if (userId != null) {
        final notificationsDao =
            await _getLocalNotifications(userId.toString());
        if (notificationsDao.isNotEmpty) {
          emit(
            NotificationsReady(
              permissionGranted: permissionGranted,
              fcmToken: token,
              notifications: notificationsDao,
              unreadCount: notificationsDao.where((n) => !n.read).length,
            ),
          );
        }
        notifications = await _repo.getStoredNotifications(userId.toString());
        unreadCount = await _repo.getUnreadCount(userId.toString());
      }

      emit(
        NotificationsReady(
          permissionGranted: permissionGranted,
          fcmToken: token,
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Notifications initialization failed');
      emit(NotificationsError('Failed to initialize notifications: $e'));
    }
  }

  Future<void> refreshInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        emit(
          NotificationsReady(
            permissionGranted:
                (state as NotificationsReady?)?.permissionGranted ?? false,
            fcmToken: (state as NotificationsReady?)?.fcmToken,
            notifications: [],
            unreadCount: 0,
          ),
        );
        return;
      }

      final cached = await _getLocalNotifications(userId.toString());
      if (cached.isNotEmpty && state is! NotificationsLoading) {
        if (state is NotificationsReady) {
          final currentState = state as NotificationsReady;
          emit(
            currentState.copyWith(
              notifications: cached,
              unreadCount: cached.where((n) => !n.read).length,
            ),
          );
        }
      }

      final notifications = await _repo.getStoredNotifications(
        userId.toString(),
      );
      final unreadCount = await _repo.getUnreadCount(userId.toString());

      if (state is NotificationsReady) {
        final currentState = state as NotificationsReady;
        emit(
          currentState.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
          ),
        );
      } else {
        emit(
          NotificationsReady(
            permissionGranted: true,
            notifications: notifications,
            unreadCount: unreadCount,
          ),
        );
      }
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to refresh notifications inbox');
      emit(NotificationsError('Failed to refresh inbox: $e'));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repo.markAsRead(notificationId);
      await refreshInbox();
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to mark notification as read');
      emit(NotificationsError('Failed to mark as read: $e'));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) return;

      await _repo.markAllAsRead(userId.toString());
      await refreshInbox();
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to mark all notifications as read');
      emit(NotificationsError('Failed to mark all as read: $e'));
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _repo.subscribeToTopic(topic);
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to subscribe to topic');
      emit(NotificationsError('Failed to subscribe to topic: $e'));
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _repo.unsubscribeFromTopic(topic);
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to unsubscribe from topic');
      emit(NotificationsError('Failed to unsubscribe from topic: $e'));
    }
  }

  Future<List<NotificationItem>> _getLocalNotifications(String userId) async {
    try {
      return await NotificationsDao.getNotificationsForUser(userId);
    } catch (e) {
      return [];
    }
  }
}
