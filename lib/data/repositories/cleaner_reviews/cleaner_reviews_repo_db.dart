import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/cleaner_review.dart';
import 'cleaner_reviews_repo.dart';

class CleanerReviewsDB extends AbstractCleanerReviewsRepo {
  static const String tableName = 'cleaner_reviews';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cleaner_id INTEGER NOT NULL,
      reviewer_name TEXT NOT NULL,
      rating REAL NOT NULL,
      date TEXT NOT NULL,
      comment TEXT NOT NULL,
      has_photos INTEGER NOT NULL DEFAULT 0,
      photo_urls TEXT,
      reviewer_id INTEGER,
      FOREIGN KEY (cleaner_id) REFERENCES profiles(id),
      FOREIGN KEY (reviewer_id) REFERENCES profiles(id)
    )
  ''';

  @override
  Future<List<CleanerReview>> getReviewsForCleaner(int cleanerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('cleaner_id', cleanerId)
          .order('date', ascending: false);
      
      return (response as List)
          .map((map) => CleanerReview.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getReviewsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleanerReview> addReview(CleanerReview review) async {
    try {
      final reviewMap = review.toMap();
      reviewMap.remove('id');
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(reviewMap)
          .select()
          .single();
      
      return CleanerReview.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('addReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .delete()
          .eq('id', reviewId);
    } catch (e, stacktrace) {
      print('deleteReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<double> getAverageRatingForCleaner(int cleanerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select('rating')
          .eq('cleaner_id', cleanerId);
      
      if (response.isEmpty) return 0.0;
      
      final ratings = (response as List)
          .map((r) => (r['rating'] as num).toDouble())
          .toList();
      
      if (ratings.isEmpty) return 0.0;
      
      final sum = ratings.fold<double>(0.0, (a, b) => a + b);
      return sum / ratings.length;
    } catch (e, stacktrace) {
      print('getAverageRatingForCleaner error: $e --> $stacktrace');
      return 0.0;
    }
  }

  @override
  Future<int> getReviewCountForCleaner(int cleanerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('cleaner_id', cleanerId);
      
      return response.count ?? 0;
    } catch (e, stacktrace) {
      print('getReviewCountForCleaner error: $e --> $stacktrace');
      return 0;
    }
  }
}

extension CleanerReviewCopyWith on CleanerReview {
  CleanerReview copyWith({
    int? id,
    int? cleanerId,
    String? reviewerName,
    double? rating,
    DateTime? date,
    String? comment,
    bool? hasPhotos,
    List<String>? photoUrls,
    int? reviewerId,
  }) {
    return CleanerReview(
      id: id ?? this.id,
      cleanerId: cleanerId ?? this.cleanerId,
      reviewerName: reviewerName ?? this.reviewerName,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      hasPhotos: hasPhotos ?? this.hasPhotos,
      photoUrls: photoUrls ?? this.photoUrls,
      reviewerId: reviewerId ?? this.reviewerId,
    );
  }
}
