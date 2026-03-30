import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/services/notification_backend_service.dart';
import '../../../core/services/notification_service_enhanced.dart';
import '../../../core/debug/debug_logger.dart';
import '../../models/booking_model.dart';
import '../../models/job_model.dart';
import '../../models/notification_item.dart';
import '../jobs/jobs_repo.dart';
import '../profiles/profile_repo.dart';
import 'bookings_repo.dart';

class BookingsDB extends AbstractBookingsRepo {
  static const String collectionName = 'bookings';

  static const String sqlCode = '''
    CREATE TABLE $collectionName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      job_id INTEGER NOT NULL,
      client_id INTEGER NOT NULL,
      provider_id INTEGER,
      status TEXT NOT NULL,
      bid_price REAL,
      message TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (job_id) REFERENCES jobs(id),
      FOREIGN KEY (client_id) REFERENCES profiles(id),
      FOREIGN KEY (provider_id) REFERENCES profiles(id)
    )
  ''';

  @override
  Future<List<Booking>> getBookingsForAgency(int agencyId) async {
    try {
      final jobsRepo = AbstractJobsRepo.getInstance();
      final agencyJobs = await jobsRepo.getAllJobsForAgency(agencyId);
      final jobIds = agencyJobs.map((j) => j.id).whereType<int>().toList();

      if (jobIds.isEmpty) return [];

      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('job_id', whereIn: jobIds)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Booking.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getBookingsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Booking>> getBookingsForClient(int clientId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('client_id', isEqualTo: clientId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Booking.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getBookingsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Booking?> getBookingById(int bookingId) async {
    try {
      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(bookingId.toString())
          .get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = bookingId;
      return Booking.fromMap(data);
    } catch (e, stacktrace) {
      print('getBookingById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      DebugLogger.log(
        'createBooking',
        'START',
        data: {
          'jobId': booking.jobId,
          'clientId': booking.clientId,
          'providerId': booking.providerId,
          'status': booking.status.name,
        },
      );

      final bookingMap = booking.toMap();
      final id = bookingMap.remove('id');

      bookingMap['job_id'] = booking.jobId;
      bookingMap['client_id'] = booking.clientId;
      bookingMap['provider_id'] = booking.providerId;
      bookingMap['status'] = 'pending';
      bookingMap['created_at'] = FieldValue.serverTimestamp();
      bookingMap['updated_at'] = FieldValue.serverTimestamp();

      String docId;
      if (id != null && id is int) {
        docId = id.toString();
      } else {
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
        bookingMap['id'] = newId;
      }

      final sanitizedMap = Map<String, dynamic>.from(bookingMap);
      sanitizedMap.removeWhere((key, value) => value is FieldValue);
      DebugLogger.log(
        'createBooking',
        'WRITING',
        data: {'docId': docId, 'bookingMap': sanitizedMap},
      );

      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(bookingMap);

      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .get();

      final data = doc.data()!;
      data['id'] = int.parse(docId);
      final createdBooking = Booking.fromMap(data);

      final readData = doc.data()!;
      DebugLogger.log(
        'createBooking',
        'VERIFIED',
        data: {
          'docId': docId,
          'bookingId': createdBooking.id,
          'job_id': readData['job_id'],
          'job_id_type': readData['job_id']?.runtimeType.toString(),
          'client_id': readData['client_id'],
          'client_id_type': readData['client_id']?.runtimeType.toString(),
          'provider_id': readData['provider_id'],
          'provider_id_type': readData['provider_id']?.runtimeType.toString(),
          'status': readData['status'],
          'created_at_type': readData['created_at']?.runtimeType.toString(),
        },
      );

      if (booking.bidPrice != null) {
        try {
          final jobsRepo = AbstractJobsRepo.getInstance();
          final job = await jobsRepo.getJobById(booking.jobId);
          if (job != null) {
            final currentMin = job.budgetMin;
            final bidPrice = booking.bidPrice!;

            if (currentMin == null || bidPrice < currentMin) {
              await FirebaseConfig.firestore
                  .collection('jobs')
                  .doc(booking.jobId.toString())
                  .update({
                'budget_min': bidPrice,
                'updated_at': FieldValue.serverTimestamp(),
              });

              DebugLogger.log(
                'createBooking',
                'BUDGET_MIN_UPDATED',
                data: {
                  'jobId': booking.jobId,
                  'oldMin': currentMin,
                  'newMin': bidPrice,
                },
              );
            }
          }
        } catch (e) {
          DebugLogger.log(
            'createBooking',
            'BUDGET_UPDATE_ERROR',
            data: {'error': e.toString(), 'jobId': booking.jobId},
          );
        }
      }

      if (booking.providerId != null) {
        Future.microtask(() async {
          try {
            final jobsRepo = AbstractJobsRepo.getInstance();
            final job = await jobsRepo.getJobById(booking.jobId);
            if (job != null) {
              final profileRepo = AbstractProfileRepo.getInstance();
              final providerProfile = await profileRepo.getProfileById(
                booking.providerId!,
              );
              final providerName =
                  providerProfile?['full_name'] as String? ?? 'A worker';

              await NotificationServiceEnhanced.createNotification(
                userId: booking.clientId.toString(),
                title: 'New Application Received',
                body: '$providerName has applied to your job "${job.title}".',
                type: NotificationType.jobApplication,
                senderId: booking.providerId.toString(),
                jobId: booking.jobId,
                clientId: booking.clientId,
                workerId: booking.providerId,
                route: '/jobDetails',
                routeId: booking.jobId.toString(),
              );
            }
          } catch (e) {
            DebugLogger.log(
              'createBooking',
              'NOTIFICATION_ERROR',
              data: {'error': e.toString()},
            );
          }
        });
      }

      DebugLogger.log(
        'createBooking',
        'SUCCESS',
        data: {'docId': docId, 'bookingId': createdBooking.id},
      );
      return createdBooking;
    } catch (e, stacktrace) {
      DebugLogger.error('createBooking', 'ERROR', e, stacktrace);
      rethrow;
    }
  }

  @override
  Future<Booking> updateBooking(Booking booking) async {
    try {
      final bookingMap = booking.toMap();
      bookingMap.remove('id');
      bookingMap['updated_at'] = FieldValue.serverTimestamp();

      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(booking.id.toString())
          .update(bookingMap);

      return booking;
    } catch (e, stacktrace) {
      print('updateBooking error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getApplicationsForJob(int jobId) async {
    try {
      DebugLogger.log(
        'getApplicationsForJob',
        'START',
        data: {'jobId': jobId, 'jobIdType': jobId.runtimeType.toString()},
      );

      QuerySnapshot snapshot;
      bool usedFallback = false;
      try {
        snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('job_id', isEqualTo: jobId)
            .orderBy('created_at', descending: true)
            .get();

        DebugLogger.log(
          'getApplicationsForJob',
          'QUERY_SUCCESS',
          data: {
            'jobId': jobId,
            'resultCount': snapshot.docs.length,
            'usedFallback': false,
          },
        );
      } catch (e, stack) {
        final errorStr = e.toString();
        final isIndexError = errorStr.contains('FAILED_PRECONDITION') ||
            errorStr.contains('requires an index') ||
            errorStr.contains('index');

        if (isIndexError) {
          DebugLogger.log(
            'getApplicationsForJob',
            'INDEX_MISSING_FALLBACK',
            data: {'jobId': jobId, 'error': errorStr},
          );
          print(
            '[getApplicationsForJob] Index missing, using fallback query (no orderBy)',
          );

          try {
            snapshot = await FirebaseConfig.firestore
                .collection(collectionName)
                .where('job_id', isEqualTo: jobId)
                .get();

            usedFallback = true;
            DebugLogger.log(
              'getApplicationsForJob',
              'FALLBACK_SUCCESS',
              data: {'jobId': jobId, 'resultCount': snapshot.docs.length},
            );
          } catch (fallbackError, fallbackStack) {
            DebugLogger.error(
              'getApplicationsForJob',
              'FALLBACK_FAILED',
              fallbackError,
              fallbackStack,
              data: {'jobId': jobId},
            );
            rethrow;
          }
        } else {
          DebugLogger.error(
            'getApplicationsForJob',
            'QUERY_FAILED',
            e,
            stack,
            data: {
              'jobId': jobId,
              'errorCode': (e as dynamic).code?.toString(),
              'errorMessage': (e as dynamic).message?.toString(),
            },
          );
          rethrow;
        }
      }

      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          if (data['provider_id'] == null) {
            DebugLogger.log(
              'getApplicationsForJob',
              'FILTERED_NO_PROVIDER',
              data: {'docId': doc.id, 'jobId': jobId},
            );
            continue;
          }

          data['id'] = int.tryParse(doc.id) ?? 0;
          final booking = Booking.fromMap(data);
          bookings.add(booking);

          DebugLogger.log(
            'getApplicationsForJob',
            'BOOKING_PASSED',
            data: {
              'docId': doc.id,
              'bookingId': booking.id,
              'jobId': booking.jobId,
              'providerId': booking.providerId,
              'status': booking.status.name,
            },
          );
        } catch (e, stack) {
          DebugLogger.error(
            'getApplicationsForJob',
            'PARSE_ERROR',
            e,
            stack,
            data: {'docId': doc.id},
          );
          continue;
        }
      }

      if (usedFallback) {
        bookings.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          return bTime.compareTo(aTime);
        });
        DebugLogger.log(
          'getApplicationsForJob',
          'CLIENT_SIDE_SORT',
          data: {'jobId': jobId, 'sortedCount': bookings.length},
        );
      }

      DebugLogger.log(
        'getApplicationsForJob',
        'SUCCESS',
        data: {
          'jobId': jobId,
          'resultCount': bookings.length,
          'usedFallback': usedFallback,
        },
      );
      return bookings;
    } catch (e, stacktrace) {
      DebugLogger.error(
        'getApplicationsForJob',
        'ERROR',
        e,
        stacktrace,
        data: {'jobId': jobId},
      );
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getAcceptedJobsForCleaner(int cleanerId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('provider_id', isEqualTo: cleanerId)
          .where('status', isEqualTo: BookingStatus.inProgress.name)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Booking.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getAcceptedJobsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<void> acceptApplication(int bookingId) async {
    try {
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final bookingRef = FirebaseConfig.firestore
            .collection(collectionName)
            .doc(bookingId.toString());
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final bookingData = bookingDoc.data()!;

        final jobIdRaw = bookingData['job_id'];
        final clientIdRaw = bookingData['client_id'];
        final providerIdRaw = bookingData['provider_id'];
        final statusBefore = bookingData['status']?.toString();

        DebugLogger.log(
          'acceptApplication',
          'TX_READ_BOOKING',
          data: {
            'bookingId': bookingId,
            'job_id': jobIdRaw,
            'job_id_type': jobIdRaw?.runtimeType.toString() ?? 'null',
            'client_id': clientIdRaw,
            'client_id_type': clientIdRaw?.runtimeType.toString() ?? 'null',
            'provider_id': providerIdRaw,
            'provider_id_type': providerIdRaw?.runtimeType.toString() ?? 'null',
            'statusBefore': statusBefore,
          },
        );

        final jobId = (jobIdRaw is int)
            ? jobIdRaw
            : (jobIdRaw is String ? int.tryParse(jobIdRaw) : null);
        if (jobId == null) {
          throw Exception(
            'Invalid job_id in booking: $jobIdRaw (type: ${jobIdRaw.runtimeType})',
          );
        }

        final providerId = (providerIdRaw is int)
            ? providerIdRaw
            : (providerIdRaw is String ? int.tryParse(providerIdRaw) : null);
        if (providerId == null) {
          throw Exception(
            'Booking has no provider_id: $providerIdRaw (type: ${providerIdRaw.runtimeType})',
          );
        }

        final jobRef =
            FirebaseConfig.firestore.collection('jobs').doc(jobId.toString());
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) {
          throw Exception('Job not found: $jobId');
        }

        final jobData = jobDoc.data()!;

        DebugLogger.log(
          'acceptApplication',
          'TX_READ_JOB_BEFORE',
          data: {
            'jobId': jobId,
            'status': jobData['status']?.toString(),
            'assigned_worker_id': jobData['assigned_worker_id'],
            'assigned_worker_id_type':
                jobData['assigned_worker_id']?.runtimeType.toString() ?? 'null',
            'client_id': jobData['client_id'],
            'client_id_type':
                jobData['client_id']?.runtimeType.toString() ?? 'null',
            'is_deleted': jobData['is_deleted'],
            'is_deleted_type':
                jobData['is_deleted']?.runtimeType.toString() ?? 'null',
            'worker_done': jobData['worker_done'],
            'worker_done_type':
                jobData['worker_done']?.runtimeType.toString() ?? 'null',
            'client_done': jobData['client_done'],
            'client_done_type':
                jobData['client_done']?.runtimeType.toString() ?? 'null',
          },
        );

        if (jobData['assigned_worker_id'] != null) {
          throw Exception('Job is already assigned to another worker');
        }

        transaction.update(bookingRef, {
          'status': BookingStatus.inProgress.name,
          'updated_at': FieldValue.serverTimestamp(),
        });

        final jobUpdates = {
          'status': JobStatus.assigned.name,
          'assigned_worker_id': providerId,
          'updated_at': FieldValue.serverTimestamp(),
        };

        DebugLogger.log(
          'acceptApplication',
          'TX_WRITE_JOB',
          data: {
            'jobId': jobId,
            'updates': {
              'status': jobUpdates['status'],
              'assigned_worker_id': jobUpdates['assigned_worker_id'],
              'assigned_worker_id_type': providerId.runtimeType.toString(),
            },
          },
        );

        transaction.update(jobRef, jobUpdates);

        final otherApplicationsSnapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('job_id', isEqualTo: jobId)
            .where('status', isEqualTo: BookingStatus.pending.name)
            .get();

        for (final doc in otherApplicationsSnapshot.docs) {
          if (doc.id != bookingId.toString()) {
            transaction.update(doc.reference, {
              'status': BookingStatus.cancelled.name,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      final jobsRepo = AbstractJobsRepo.getInstance();
      final bookingAfter = await getBookingById(bookingId);
      if (bookingAfter != null) {
        final jobAfter = await jobsRepo.getJobById(bookingAfter.jobId);
        if (jobAfter != null) {
          final jobDocAfter = await FirebaseConfig.firestore
              .collection('jobs')
              .doc(bookingAfter.jobId.toString())
              .get();
          final jobDataAfter = jobDocAfter.data();

          DebugLogger.log(
            'acceptApplication',
            'TX_READ_JOB_AFTER',
            data: {
              'jobId': bookingAfter.jobId,
              'status': jobDataAfter?['status']?.toString(),
              'assigned_worker_id': jobDataAfter?['assigned_worker_id'],
              'assigned_worker_id_type':
                  jobDataAfter?['assigned_worker_id']?.runtimeType.toString() ??
                      'null',
              'client_id': jobDataAfter?['client_id'],
              'client_id_type':
                  jobDataAfter?['client_id']?.runtimeType.toString() ?? 'null',
              'is_deleted': jobDataAfter?['is_deleted'],
              'is_deleted_type':
                  jobDataAfter?['is_deleted']?.runtimeType.toString() ?? 'null',
              'worker_done': jobDataAfter?['worker_done'],
              'worker_done_type':
                  jobDataAfter?['worker_done']?.runtimeType.toString() ??
                      'null',
              'client_done': jobDataAfter?['client_done'],
              'client_done_type':
                  jobDataAfter?['client_done']?.runtimeType.toString() ??
                      'null',
            },
          );
        }
      }

      final booking = bookingAfter ?? await getBookingById(bookingId);
      if (booking != null && booking.providerId != null) {
        final job = await jobsRepo.getJobById(booking.jobId);

        if (job != null) {
          DebugLogger.log(
            'acceptApplication',
            'POST_TX_VERIFY',
            data: {
              'jobId': booking.jobId,
              'assignedWorkerId': job.assignedWorkerId,
              'assignedWorkerIdType':
                  job.assignedWorkerId?.runtimeType.toString() ?? 'null',
              'providerId': booking.providerId,
              'providerIdType': booking.providerId.runtimeType.toString(),
              'status': job.status.name,
            },
          );
        }

        if (job != null) {
          try {
            final profileRepo = AbstractProfileRepo.getInstance();
            final providerProfile = await profileRepo.getProfileById(
              booking.providerId!,
            );
            final providerName =
                providerProfile?['full_name'] as String? ?? 'A worker';

            await NotificationServiceEnhanced.createNotification(
              userId: booking.providerId.toString(),
              title: 'Application Accepted!',
              body:
                  'Congratulations! Your application for "${job.title}" has been accepted.',
              type: NotificationType.jobAssigned,
              senderId: booking.clientId.toString(),
              jobId: booking.jobId,
              clientId: booking.clientId,
              workerId: booking.providerId,
              route: '/jobDetails',
              routeId: booking.jobId.toString(),
            );

            await NotificationServiceEnhanced.createNotification(
              userId: booking.clientId.toString(),
              title: 'Worker Assigned',
              body:
                  '$providerName has been assigned to your job "${job.title}".',
              type: NotificationType.jobAssigned,
              senderId: booking.providerId.toString(),
              jobId: booking.jobId,
              clientId: booking.clientId,
              workerId: booking.providerId,
              route: '/jobDetails',
              routeId: booking.jobId.toString(),
            );
          } catch (e) {
            print('Error sending acceptance notifications: $e');
          }
        }
      }
    } catch (e, stacktrace) {
      print('acceptApplication error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> rejectApplication(int bookingId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(bookingId.toString())
          .update({
        'status': BookingStatus.cancelled.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final booking = await getBookingById(bookingId);
      if (booking != null && booking.providerId != null) {
        Future.microtask(() async {
          try {
            final jobsRepo = AbstractJobsRepo.getInstance();
            final job = await jobsRepo.getJobById(booking.jobId);
            if (job != null) {
              await NotificationBackendService.sendToUser(
                userId: booking.providerId.toString(),
                title: 'Application Status',
                body: 'Your application for "${job.title}" was not selected.',
                route: '/jobDetails',
                id: booking.jobId.toString(),
              );
            }
          } catch (e) {
            print('Error sending rejection notification: $e');
          }
        });
      }
    } catch (e, stacktrace) {
      print('rejectApplication error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> withdrawApplication(int bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      if (booking.status != BookingStatus.pending) {
        throw Exception(
          'Cannot withdraw application - status is ${booking.status.name}',
        );
      }

      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(bookingId.toString())
          .update({
        'status': BookingStatus.cancelled.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      Future.microtask(() async {
        try {
          final jobsRepo = AbstractJobsRepo.getInstance();
          final job = await jobsRepo.getJobById(booking.jobId);
          if (job != null) {
            await NotificationBackendService.sendToUser(
              userId: booking.clientId.toString(),
              title: 'Application Withdrawn',
              body:
                  'A worker has withdrawn their application for "${job.title}".',
              route: '/jobDetails',
              id: booking.jobId.toString(),
            );
          }
        } catch (e) {
          print('Error sending withdrawal notification: $e');
        }
      });
    } catch (e, stacktrace) {
      print('withdrawApplication error: $e --> $stacktrace');
      rethrow;
    }
  }
}
