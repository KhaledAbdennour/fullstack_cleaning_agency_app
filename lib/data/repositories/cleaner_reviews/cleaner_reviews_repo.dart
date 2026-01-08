import '../../models/cleaner_review.dart';
import 'cleaner_reviews_repo_db.dart';


abstract class AbstractCleanerReviewsRepo {
  Future<List<CleanerReview>> getReviewsForCleaner(int cleanerId);
  Future<CleanerReview> addReview(CleanerReview review);
  Future<void> deleteReview(int reviewId);
  Future<double> getAverageRatingForCleaner(int cleanerId);
  Future<int> getReviewCountForCleaner(int cleanerId);

  static AbstractCleanerReviewsRepo? _instance;
  static AbstractCleanerReviewsRepo getInstance() {
    _instance ??= CleanerReviewsDB();
    return _instance!;
  }
}




