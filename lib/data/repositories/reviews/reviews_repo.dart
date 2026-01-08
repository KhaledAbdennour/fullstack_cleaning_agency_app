import '../../models/review_model.dart';
import 'reviews_repo_db.dart' show ReviewsDB;

abstract class AbstractReviewsRepo {
  Future<Review> addReview({
    required int jobId,
    required String revieweeId,
    required int rating,
    required String comment,
    int? bookingId,
  });
  
  Future<List<Review>> getReviewsForReviewee(String revieweeId);
  Future<List<Review>> getReviewsForJob(int jobId);
  Future<List<Review>> getReviewsByReviewer(String reviewerId);

  static AbstractReviewsRepo? _instance;
  static AbstractReviewsRepo getInstance() {
    _instance ??= ReviewsDB();
    return _instance!;
  }
}
