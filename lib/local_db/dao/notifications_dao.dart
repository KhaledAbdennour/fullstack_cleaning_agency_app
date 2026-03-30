import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../data/models/notification_item.dart';
import 'dart:convert';

class NotificationsDao {
  static const String _tableName = 'notifications_cache';

  static Future<void> insertNotifications(
      List<NotificationItem> notifications) async {
    if (notifications.isEmpty) return;

    final db = await AppDatabase.database;
    final batch = db.batch();

    for (final notification in notifications) {
      batch.insert(
        _tableName,
        {
          'id': notification.id,
          'title': notification.title,
          'body': notification.body,
          'created_at': notification.createdAt.millisecondsSinceEpoch,
          'user_id': notification.userId,
          'read': notification.read ? 1 : 0,
          'type': notification.type,
          'sender_id': notification.senderId,
          'job_id': notification.jobId,
          'data_json':
              notification.data != null ? jsonEncode(notification.data) : null,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<List<NotificationItem>> getNotificationsForUser(
      String userId) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 100,
    );

    return maps
        .map((map) {
          try {
            return NotificationItem(
              id: map['id'] as String,
              title: map['title'] as String,
              body: map['body'] as String,
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
              userId: map['user_id'] as String,
              read: (map['read'] as int) == 1,
              type: map['type'] as String?,
              senderId: map['sender_id'] as String?,
              jobId: map['job_id'] as int?,
              data: map['data_json'] != null
                  ? Map<String, dynamic>.from(
                      jsonDecode(map['data_json'] as String))
                  : null,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<NotificationItem>()
        .toList();
  }

  static Future<void> clearUserNotifications(String userId) async {
    final db = await AppDatabase.database;
    await db.delete(_tableName, where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<void> clearAll() async {
    final db = await AppDatabase.database;
    await db.delete(_tableName);
  }
}
