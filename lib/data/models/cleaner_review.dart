import 'package:flutter/material.dart';


class CleanerReview {
  final int? id;
  final int cleanerId;
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
      'reviewer_name': reviewerName,
      'rating': rating,
      'date': date.toIso8601String(),
      'comment': comment,
      'has_photos': hasPhotos ? 1 : 0,
      'photo_urls': photoUrls != null ? photoUrls!.join(',') : null,
      'reviewer_id': reviewerId,
    };
  }

  factory CleanerReview.fromMap(Map<String, dynamic> map) {
    return CleanerReview(
      id: map['id'] as int?,
      cleanerId: map['cleaner_id'] as int,
      reviewerName: map['reviewer_name'] as String,
      rating: (map['rating'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      comment: map['comment'] as String,
      hasPhotos: (map['has_photos'] as int? ?? 0) == 1,
      photoUrls: map['photo_urls'] != null
          ? (map['photo_urls'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      reviewerId: map['reviewer_id'] as int?,
    );
  }
}


