import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../core/services/notification_service_enhanced.dart';
import '../../../core/utils/firestore_type.dart';
import '../../models/review_model.dart';
import '../../models/job_model.dart';
import '../../models/notification_item.dart';
import '../jobs/jobs_repo.dart';
import '../profiles/profile_repo.dart';
import 'reviews_repo.dart';

class ReviewsDB extends AbstractReviewsRepo {
  static const String collectionName = 'reviews';

  @override
  Future<Review> addReview({
    required int jobId,
    required String revieweeId,
    required int rating,
    required String comment,
    int? bookingId,
  }) async {
    try {
      DebugLogger.log(
        'ReviewsDB',
        'addReview_START',
        data: {
          'jobId': jobId,
          'revieweeId': revieweeId,
          'rating': rating,
          'hasComment': comment.isNotEmpty,
          'bookingId': bookingId,
        },
      );

      final jobsRepo = AbstractJobsRepo.getInstance();
      final job = await jobsRepo.getJobById(jobId);

      if (job == null) {
        throw Exception('Job not found');
      }

      DebugLogger.log(
        'ReviewsDB',
        'addReview_JOB_LOADED',
        data: {
          'jobId': jobId,
          'status': job.status.name,
          'clientDone': job.clientDone,
          'workerDone': job.workerDone,
        },
      );

      if (job.status != JobStatus.completed) {
        throw Exception(
          'Reviews can only be added for completed jobs. Current job status: ${job.status.name}',
        );
      }

      final clientDone = readBool(job.clientDone);
      final workerDone = readBool(job.workerDone);

      if (!clientDone || !workerDone) {
        throw Exception(
          'Job is not fully completed yet. Both parties must confirm completion before leaving a review.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final currentUserIdInt = prefs.getInt('current_user_id');

      if (currentUserIdInt == null) {
        throw Exception('User not logged in');
      }

      final profilesRepo = AbstractProfileRepo.getInstance();
      final reviewerProfile = await profilesRepo.getProfileById(
        currentUserIdInt,
      );

      if (reviewerProfile == null) {
        throw Exception('User profile not found');
      }

      final reviewerRole = readString(reviewerProfile['user_type']) ?? 'Client';
      final reviewerId = currentUserIdInt.toString();

      String revieweeRole = 'Individual Cleaner';
      if (job.assignedWorkerId != null) {
        final workerProfile = await profilesRepo.getProfileById(
          job.assignedWorkerId!,
        );
        if (workerProfile != null) {
          revieweeRole =
              readString(workerProfile['user_type']) ?? 'Individual Cleaner';
        }
      }

      DebugLogger.log(
        'ReviewsDB',
        'addReview_USER_DATA',
        data: {
          'reviewerId': reviewerId,
          'reviewerRole': reviewerRole,
          'revieweeId': revieweeId,
          'revieweeRole': revieweeRole,
        },
      );

      final reviewDocId = 'job_${jobId}_reviewer_$reviewerId';
      final reviewRef =
          FirebaseConfig.firestore.collection(collectionName).doc(reviewDocId);

      final existingDoc = await reviewRef.get();
      if (existingDoc.exists) {
        throw Exception('Review already exists for this job');
      }

      final revieweeIdInt = int.tryParse(revieweeId);
      if (revieweeIdInt == null) {
        throw Exception('Invalid reviewee ID format: $revieweeId');
      }

      DebugLogger.log(
        'ReviewsDB',
        'addReview_BEFORE_WRITE',
        data: {
          'reviewDocId': reviewDocId,
          'jobId': jobId,
          'revieweeId': revieweeId,
          'revieweeIdInt': revieweeIdInt,
          'rating': rating,
          'hasComment': comment.isNotEmpty,
        },
      );

      final reviewData = {
        'job_id': jobId,
        if (bookingId != null) 'booking_id': bookingId,
        'reviewer_id': reviewerId,
        'reviewer_role': reviewerRole,
        'reviewee_id': revieweeId,
        'reviewee_role': revieweeRole,
        'rating': rating,
        'comment': comment,
        'photos': <String>[],
        'status': 'active',
        'reviewer_user_id_int': currentUserIdInt,
        'reviewee_user_id_int': revieweeIdInt,
        'created_at': FieldValue.serverTimestamp(),
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      };

      await reviewRef.set(reviewData);

      DebugLogger.log(
        'ReviewsDB',
        'addReview_REVIEW_SAVED',
        data: {
          'reviewDocId': reviewDocId,
          'jobId': jobId,
          'collection': 'reviews',
        },
      );

      try {
        final oldReviewDocId = 'job_${jobId}_reviewer_$reviewerId';
        final oldReviewRef = FirebaseConfig.firestore
            .collection('cleaner_reviews')
            .doc(oldReviewDocId);

        final reviewerName =
            readString(reviewerProfile['full_name']) ?? 'Anonymous';

        final now = DateTime.now();
        final oldReviewData = {
          'cleaner_id': revieweeIdInt,
          'job_id': jobId,
          'reviewer_id': currentUserIdInt,
          'reviewer_name': reviewerName,
          'rating': rating.toDouble(),
          'comment': comment,
          'date': now.toIso8601String(),
          'has_photos': 0,
          'photo_urls': null,
          'created_at': FieldValue.serverTimestamp(),
          'created_at_ms': now.millisecondsSinceEpoch,
        };

        await oldReviewRef.set(oldReviewData);

        DebugLogger.log(
          'ReviewsDB',
          'addReview_OLD_COLLECTION_SAVED',
          data: {
            'oldReviewDocId': oldReviewDocId,
            'cleanerId': revieweeIdInt,
            'cleanerIdType': revieweeIdInt.runtimeType.toString(),
            'dateField': 'date',
            'dateValue': now.toIso8601String(),
            'created_at_ms': now.millisecondsSinceEpoch,
            'collection': 'cleaner_reviews',
          },
        );
      } catch (e, stack) {
        DebugLogger.error(
          'ReviewsDB',
          'addReview_OLD_COLLECTION_FAILED',
          e,
          stack,
          data: {'revieweeId': revieweeId},
        );
      }

      final profileDocId = revieweeIdInt.toString();

      try {
        final profileRef =
            FirebaseConfig.firestore.collection('profiles').doc(profileDocId);

        final profileDoc = await profileRef.get();
        if (!profileDoc.exists) {
          DebugLogger.log(
            'ReviewsDB',
            'addReview_PROFILE_NOT_FOUND',
            data: {'revieweeId': revieweeId, 'profileDocId': profileDocId},
          );
        } else {
          final profileData = profileDoc.data()!;
          final oldRatingAvg = readDouble(profileData['rating']) ??
              readDouble(profileData['rating_avg']) ??
              0.0;
          final oldRatingCount = readInt(profileData['rating_count']) ?? 0;

          DebugLogger.log(
            'ReviewsDB',
            'addReview_AGGREGATES_BEFORE',
            data: {
              'revieweeId': revieweeId,
              'profileDocId': profileDocId,
              'oldRatingAvg': oldRatingAvg,
              'oldRatingAvgType': oldRatingAvg.runtimeType.toString(),
              'oldRatingCount': oldRatingCount,
              'oldRatingCountType': oldRatingCount.runtimeType.toString(),
            },
          );

          final newReviewsSnapshot = await FirebaseConfig.firestore
              .collection(collectionName)
              .where('reviewee_id', isEqualTo: revieweeId)
              .get();

          final oldReviewsSnapshot = await FirebaseConfig.firestore
              .collection('cleaner_reviews')
              .where('cleaner_id', isEqualTo: revieweeIdInt)
              .get();

          final ratingsMap = <String, int>{};

          for (final doc in newReviewsSnapshot.docs) {
            final data = doc.data();
            final jobId = readInt(data['job_id']) ?? 0;
            final reviewerId = readString(data['reviewer_id']) ?? '';
            final key = '${jobId}_$reviewerId';
            final rating = readInt(data['rating']) ?? 0;
            if (rating > 0 && rating <= 5) {
              ratingsMap[key] = rating;
            }
          }

          for (final doc in oldReviewsSnapshot.docs) {
            final data = doc.data();
            final jobId = readInt(data['job_id']) ?? 0;
            final reviewerId = readInt(data['reviewer_id']) ?? 0;
            final key = '${jobId}_$reviewerId';
            final rating = (readDouble(data['rating']) ?? 0.0).round();
            if (rating > 0 && rating <= 5 && !ratingsMap.containsKey(key)) {
              ratingsMap[key] = rating;
            }
          }

          final ratings = ratingsMap.values.toList();
          final ratingAvg = ratings.isEmpty
              ? 0.0
              : ratings.fold<double>(0.0, (a, b) => a + b) / ratings.length;
          final ratingCount = ratings.length;

          DebugLogger.log(
            'ReviewsDB',
            'addReview_AGGREGATES_CALCULATED',
            data: {
              'revieweeId': revieweeId,
              'newReviewsCount': newReviewsSnapshot.docs.length,
              'oldReviewsCount': oldReviewsSnapshot.docs.length,
              'uniqueReviewsCount': ratings.length,
              'newRatingAvg': ratingAvg,
              'newRatingCount': ratingCount,
            },
          );

          await FirebaseConfig.firestore.runTransaction((transaction) async {
            final profileDocInTx = await transaction.get(profileRef);
            if (!profileDocInTx.exists) {
              DebugLogger.log(
                'ReviewsDB',
                'addReview_PROFILE_NOT_FOUND_IN_TX',
                data: {'profileDocId': profileDocId},
              );
              return;
            }

            transaction.update(profileRef, {
              'rating': ratingAvg,
              'rating_avg': ratingAvg,
              'rating_count': ratingCount,
              'updated_at': FieldValue.serverTimestamp(),
            });

            DebugLogger.log(
              'ReviewsDB',
              'addReview_AGGREGATES_UPDATED',
              data: {
                'revieweeId': revieweeId,
                'profileDocId': profileDocId,
                'oldRatingAvg': oldRatingAvg,
                'newRatingAvg': ratingAvg,
                'oldRatingCount': oldRatingCount,
                'newRatingCount': ratingCount,
                'ratingAvgType': ratingAvg.runtimeType.toString(),
                'ratingCountType': ratingCount.runtimeType.toString(),
              },
            );
          });
        }
      } catch (e, stack) {
        DebugLogger.error(
          'ReviewsDB',
          'addReview_AGGREGATE_UPDATE_FAILED',
          e,
          stack,
          data: {'revieweeId': revieweeId, 'profileDocId': profileDocId},
        );
      }

      try {
        await NotificationServiceEnhanced.createNotification(
          userId: revieweeId,
          title: 'New Review Received',
          body: 'You received a $rating-star review.',
          type: NotificationType.reviewReceived,
          senderId: reviewerId,
          jobId: jobId,
        );
      } catch (e) {
        DebugLogger.error(
          'ReviewsDB',
          'addReview_NOTIFICATION_FAILED',
          e,
          StackTrace.current,
          data: {'revieweeId': revieweeId},
        );
      }

      final savedDoc = await reviewRef.get();
      if (savedDoc.exists) {
        final savedReview = Review.fromMap(savedDoc.data()!, savedDoc.id);
        DebugLogger.log(
          'ReviewsDB',
          'addReview_SUCCESS',
          data: {'reviewId': savedReview.id, 'jobId': jobId},
        );
        return savedReview;
      }

      throw Exception('Review was created but could not be retrieved');
    } catch (e, stack) {
      DebugLogger.error(
        'ReviewsDB',
        'addReview_ERROR',
        e,
        stack,
        data: {'jobId': jobId, 'revieweeId': revieweeId},
      );
      rethrow;
    }
  }

  @override
  Future<List<Review>> getReviewsForReviewee(String revieweeId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('reviewee_id', isEqualTo: revieweeId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review.fromMap(data, doc.id);
      }).toList();
    } catch (e, stack) {
      DebugLogger.error(
        'ReviewsDB',
        'getReviewsForReviewee_ERROR',
        e,
        stack,
        data: {'revieweeId': revieweeId},
      );

      try {
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('reviewee_id', isEqualTo: revieweeId)
            .get();

        final reviews = snapshot.docs.map((doc) {
          final data = doc.data();
          return Review.fromMap(data, doc.id);
        }).toList();

        reviews.sort((a, b) {
          final aMs =
              a.createdAtMs ?? (a.createdAt?.millisecondsSinceEpoch ?? 0);
          final bMs =
              b.createdAtMs ?? (b.createdAt?.millisecondsSinceEpoch ?? 0);
          return bMs.compareTo(aMs);
        });

        return reviews;
      } catch (e2) {
        return [];
      }
    }
  }

  @override
  Future<List<Review>> getReviewsForJob(int jobId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('job_id', isEqualTo: jobId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review.fromMap(data, doc.id);
      }).toList();
    } catch (e, stack) {
      DebugLogger.error(
        'ReviewsDB',
        'getReviewsForJob_ERROR',
        e,
        stack,
        data: {'jobId': jobId},
      );
      return [];
    }
  }

  @override
  Future<List<Review>> getReviewsByReviewer(String reviewerId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('reviewer_id', isEqualTo: reviewerId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review.fromMap(data, doc.id);
      }).toList();
    } catch (e, stack) {
      DebugLogger.error(
        'ReviewsDB',
        'getReviewsByReviewer_ERROR',
        e,
        stack,
        data: {'reviewerId': reviewerId},
      );
      return [];
    }
  }
}
