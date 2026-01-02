import 'package:sqflite/sqflite.dart';
import '../../databases/dbhelper.dart';
import '../../models/cleaner_review.dart';
import 'cleaner_reviews_repo.dart';

class CleanerReviewsDB extends AbstractCleanerReviewsRepo {
  static const String tableName = 'cleaner_reviews';

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
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'cleaner_id = ?',
        whereArgs: [cleanerId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => CleanerReview.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getReviewsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleanerReview> addReview(CleanerReview review) async {
    try {
      final db = await DBHelper.getDatabase();
      final reviewMap = review.toMap();
      reviewMap.remove('id');
      final id = await db.insert(tableName, reviewMap);
      return review.copyWith(id: id);
    } catch (e, stacktrace) {
      print('addReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    try {
      final db = await DBHelper.getDatabase();
      await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [reviewId],
      );
    } catch (e, stacktrace) {
      print('deleteReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<double> getAverageRatingForCleaner(int cleanerId) async {
    try {
      final db = await DBHelper.getDatabase();
      final result = await db.rawQuery(
        'SELECT AVG(rating) as avg_rating FROM $tableName WHERE cleaner_id = ?',
        [cleanerId],
      );
      final avgRating = result.first['avg_rating'] as num?;
      return avgRating?.toDouble() ?? 0.0;
    } catch (e, stacktrace) {
      print('getAverageRatingForCleaner error: $e --> $stacktrace');
      return 0.0;
    }
  }

  @override
  Future<int> getReviewCountForCleaner(int cleanerId) async {
    try {
      final db = await DBHelper.getDatabase();
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE cleaner_id = ?',
        [cleanerId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
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




