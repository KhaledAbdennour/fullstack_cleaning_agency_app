import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_type.dart';

/// Notification model with enhanced fields for role-based filtering
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Contains route, id, etc.
  final bool read;
  
  // New fields for role-based filtering
  final String? type; // 'job_published', 'job_accepted', 'job_rejected', 'job_completed', 'review_added'
  final String? senderId; // User ID of the sender
  final int? jobId; // Related job ID
  final String userId; // Recipient user ID

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.userId,
    this.data,
    this.read = false,
    this.type,
    this.senderId,
    this.jobId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'data': data,
      'read': read,
      'type': type,
      'sender_id': senderId,
      'job_id': jobId,
      'user_id': userId,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map, {DocumentSnapshot? docSnapshot}) {
    // Parse createdAt using unified helper (supports Timestamp/int/String)
    DateTime? parsedDate = readDate(map['created_at']);
    
    // Fallback to created_at_ms if created_at is null
    if (parsedDate == null && map['created_at_ms'] != null) {
      final ms = map['created_at_ms'];
      parsedDate = readDate(ms);
    }
    
    // Final fallback: use current time (but log warning)
    if (parsedDate == null) {
      print('⚠️ Notification missing created_at, using DateTime.now() - id: ${map['id']}');
      parsedDate = DateTime.now();
    }
    
    return NotificationItem(
      id: readString(map['id']) ?? '',
      title: readString(map['title']) ?? '',
      body: readString(map['body']) ?? '',
      createdAt: parsedDate,
      data: map['data'] != null || map['data_json'] != null
          ? Map<String, dynamic>.from(map['data'] ?? map['data_json'] ?? {})
          : null,
      read: readBool(map['read']),
      type: readString(map['type']),
      senderId: readString(map['sender_id']),
      jobId: readInt(map['job_id']),
      userId: readString(map['user_id']) ?? '',
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    bool? read,
    String? type,
    String? senderId,
    int? jobId,
    String? userId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      read: read ?? this.read,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
    );
  }
}

/// Notification types enum
enum NotificationType {
  jobPublished,
  jobAccepted,
  jobRejected,
  jobCompleted,
  reviewAdded,
  jobApplication,
  jobAssigned,
  jobMarkedDone,
  jobDeleted,
  reviewReceived,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.jobPublished:
        return 'job_published';
      case NotificationType.jobAccepted:
        return 'job_accepted';
      case NotificationType.jobRejected:
        return 'job_rejected';
      case NotificationType.jobCompleted:
        return 'job_completed';
      case NotificationType.reviewAdded:
        return 'review_added';
      case NotificationType.jobApplication:
        return 'job_application';
      case NotificationType.jobAssigned:
        return 'job_assigned';
      case NotificationType.jobMarkedDone:
        return 'job_marked_done';
      case NotificationType.jobDeleted:
        return 'job_deleted';
      case NotificationType.reviewReceived:
        return 'review_received';
    }
  }
  
  String get displayName {
    switch (this) {
      case NotificationType.jobPublished:
        return 'New Job Available';
      case NotificationType.jobAccepted:
        return 'Application Accepted';
      case NotificationType.jobRejected:
        return 'Application Rejected';
      case NotificationType.jobCompleted:
        return 'Job Completed';
      case NotificationType.reviewAdded:
        return 'New Review';
      case NotificationType.jobApplication:
        return 'New Application';
      case NotificationType.jobAssigned:
        return 'Job Assigned';
      case NotificationType.jobMarkedDone:
        return 'Job Marked Done';
      case NotificationType.jobDeleted:
        return 'Job Deleted';
      case NotificationType.reviewReceived:
        return 'Review Received';
    }
  }
}
