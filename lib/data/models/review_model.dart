import '../../core/utils/firestore_type.dart';

class Review {
  final String? id;
  final int jobId;
  final int? bookingId;
  final String reviewerId;
  final String reviewerRole;
  final String revieweeId;
  final String revieweeRole;
  final int rating;
  final String comment;
  final List<String> photos;
  final DateTime? createdAt;
  final int? createdAtMs;
  final String status;
  final int? reviewerUserIdInt;
  final int? revieweeUserIdInt;

  Review({
    this.id,
    required this.jobId,
    this.bookingId,
    required this.reviewerId,
    required this.reviewerRole,
    required this.revieweeId,
    required this.revieweeRole,
    required this.rating,
    required this.comment,
    this.photos = const [],
    this.createdAt,
    this.createdAtMs,
    this.status = 'active',
    this.reviewerUserIdInt,
    this.revieweeUserIdInt,
  });

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      if (bookingId != null) 'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewer_role': reviewerRole,
      'reviewee_id': revieweeId,
      'reviewee_role': revieweeRole,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'status': status,
      if (reviewerUserIdInt != null) 'reviewer_user_id_int': reviewerUserIdInt,
      if (revieweeUserIdInt != null) 'reviewee_user_id_int': revieweeUserIdInt,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      jobId: readInt(map['job_id']) ?? 0,
      bookingId: readInt(map['booking_id']),
      reviewerId: readString(map['reviewer_id']) ?? '',
      reviewerRole: readString(map['reviewer_role']) ?? '',
      revieweeId: readString(map['reviewee_id']) ?? '',
      revieweeRole: readString(map['reviewee_role']) ?? '',
      rating: readInt(map['rating']) ?? 0,
      comment: readString(map['comment']) ?? '',
      photos: map['photos'] is List
          ? (map['photos'] as List)
              .map((e) => readString(e) ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
      createdAt: readDate(map['created_at']),
      createdAtMs: readInt(map['created_at_ms']),
      status: readString(map['status']) ?? 'active',
      reviewerUserIdInt: readInt(map['reviewer_user_id_int']),
      revieweeUserIdInt: readInt(map['reviewee_user_id_int']),
    );
  }
}
