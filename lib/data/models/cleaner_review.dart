import '../../core/utils/firestore_type.dart';

class CleanerReview {
  final int? id;
  final int cleanerId;
  final int? jobId;
  final String reviewerName;
  final double rating;
  final DateTime date;
  final String comment;
  final bool hasPhotos;
  final List<String>? photoUrls;
  final int? reviewerId;

  CleanerReview({
    this.id,
    required this.cleanerId,
    this.jobId,
    required this.reviewerName,
    required this.rating,
    required this.date,
    required this.comment,
    this.hasPhotos = false,
    this.photoUrls,
    this.reviewerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cleaner_id': cleanerId,
      'job_id': jobId,
      'reviewer_name': reviewerName,
      'rating': rating,
      'date': date.toIso8601String(),
      'comment': comment,
      'has_photos': hasPhotos ? 1 : 0,
      'photo_urls': photoUrls?.join(','),
      'reviewer_id': reviewerId,
    };
  }

  factory CleanerReview.fromMap(Map<String, dynamic> map) {
    final cleanerIdValue = readInt(map['cleaner_id']);
    if (cleanerIdValue == null) {
      throw Exception(
        'cleaner_id is required and must be int. Got: ${map['cleaner_id']} (${map['cleaner_id']?.runtimeType})',
      );
    }

    DateTime? dateValue;
    if (map.containsKey('date') && map['date'] != null) {
      dateValue = readDate(map['date']);
    }
    if (dateValue == null &&
        map.containsKey('created_at') &&
        map['created_at'] != null) {
      dateValue = readDate(map['created_at']);
    }
    dateValue ??= DateTime.now();

    return CleanerReview(
      id: readInt(map['id']),
      cleanerId: cleanerIdValue,
      jobId: readInt(map['job_id']),
      reviewerName: readString(map['reviewer_name']) ?? 'Anonymous',
      rating: readDouble(map['rating']) ?? 0.0,
      date: dateValue,
      comment: readString(map['comment']) ?? '',
      hasPhotos: readBool(map['has_photos']),
      photoUrls: map['photo_urls'] != null
          ? (readString(map['photo_urls']) ?? '')
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()
          : null,
      reviewerId: readInt(map['reviewer_id']),
    );
  }
}
