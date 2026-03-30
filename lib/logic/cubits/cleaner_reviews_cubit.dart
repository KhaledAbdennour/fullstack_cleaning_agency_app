import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cleaner_review.dart';
import '../../data/repositories/cleaner_reviews/cleaner_reviews_repo.dart';

abstract class CleanerReviewsState {}

class CleanerReviewsInitial extends CleanerReviewsState {}

class CleanerReviewsLoading extends CleanerReviewsState {}

class CleanerReviewsLoaded extends CleanerReviewsState {
  final List<CleanerReview> allReviews;
  final List<CleanerReview> filteredReviews;
  final String sortBy;
  final int? ratingFilter;
  final bool withPhotosOnly;
  final double averageRating;
  final int reviewCount;

  CleanerReviewsLoaded({
    required this.allReviews,
    required this.filteredReviews,
    this.sortBy = 'recency',
    this.ratingFilter,
    this.withPhotosOnly = false,
    required this.averageRating,
    required this.reviewCount,
  });
}

class CleanerReviewsError extends CleanerReviewsState {
  final String message;
  CleanerReviewsError(this.message);
}

class CleanerReviewsCubit extends Cubit<CleanerReviewsState> {
  final AbstractCleanerReviewsRepo _reviewsRepo =
      AbstractCleanerReviewsRepo.getInstance();

  CleanerReviewsCubit() : super(CleanerReviewsInitial());

  Future<void> loadReviews(int cleanerId) async {
    emit(CleanerReviewsLoading());
    try {
      final reviews = await _reviewsRepo.getReviewsForCleaner(cleanerId);
      final averageRating = await _reviewsRepo.getAverageRatingForCleaner(
        cleanerId,
      );
      final reviewCount = await _reviewsRepo.getReviewCountForCleaner(
        cleanerId,
      );

      emit(
        CleanerReviewsLoaded(
          allReviews: reviews,
          filteredReviews: _applyFilters(reviews),
          averageRating: averageRating,
          reviewCount: reviewCount,
        ),
      );
    } catch (e) {
      emit(CleanerReviewsError('Failed to load reviews: $e'));
    }
  }

  List<CleanerReview> _applyFilters(
    List<CleanerReview> reviews, {
    String? sortBy,
    int? ratingFilter,
    bool? withPhotosOnly,
  }) {
    var filtered = List<CleanerReview>.from(reviews);

    final rating = ratingFilter ??
        (state is CleanerReviewsLoaded
            ? (state as CleanerReviewsLoaded).ratingFilter
            : null);
    if (rating != null) {
      filtered = filtered.where((r) => r.rating.floor() == rating).toList();
    }

    final photosOnly = withPhotosOnly ??
        (state is CleanerReviewsLoaded
            ? (state as CleanerReviewsLoaded).withPhotosOnly
            : false);
    if (photosOnly) {
      filtered = filtered.where((r) => r.hasPhotos).toList();
    }

    final sort = sortBy ??
        (state is CleanerReviewsLoaded
            ? (state as CleanerReviewsLoaded).sortBy
            : 'recency');

    switch (sort) {
      case 'highest':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'recency':
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return filtered;
  }

  void updateSort(String sortBy, int cleanerId) {
    if (state is CleanerReviewsLoaded) {
      final currentState = state as CleanerReviewsLoaded;
      final filtered = _applyFilters(
        currentState.allReviews,
        sortBy: sortBy,
        ratingFilter: currentState.ratingFilter,
        withPhotosOnly: currentState.withPhotosOnly,
      );
      emit(currentState.copyWith(filteredReviews: filtered, sortBy: sortBy));
    }
  }

  void updateRatingFilter(int? rating, int cleanerId) {
    if (state is CleanerReviewsLoaded) {
      final currentState = state as CleanerReviewsLoaded;
      final filtered = _applyFilters(
        currentState.allReviews,
        sortBy: currentState.sortBy,
        ratingFilter: rating,
        withPhotosOnly: currentState.withPhotosOnly,
      );
      emit(
        currentState.copyWith(filteredReviews: filtered, ratingFilter: rating),
      );
    }
  }

  void togglePhotosFilter(bool enabled, int cleanerId) {
    if (state is CleanerReviewsLoaded) {
      final currentState = state as CleanerReviewsLoaded;
      final filtered = _applyFilters(
        currentState.allReviews,
        sortBy: currentState.sortBy,
        ratingFilter: currentState.ratingFilter,
        withPhotosOnly: enabled,
      );
      emit(
        currentState.copyWith(
          filteredReviews: filtered,
          withPhotosOnly: enabled,
        ),
      );
    }
  }

  Future<void> refresh(int cleanerId) async {
    await loadReviews(cleanerId);
  }
}

extension CleanerReviewsLoadedCopyWith on CleanerReviewsLoaded {
  CleanerReviewsLoaded copyWith({
    List<CleanerReview>? allReviews,
    List<CleanerReview>? filteredReviews,
    String? sortBy,
    int? ratingFilter,
    bool? withPhotosOnly,
    double? averageRating,
    int? reviewCount,
  }) {
    return CleanerReviewsLoaded(
      allReviews: allReviews ?? this.allReviews,
      filteredReviews: filteredReviews ?? this.filteredReviews,
      sortBy: sortBy ?? this.sortBy,
      ratingFilter: ratingFilter ?? this.ratingFilter,
      withPhotosOnly: withPhotosOnly ?? this.withPhotosOnly,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
