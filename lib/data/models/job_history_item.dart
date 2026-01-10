import 'package:cloud_firestore/cloud_firestore.dart';

/// Job history item for tracking completed jobs across all roles
class JobHistoryItem {
  final String? id;
  final int jobId;
  final int participantUserId; // Worker, Client, or Agency ID
  final String role; // 'worker', 'client', or 'agency'
  final DateTime completedAt;
  final String title;
  final int?
  otherPartyId; // The other party involved (e.g., client ID if participant is worker)
  final String? description;
  final double? price;

  JobHistoryItem({
    this.id,
    required this.jobId,
    required this.participantUserId,
    required this.role,
    required this.completedAt,
    required this.title,
    this.otherPartyId,
    this.description,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'participant_user_id': participantUserId,
      'role': role,
      'completed_at': Timestamp.fromDate(completedAt),
      'title': title,
      'other_party_id': otherPartyId,
      'description': description,
      'price': price,
    };
  }

  factory JobHistoryItem.fromMap(Map<String, dynamic> map) {
    return JobHistoryItem(
      id: map['id'] as String?,
      jobId: map['job_id'] as int,
      participantUserId: map['participant_user_id'] as int,
      role: map['role'] as String,
      completedAt: (map['completed_at'] as Timestamp).toDate(),
      title: map['title'] as String,
      otherPartyId: map['other_party_id'] as int?,
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toDouble(),
    );
  }
}
