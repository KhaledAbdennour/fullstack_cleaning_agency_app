import '../../core/utils/firestore_type.dart';

/// Review model for the new "reviews" collection
class Review {
  final String? id; // Document ID
  final int jobId;
  final int? bookingId; // Optional
  final String reviewerId; // Firebase auth uid or profile doc id as string
  final String reviewerRole; // "Client" / "Agency" / "Individual Cleaner"
  final String revieweeId; // The cleaner/agency being reviewed
  final String revieweeRole; // "Agency" / "Individual Cleaner"
  final int rating; // 1..5
  final String comment;
  final List<String> photos; // Optional, can be empty
  final DateTime? createdAt;
  final int? createdAtMs; // Milliseconds for stable sorting
  final String status; // "active" for future moderation
  final int? reviewerUserIdInt; // Optional: numeric user ID if using int IDs
  final int? revieweeUserIdInt; // Optional: numeric user ID if using int IDs

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
      // Note: createdAt and createdAtMs are set by repository using FieldValue.serverTimestamp()
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
