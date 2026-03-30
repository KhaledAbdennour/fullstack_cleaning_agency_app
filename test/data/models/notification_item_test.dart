import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mob_dev_project/data/models/notification_item.dart';

void main() {
  group('NotificationItem.fromMap', () {
    test('parses notification with Timestamp created_at', () {
      final timestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
      final map = {
        'id': 'test-id-1',
        'title': 'Test Notification',
        'body': 'Test body',
        'created_at': timestamp,
        'user_id': '123',
        'read': false,
      };

      final notification = NotificationItem.fromMap(map);

      expect(notification.id, equals('test-id-1'));
      expect(notification.title, equals('Test Notification'));
      expect(notification.body, equals('Test body'));
      expect(notification.createdAt.year, equals(2024));
      expect(notification.userId, equals('123'));
      expect(notification.read, isFalse);
    });

    test('parses notification with ISO string created_at', () {
      final map = {
        'id': 'test-id-2',
        'title': 'Test',
        'body': 'Body',
        'created_at': '2024-01-15T10:30:00Z',
        'user_id': '456',
        'read': true,
      };

      final notification = NotificationItem.fromMap(map);

      expect(notification.id, equals('test-id-2'));
      expect(notification.createdAt.year, equals(2024));
      expect(notification.read, isTrue);
    });

    test('parses notification with milliseconds created_at', () {
      final ms = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final map = {
        'id': 'test-id-3',
        'title': 'Test',
        'body': 'Body',
        'created_at_ms': ms,
        'user_id': '789',
        'read': false,
      };

      final notification = NotificationItem.fromMap(map);

      expect(notification.id, equals('test-id-3'));
      expect(notification.createdAt.year, equals(2024));
      expect(notification.createdAt.month, equals(1));
    });

    test('parses notification with optional fields', () {
      final map = {
        'id': 'test-id-4',
        'title': 'Job Published',
        'body': 'A new job is available',
        'created_at': Timestamp.now(),
        'user_id': '999',
        'read': false,
        'type': 'job_published',
        'sender_id': 'sender-123',
        'job_id': 42,
        'data': {'route': '/job/42'},
      };

      final notification = NotificationItem.fromMap(map);

      expect(notification.type, equals('job_published'));
      expect(notification.senderId, equals('sender-123'));
      expect(notification.jobId, equals(42));
      expect(notification.data, isNotNull);
      expect(notification.data!['route'], equals('/job/42'));
    });

    test('handles missing optional fields', () {
      final map = {
        'id': 'test-id-5',
        'title': 'Test',
        'body': 'Body',
        'created_at': Timestamp.now(),
        'user_id': '111',
      };

      final notification = NotificationItem.fromMap(map);

      expect(notification.type, isNull);
      expect(notification.senderId, isNull);
      expect(notification.jobId, isNull);
      expect(notification.data, isNull);
      expect(notification.read, isFalse);
    });

    test('sorts by createdAt descending', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));
      final later = now.add(const Duration(hours: 1));

      final n1 = NotificationItem(
        id: '1',
        title: 'Earlier',
        body: 'Body',
        createdAt: earlier,
        userId: '123',
      );

      final n2 = NotificationItem(
        id: '2',
        title: 'Later',
        body: 'Body',
        createdAt: later,
        userId: '123',
      );

      final list = [n1, n2];
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(list.first.id, equals('2'));
      expect(list.last.id, equals('1'));
    });
  });
}
