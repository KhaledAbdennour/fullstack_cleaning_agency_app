import '../../core/utils/firestore_type.dart';

class Complaint {
  final int? id;
  final int userId;
  final String subject;
  final String message;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Complaint({
    this.id,
    required this.userId,
    required this.subject,
    required this.message,
    this.status = ComplaintStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    ComplaintStatus complaintStatus = ComplaintStatus.pending;
    if (map['status'] != null) {
      final statusStr = map['status'].toString();
      try {
        complaintStatus = ComplaintStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => ComplaintStatus.pending,
        );
      } catch (e) {
        complaintStatus = ComplaintStatus.pending;
      }
    }

    DateTime createdAt;
    final createdAtValue = readDate(map['created_at']);
    if (createdAtValue != null) {
      createdAt = createdAtValue;
    } else {
      try {
        createdAt = DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
        );
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    DateTime? updatedAt;
    if (map['updated_at'] != null) {
      final updatedAtValue = readDate(map['updated_at']);
      if (updatedAtValue != null) {
        updatedAt = updatedAtValue;
      } else {
        try {
          updatedAt = DateTime.parse(map['updated_at'] as String);
        } catch (e) {
          updatedAt = null;
        }
      }
    }

    return Complaint(
      id: map['id'] as int?,
      userId: readInt(map['user_id']) ?? 0,
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: complaintStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Complaint copyWith({
    int? id,
    int? userId,
    String? subject,
    String? message,
    ComplaintStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ComplaintStatus { pending, inProgress, resolved, closed }
