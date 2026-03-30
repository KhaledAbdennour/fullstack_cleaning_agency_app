import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../core/services/notification_service_enhanced.dart';
import '../../models/cleaner_review.dart';
import '../../models/job_model.dart';
import '../../models/notification_item.dart';
import '../jobs/jobs_repo.dart';
import 'cleaner_reviews_repo.dart';

class CleanerReviewsDB extends AbstractCleanerReviewsRepo {
  static const String collectionName = 'cleaner_reviews';

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
      DebugLogger.log(
        'CleanerReviewsDB',
        'getReviewsForCleaner_START',
        data: {
          'cleanerId': cleanerId,
          'cleanerIdType': cleanerId.runtimeType.toString(),
          'collection': collectionName,
          'filters': 'cleaner_id == $cleanerId (int), orderBy date desc',
          'dateField': 'date',
        },
      );

      QuerySnapshot snapshot;
      bool usedFallback = false;

      try {
        snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('cleaner_id', isEqualTo: cleanerId)
            .orderBy('date', descending: true)
            .get();

        DebugLogger.log(
          'CleanerReviewsDB',
          'getReviewsForCleaner_QUERY_SUCCESS',
          data: {
            'cleanerId': cleanerId,
            'resultCount': snapshot.docs.length,
            'usedFallback': false,
          },
        );
      } catch (e) {
        final errorStr = e.toString();
        if (errorStr.contains('FAILED_PRECONDITION') ||
            errorStr.contains('requires an index') ||
            errorStr.contains('index')) {
          DebugLogger.log(
            'CleanerReviewsDB',
            'getReviewsForCleaner_INDEX_ERROR',
            data: {
              'cleanerId': cleanerId,
              'error': errorStr,
              'willTryFallback': true,
            },
          );

          snapshot = await FirebaseConfig.firestore
              .collection(collectionName)
              .where('cleaner_id', isEqualTo: cleanerId)
              .get();

          usedFallback = true;

          DebugLogger.log(
            'CleanerReviewsDB',
            'getReviewsForCleaner_FALLBACK_SUCCESS',
            data: {
              'cleanerId': cleanerId,
              'resultCount': snapshot.docs.length,
              'usedFallback': true,
            },
          );
        } else {
          rethrow;
        }
      }

      final reviews = <CleanerReview>[];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          final data = Map<String, dynamic>.from(raw as Map);

          final id = int.tryParse(doc.id);
          if (id != null) {
            data['id'] = id;
          }

          if (reviews.isEmpty && snapshot.docs.isNotEmpty) {
            final cleanerIdValue = data['cleaner_id'];
            final dateValue = data['date'];
            final createdAtValue = data['created_at'];

            DebugLogger.log(
              'CleanerReviewsDB',
              'getReviewsForCleaner_FIRST_DOC_TYPES',
              data: {
                'cleanerId': cleanerId,
                'firstDoc_cleaner_id_value': cleanerIdValue,
                'firstDoc_cleaner_id_type':
                    cleanerIdValue?.runtimeType.toString(),
                'firstDoc_date_value': dateValue is String
                    ? (dateValue.length > 20
                        ? dateValue.substring(0, 20)
                        : dateValue)
                    : dateValue,
                'firstDoc_date_type': dateValue?.runtimeType.toString(),
                'firstDoc_created_at_type':
                    createdAtValue?.runtimeType.toString(),
              },
            );
          }

          final review = CleanerReview.fromMap(data);
          reviews.add(review);
        } catch (e, stack) {
          DebugLogger.error(
            'CleanerReviewsDB',
            'getReviewsForCleaner_PARSE_ERROR',
            e,
            stack,
            data: {
              'docId': doc.id,
              'cleanerId': cleanerId,
              'docData': doc.data(),
            },
          );
        }
      }

      if (usedFallback) {
        reviews.sort((a, b) => b.date.compareTo(a.date));
      }

      if (reviews.isNotEmpty) {
        final firstThree = reviews
            .take(3)
            .map(
              (r) => {
                'id': r.id,
                'cleanerId': r.cleanerId,
                'rating': r.rating,
                'date': r.date.toIso8601String(),
                'hasComment': r.comment.isNotEmpty,
              },
            )
            .toList();

        DebugLogger.log(
          'CleanerReviewsDB',
          'getReviewsForCleaner_RESULT',
          data: {
            'cleanerId': cleanerId,
            'totalCount': reviews.length,
            'firstThree': firstThree,
          },
        );
      } else {
        DebugLogger.log(
          'CleanerReviewsDB',
          'getReviewsForCleaner_EMPTY',
          data: {
            'cleanerId': cleanerId,
            'docsFetched': snapshot.docs.length,
            'dateField': 'date',
          },
        );
      }

      return reviews;
    } catch (e, stacktrace) {
      DebugLogger.error(
        'CleanerReviewsDB',
        'getReviewsForCleaner_ERROR',
        e,
        stacktrace,
        data: {'cleanerId': cleanerId},
      );

      return [];
    }
  }

  @override
  Future<CleanerReview> addReview(CleanerReview review) async {
    try {
      if (review.jobId != null) {
        final jobsRepo = AbstractJobsRepo.getInstance();
        final job = await jobsRepo.getJobById(review.jobId!);
        if (job == null) {
          throw Exception('Job not found');
        }
        if (job.status != JobStatus.completed) {
          throw Exception(
            'Reviews can only be added for completed jobs. Current job status: ${job.status.name}',
          );
        }
      }

      String? docId;
      bool isUpdate = false;

      if (review.jobId != null && review.reviewerId != null) {
        docId = 'job_${review.jobId}_reviewer_${review.reviewerId}';

        final existingDoc = await FirebaseConfig.firestore
            .collection(collectionName)
            .doc(docId)
            .get();

        isUpdate = existingDoc.exists;
      } else {
        if (review.reviewerId != null) {
          final querySnapshot = await FirebaseConfig.firestore
              .collection(collectionName)
              .where('cleaner_id', isEqualTo: review.cleanerId)
              .where('reviewer_id', isEqualTo: review.reviewerId)
              .where('job_id', isEqualTo: review.jobId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            docId = querySnapshot.docs.first.id;
            isUpdate = true;
          }
        }

        if (docId == null) {
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
        }
      }

      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final reviewRef =
            FirebaseConfig.firestore.collection(collectionName).doc(docId!);

        final reviewMap = review.toMap();
        reviewMap.remove('id');
        reviewMap['date'] = review.date.toIso8601String();
        reviewMap['updated_at'] = FieldValue.serverTimestamp();

        if (isUpdate) {
          transaction.update(reviewRef, reviewMap);
        } else {
          reviewMap['created_at'] = FieldValue.serverTimestamp();
          transaction.set(reviewRef, reviewMap);
        }

        final allReviewsSnapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('cleaner_id', isEqualTo: review.cleanerId)
            .get();

        final ratings = allReviewsSnapshot.docs
            .where(
              (doc) => doc.id != docId,
            )
            .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
            .where((r) => r > 0)
            .toList();

        ratings.add(review.rating);

        final ratingAvg = ratings.isEmpty
            ? 0.0
            : ratings.fold<double>(0.0, (a, b) => a + b) / ratings.length;
        final ratingCount = ratings.length;

        final cleanerRef = FirebaseConfig.firestore
            .collection('cleaners')
            .doc(review.cleanerId.toString());

        final cleanerDoc = await transaction.get(cleanerRef);
        if (cleanerDoc.exists) {
          transaction.update(cleanerRef, {
            'rating': ratingAvg,
            'rating_avg': ratingAvg,
            'rating_count': ratingCount,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          final profileRef = FirebaseConfig.firestore
              .collection('profiles')
              .doc(review.cleanerId.toString());

          final profileDoc = await transaction.get(profileRef);
          if (profileDoc.exists) {
            transaction.update(profileRef, {
              'rating': ratingAvg,
              'rating_avg': ratingAvg,
              'rating_count': ratingCount,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      final savedDoc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .get();

      if (savedDoc.exists) {
        final data = savedDoc.data()!;

        final id = int.tryParse(savedDoc.id);
        if (id != null) {
          data['id'] = id;
        }
        final savedReview = CleanerReview.fromMap(data);

        Future.microtask(() async {
          try {
            await NotificationServiceEnhanced.createNotification(
              userId: review.cleanerId.toString(),
              title: 'New Review Received',
              body:
                  '${review.reviewerName} left you a ${review.rating}-star review.',
              type: NotificationType.reviewReceived,
              senderId: review.reviewerId?.toString(),
              jobId: review.jobId,
            );

            if (review.jobId != null) {
              try {
                final jobsRepo = AbstractJobsRepo.getInstance();
                final job = await jobsRepo.getJobById(review.jobId!);
                if (job != null) {
                  String? notifyUserId;
                  if (job.clientId == review.reviewerId &&
                      job.assignedWorkerId != null) {
                    notifyUserId = job.assignedWorkerId.toString();
                  } else if (job.assignedWorkerId == review.reviewerId &&
                      job.clientId != null) {
                    notifyUserId = job.clientId.toString();
                  }

                  if (notifyUserId != null) {
                    await NotificationServiceEnhanced.createNotification(
                      userId: notifyUserId,
                      title: 'Review Added',
                      body: 'A review has been added for job "${job.title}".',
                      type: NotificationType.reviewAdded,
                      senderId: review.reviewerId?.toString(),
                      jobId: review.jobId,
                      workerId: job.assignedWorkerId,
                      clientId: job.clientId,
                      agencyId: job.agencyId,
                    );
                  }

                  if (job.agencyId != null &&
                      job.agencyId != review.cleanerId) {
                    await NotificationServiceEnhanced.createNotification(
                      userId: job.agencyId.toString(),
                      title: 'Review Added for Worker',
                      body:
                          'A review was added for your worker on job "${job.title}".',
                      type: NotificationType.reviewAdded,
                      workerId: job.assignedWorkerId,
                      clientId: job.clientId,
                      agencyId: job.agencyId,
                      senderId: review.reviewerId?.toString(),
                      jobId: review.jobId,
                      route: '/jobDetails',
                      routeId: review.jobId.toString(),
                    );
                  }
                }
              } catch (e) {
                print('Error sending review notification to other party: $e');
              }
            }
          } catch (e) {
            print('Error sending review notification: $e');
          }
        });

        return savedReview;
      }

      return review;
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
