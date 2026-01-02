import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/cleaner_review.dart';
import 'cleaner_reviews_repo.dart';

class CleanerReviewsDB extends AbstractCleanerReviewsRepo {
  static const String collectionName = 'cleaner_reviews';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $collectionName (
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
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('cleaner_id', isEqualTo: cleanerId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return CleanerReview.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getReviewsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleanerReview> addReview(CleanerReview review) async {
    try {
      final reviewMap = review.toMap();
      final id = reviewMap.remove('id');
      
      String docId;
      if (id != null && id is int) {
        docId = id.toString();
      } else {
        // Generate new ID
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .orderBy('id', descending: true)
            .limit(1)
            .get();
        
        int newId = 1;
        if (snapshot.docs.isNotEmpty) {
          final maxId = snapshot.docs.first.data()['id'] as int? ?? 0;
          newId = maxId + 1;
        }
        docId = newId.toString();
        reviewMap['id'] = newId;
      }
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(reviewMap);
      
      final data = reviewMap;
      data['id'] = int.parse(docId);
      return CleanerReview.fromMap(data);
    } catch (e, stacktrace) {
      print('addReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(reviewId.toString())
          .delete();
    } catch (e, stacktrace) {
      print('deleteReview error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<double> getAverageRatingForCleaner(int cleanerId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('cleaner_id', isEqualTo: cleanerId)
          .get();
      
      if (snapshot.docs.isEmpty) return 0.0;
      
      final ratings = snapshot.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .where((r) => r > 0)
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
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('cleaner_id', isEqualTo: cleanerId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
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
