import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/services/notification_backend_service.dart';
import '../../../core/services/notification_service_enhanced.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../core/utils/firestore_type.dart';
import '../../models/job_model.dart';
import '../../models/notification_item.dart';
import '../../models/booking_model.dart';
import '../bookings/bookings_repo.dart';
import '../bookings/bookings_repo.dart';
import 'jobs_repo.dart';

class JobsDB extends AbstractJobsRepo {
  static const String collectionName = 'jobs';
  static const String _logPath = 'c:\\Users\\wailo\\Desktop\\mob_dev_project\\.cursor\\debug.log';

  void _agentLog(String hypothesisId, String message, Map<String, dynamic> data) {
    // #region agent log
    try {
      final logFile = File(_logPath);
      logFile.parent.createSync(recursive: true);
      final logLine = jsonEncode({
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': hypothesisId,
        'location': 'jobs_repo_db.dart',
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      logFile.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (e) {
      // fallback to console so we still get runtime evidence
      print('agentLog jobs_repo_db.dart [$hypothesisId] $message $data (log write failed: $e)');
    }
    // #endregion
  }

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $collectionName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      city TEXT NOT NULL,
      country TEXT NOT NULL,
      description TEXT NOT NULL,
      status TEXT NOT NULL,
      posted_date TEXT NOT NULL,
      job_date TEXT NOT NULL,
      cover_image_url TEXT,
      client_id INTEGER,
      agency_id INTEGER,
      budget_min REAL,
      budget_max REAL,
      estimated_hours INTEGER,
      required_services TEXT,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (client_id) REFERENCES profiles(id),
      FOREIGN KEY (agency_id) REFERENCES profiles(id),
      CHECK (client_id IS NOT NULL OR agency_id IS NOT NULL)
    )
  ''';

  @override
  Future<List<Job>> getActiveJobsForAgency(int agencyId) async {
    try {
      // Fetch without orderBy to avoid composite index; filter client-side
      final jobsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('client_id', isNull: true)
          .get();

      // Also get jobs where agency has bookings (in progress OR pending)
      final bookingsSnapshot = await FirebaseConfig.firestore
          .collection('bookings')
          .where('provider_id', isEqualTo: agencyId)
          .where('status', whereIn: [BookingStatus.inProgress.name, BookingStatus.pending.name])
          .get();

      final bookingJobIds = bookingsSnapshot.docs
          .map((doc) => doc.data()['job_id'] as int? ?? 0)
          .where((id) => id > 0)
          .toSet();

      final allJobs = <Job>[];
      
      // Add agency-owned jobs
      for (final doc in jobsSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = int.tryParse(doc.id) ?? 0;
          final job = Job.fromMap(data);
          if (!job.isDeleted &&
              (job.status == JobStatus.active || job.status == JobStatus.inProgress)) {
            allJobs.add(job);
          }
        } catch (e) {
          print('Error parsing job: $e');
        }
      }

      // Add jobs with bookings
      if (bookingJobIds.isNotEmpty) {
        final bookedJobsSnapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where(FieldPath.documentId, whereIn: bookingJobIds.map((id) => id.toString()).toList())
            .get();

        for (final doc in bookedJobsSnapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = int.tryParse(doc.id) ?? 0;
            final job = Job.fromMap(data);
            // Include jobs with pending/inProgress bookings regardless of job status
            // (they should show in Active Listings as "Pending")
            // BUT exclude jobs where both client_done and worker_done are true (completed)
            if (!job.isDeleted && 
                !(job.clientDone && job.workerDone) &&
                !allJobs.any((j) => j.id == job.id)) {
              allJobs.add(job);
            }
          } catch (e) {
            print('Error parsing booked job: $e');
          }
        }
      }

      // Sort by most recent first:
      // 1. Use updated_at if available (most recent activity)
      // 2. Otherwise use postedDate (when job was posted)
      allJobs.sort((a, b) {
        // Compare by updated_at first (if both have it)
        if (a.updatedAt != null && b.updatedAt != null) {
          final updatedCmp = b.updatedAt!.compareTo(a.updatedAt!);
          if (updatedCmp != 0) return updatedCmp;
        } else if (a.updatedAt != null) {
          return -1; // a has updatedAt, b doesn't - a comes first
        } else if (b.updatedAt != null) {
          return 1; // b has updatedAt, a doesn't - b comes first
        }
        // Fall back to postedDate (most recent first)
        return b.postedDate.compareTo(a.postedDate);
      });
      return allJobs;
    } catch (e, stacktrace) {
      print('getActiveJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getPastJobsForAgency(int agencyId) async {
    try {
      // Get agency-owned jobs
      final agencyJobsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('client_id', isNull: true)
          .get();
      
      // Also get jobs where worker was assigned and both parties confirmed completion
      final assignedJobsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('assigned_worker_id', isEqualTo: agencyId)
          .get();
      
      final allJobs = <Job>[];
      
      // Add agency-owned completed/cancelled jobs
      for (final doc in agencyJobsSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = int.tryParse(doc.id) ?? 0;
          final job = Job.fromMap(data);
          if (!job.isDeleted && 
              (job.status == JobStatus.completed || job.status == JobStatus.cancelled)) {
            allJobs.add(job);
          }
        } catch (e) {
          print('Error parsing agency job: $e');
        }
      }
      
      // Add assigned jobs where both client_done and worker_done are true
      for (final doc in assignedJobsSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = int.tryParse(doc.id) ?? 0;
          final job = Job.fromMap(data);
          // Include if both parties confirmed completion (client_done && worker_done)
          if (!job.isDeleted && 
              job.clientDone && 
              job.workerDone &&
              !allJobs.any((j) => j.id == job.id)) {
            allJobs.add(job);
          }
        } catch (e) {
          print('Error parsing assigned job: $e');
        }
      }
      
      // Sort by most recent first
      allJobs.sort((a, b) {
        if (a.updatedAt != null && b.updatedAt != null) {
          final updatedCmp = b.updatedAt!.compareTo(a.updatedAt!);
          if (updatedCmp != 0) return updatedCmp;
        } else if (a.updatedAt != null) {
          return -1;
        } else if (b.updatedAt != null) {
          return 1;
        }
        return b.postedDate.compareTo(a.postedDate);
      });
      
      return allJobs;
    } catch (e, stacktrace) {
      print('getPastJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getAllJobsForAgency(int agencyId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('client_id', isNull: true)
          .get();
      
      final jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Job.fromMap(data);
      }).where((job) => !job.isDeleted).toList();
      
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      return jobs;
    } catch (e, stacktrace) {
      print('getAllJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Job?> getJobById(int jobId) async {
    try {
      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(jobId.toString())
          .get();
      
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['is_deleted'] == true) return null;
      
      data['id'] = jobId;
      return Job.fromMap(data);
    } catch (e, stacktrace) {
      print('getJobById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Job> createJob(Job job) async {
    try {
      // Validate required fields
      if (job.clientId == null) {
        throw Exception('Client ID is required to create a job. Please ensure you are logged in.');
      }
      
      final now = DateTime.now();
      // Ensure new jobs start with 'open' status (visible to workers)
      // Convert 'active' to 'open' for consistency
      final jobWithStatus = (job.status == JobStatus.active || job.status == JobStatus.open)
          ? job.copyWith(status: JobStatus.open, createdAt: now, updatedAt: now)
          : job.copyWith(createdAt: now, updatedAt: now);
      
      DebugLogger.log('createJob', 'START', data: {
        'clientId': job.clientId,
        'agencyId': job.agencyId,
        'status': job.status.name,
        'title': job.title,
      });
      
      final jobMap = jobWithStatus.toMap();
      
      final id = jobMap.remove('id');
      // Normalize ownership/assignment fields to explicit nulls
      jobMap['agency_id'] = jobWithStatus.agencyId ?? null;
      jobMap['client_id'] = jobWithStatus.clientId; // This should not be null after validation
      jobMap['assigned_worker_id'] = jobWithStatus.assignedWorkerId ?? null;
      jobMap['is_deleted'] = false; // BOOL
      jobMap['status'] = 'open'; // Ensure status is 'open'
      // Ensure job_images field is always present (empty array if null)
      jobMap['job_images'] = jobWithStatus.jobImages ?? <String>[];
      jobMap['posted_date'] = FieldValue.serverTimestamp(); // Use serverTimestamp for consistency
      jobMap['created_at'] = Timestamp.fromDate(now);
      jobMap['updated_at'] = Timestamp.fromDate(now);
      
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
        jobMap['id'] = newId;
      }
      
      DebugLogger.log('createJob', 'WRITING', data: {
        'docId': docId,
        'jobMap': jobMap,
      });
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(jobMap);
      
      // Verify write - read back to check field types
      final createdSnap = await FirebaseConfig.firestore.collection(collectionName).doc(docId).get();
      if (createdSnap.exists) {
        final readData = createdSnap.data()!;
        DebugLogger.log('createJob', 'VERIFIED', data: {
          'docId': docId,
          'client_id': readData['client_id'],
          'client_id_type': readData['client_id']?.runtimeType.toString(),
          'status': readData['status'],
          'is_deleted': readData['is_deleted'],
          'is_deleted_type': readData['is_deleted']?.runtimeType.toString(),
          'assigned_worker_id': readData['assigned_worker_id'],
          'assigned_worker_id_exists': readData.containsKey('assigned_worker_id'),
          'posted_date_type': readData['posted_date']?.runtimeType.toString(),
          'agency_id': readData['agency_id'],
          'agency_id_type': readData['agency_id']?.runtimeType.toString(),
        });
      } else {
        DebugLogger.log('createJob', 'VERIFY_FAILED', data: {'docId': docId});
      }
      
      final createdJob = job.copyWith(id: int.parse(docId), createdAt: now, updatedAt: now);
      
      // Send notification to workers/agencies when client creates a job
      if (job.clientId != null) {
        // Client created a job - notify workers/agencies (async, don't block)
        Future.microtask(() async {
          try {
            // Get all agencies/workers (user_type: 'Agency' or 'Individual Cleaner')
            final profilesSnapshot = await FirebaseConfig.firestore
                .collection('profiles')
                .where('user_type', whereIn: ['Agency', 'Individual Cleaner'])
                .get();
            
            // Send to each worker individually
            for (final profileDoc in profilesSnapshot.docs) {
              final userId = profileDoc.id;
              try {
                await NotificationBackendService.sendToUser(
                  userId: userId,
                  title: 'New Job Available',
                  body: '${job.title} in ${job.city}, ${job.country}',
                  route: '/jobDetails',
                  id: createdJob.id.toString(),
                );
              } catch (e) {
                DebugLogger.log('createJob', 'NOTIFICATION_ERROR', data: {'userId': userId, 'error': e.toString()});
              }
            }
          } catch (e) {
            DebugLogger.log('createJob', 'NOTIFICATION_BATCH_ERROR', data: {'error': e.toString()});
          }
        });
      }
      
      DebugLogger.log('createJob', 'SUCCESS', data: {'docId': docId, 'jobId': createdJob.id});
      return createdJob;
    } catch (e, stacktrace) {
      DebugLogger.error('createJob', 'ERROR', e, stacktrace);
      rethrow;
    }
  }

  @override
  Future<Job> updateJob(Job job) async {
    try {
      final now = DateTime.now();
      final jobMap = job.copyWith(updatedAt: now).toMap();
      jobMap.remove('id');
      // Ensure job_images field is always present (empty array if null)
      jobMap['job_images'] = job.jobImages ?? <String>[];
      jobMap['updated_at'] = Timestamp.fromDate(now);
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(job.id.toString())
          .update(jobMap);
      
      return job.copyWith(updatedAt: now);
    } catch (e, stacktrace) {
      print('updateJob error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteJob(int jobId) async {
    try {
      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(jobId.toString());
      
      DebugLogger.log('deleteJob', 'START', data: {
        'jobId': jobId,
        'docPath': docRef.path,
      });
      
      // Use transaction to ensure atomicity and prevent race conditions
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        // Get the document
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          throw Exception('Job with ID $jobId does not exist in Firestore');
        }
        
        final beforeData = doc.data()!;
        DebugLogger.log('deleteJob', 'BEFORE_UPDATE', data: {
          'jobId': jobId,
          'is_deleted_before': beforeData['is_deleted'],
          'is_deleted_type': beforeData['is_deleted']?.runtimeType.toString(),
        });
        
        // Update the document with is_deleted flag within transaction
        transaction.update(docRef, {
          'is_deleted': true,  // Explicit bool
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        DebugLogger.log('deleteJob', 'TRANSACTION_UPDATE', data: {'jobId': jobId});
      });
      
      // Wait a bit for transaction to complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify the update was successful - use GetOptions to read from server
      final updatedDoc = await docRef.get(const GetOptions(source: Source.server));
      if (updatedDoc.exists) {
        final data = updatedDoc.data()!;
        final isDeleted = data['is_deleted'];
        
        DebugLogger.log('deleteJob', 'VERIFICATION', data: {
          'jobId': jobId,
          'is_deleted_after': isDeleted,
          'is_deleted_type': isDeleted?.runtimeType.toString(),
          'is_deleted_true': isDeleted == true,
        });
        
        // Check if is_deleted is actually true (handle both bool and int types)
        if (isDeleted != true && isDeleted != 1) {
          final error = Exception('Failed to mark job as deleted - is_deleted is $isDeleted (type: ${isDeleted.runtimeType})');
          DebugLogger.error('deleteJob', 'VERIFICATION_FAILED', error, StackTrace.current, data: {
            'jobId': jobId,
            'is_deleted_value': isDeleted,
            'is_deleted_type': isDeleted.runtimeType.toString(),
          });
          throw error;
        }
      } else {
        throw Exception('Job document disappeared after update');
      }
      
      // Send notifications after deletion
      try {
        final job = await getJobById(jobId);
        if (job != null) {
          // Notify client
          if (job.clientId != null) {
            await NotificationServiceEnhanced.createNotification(
              userId: job.clientId.toString(),
              title: 'Job Deleted',
              body: 'Your job "${job.title}" has been deleted.',
              type: NotificationType.jobDeleted,
              jobId: jobId,
              clientId: job.clientId,
              route: '/myPosts',
            );
          }
          
          // Notify assigned worker/agency if job was assigned
          if (job.assignedWorkerId != null) {
            await NotificationServiceEnhanced.createNotification(
              userId: job.assignedWorkerId.toString(),
              title: 'Job Deleted',
              body: 'The job "${job.title}" you were assigned to has been deleted by the client.',
              type: NotificationType.jobDeleted,
              senderId: job.clientId?.toString(),
              jobId: jobId,
              clientId: job.clientId,
              workerId: job.assignedWorkerId,
              route: '/availableJobs',
            );
          }
          
          // Also notify all applicants (bookings with pending status)
          try {
            final bookingsRepo = AbstractBookingsRepo.getInstance();
            final applications = await bookingsRepo.getApplicationsForJob(jobId);
            for (final application in applications) {
              if (application.status == BookingStatus.pending && application.providerId != null) {
                await NotificationServiceEnhanced.createNotification(
                  userId: application.providerId.toString(),
                  title: 'Job Deleted',
                  body: 'The job "${job.title}" you applied to has been deleted by the client.',
                  type: NotificationType.jobDeleted,
                  senderId: job.clientId?.toString(),
                  jobId: jobId,
                  clientId: job.clientId,
                  workerId: application.providerId,
                  route: '/availableJobs',
                );
              }
            }
          } catch (e) {
            print('Error notifying applicants about job deletion: $e');
          }
        }
      } catch (e) {
        print('Error sending deletion notifications: $e');
        // Don't fail the deletion if notification fails
      }
      
      DebugLogger.log('deleteJob', 'SUCCESS', data: {'jobId': jobId});
    } catch (e, stacktrace) {
      DebugLogger.error('deleteJob', 'ERROR', e, stacktrace, data: {'jobId': jobId});
      print('❌ deleteJob error: $e');
      print('❌ Stack trace: $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> changeJobStatus(int jobId, JobStatus status) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(jobId.toString())
          .update({
            'status': status.name,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e, stacktrace) {
      print('changeJobStatus error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<int> getTotalJobsCompletedForAgency(int agencyId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('status', isEqualTo: JobStatus.completed.name)
          .where('is_deleted', isEqualTo: false)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e, stacktrace) {
      print('getTotalJobsCompletedForAgency error: $e --> $stacktrace');
      return 0;
    }
  }

  Future<void> _addJobToHistory(Job job) async {
    try {
      final jobId = job.id;
      if (jobId == null) return;

      final historyRef = FirebaseConfig.firestore.collection('job_history');
      final batch = FirebaseConfig.firestore.batch();
      final completedAt = FieldValue.serverTimestamp();

      if (job.assignedWorkerId != null) {
        batch.set(historyRef.doc(), {
          'job_id': jobId,
          'participant_user_id': job.assignedWorkerId,
          'role': 'worker',
          'completed_at': completedAt,
          'title': job.title,
          'other_party_id': job.clientId,
        });
      }

      if (job.clientId != null) {
        batch.set(historyRef.doc(), {
          'job_id': jobId,
          'participant_user_id': job.clientId,
          'role': 'client',
          'completed_at': completedAt,
          'title': job.title,
          'other_party_id': job.assignedWorkerId,
        });
      }

      if (job.agencyId != null) {
        batch.set(historyRef.doc(), {
          'job_id': jobId,
          'participant_user_id': job.agencyId,
          'role': 'agency',
          'completed_at': completedAt,
          'title': job.title,
          'other_party_id': job.clientId ?? job.assignedWorkerId,
        });
      }

      await batch.commit();
    } catch (e) {
      print('addJobToHistory error: $e');
    }
  }

  @override
  Future<Job> markClientDone(int jobId) async {
    try {
      DebugLogger.log('markClientDone', 'TX_START', data: {'jobId': jobId});
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final jobRef = FirebaseConfig.firestore
            .collection(collectionName)
            .doc(jobId.toString());
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }
        
        final jobData = jobDoc.data()!;
        final workerDoneBefore = readBool(jobData['worker_done']);
        final clientDoneBefore = readBool(jobData['client_done']);
        final statusBefore = jobData['status']?.toString();
        DebugLogger.log('markClientDone', 'TX_READ', data: {
          'jobId': jobId,
          'worker_done_before': workerDoneBefore,
          'client_done_before': clientDoneBefore,
          'status_before': statusBefore,
        });
        
        // Update client_done flag (as bool) and recompute status atomically
        final updates = <String, dynamic>{
          'client_done': true,
          'updated_at': FieldValue.serverTimestamp(),
        };
        if (workerDoneBefore) {
          updates['status'] = JobStatus.completed.name;
          updates['completed_at'] = FieldValue.serverTimestamp();
        } else {
          updates['status'] = JobStatus.completedPendingConfirmation.name;
        }
        transaction.update(jobRef, updates);
        DebugLogger.log('markClientDone', 'TX_WRITE', data: {
          'jobId': jobId,
          'status_after': updates['status'],
        });
      });
      
      // Read back updated job AFTER transaction
      final job = await getJobById(jobId);
      DebugLogger.log('markClientDone', 'POST_TX_READ', data: {
        'jobId': jobId,
        'status': job?.status.name,
        'client_done': job?.clientDone,
        'worker_done': job?.workerDone,
      });
      if (job != null) {
        try {
          if (job.workerDone) {
            // Both confirmed - add to history and notify both parties
            await _addJobToHistory(job);
            
            if (job.clientId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.clientId.toString(),
                title: 'Job Completed!',
                body: 'Job "${job.title}" has been completed. You can now leave a review.',
                type: NotificationType.jobCompleted,
                senderId: job.assignedWorkerId?.toString(),
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
            if (job.assignedWorkerId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.assignedWorkerId.toString(),
                title: 'Job Completed!',
                body: 'Job "${job.title}" has been completed. You can now leave a review.',
                type: NotificationType.jobCompleted,
                senderId: job.clientId?.toString(),
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
          } else {
            // Only client confirmed - notify worker
            if (job.assignedWorkerId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.assignedWorkerId.toString(),
                title: 'Client Confirmed Completion',
                body: 'The client has confirmed completion of "${job.title}". Please confirm as well.',
                type: NotificationType.jobCompleted,
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
          }
        } catch (e) {
          print('Error sending completion notifications: $e');
        }
      }
      if (job == null) {
        throw Exception('Job not found after completion');
      }
      return job;
    } catch (e, stacktrace) {
      DebugLogger.error('markClientDone', 'ERROR', e, stacktrace, data: {'jobId': jobId});
      rethrow;
    }
  }

  @override
  Future<Job> markWorkerDone(int jobId) async {
    try {
      DebugLogger.log('markWorkerDone', 'TX_START', data: {'jobId': jobId});
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final jobRef = FirebaseConfig.firestore
            .collection(collectionName)
            .doc(jobId.toString());
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }
        
        final jobData = jobDoc.data()!;
        final clientDoneBefore = readBool(jobData['client_done']);
        final workerDoneBefore = readBool(jobData['worker_done']);
        final statusBefore = jobData['status']?.toString();
        DebugLogger.log('markWorkerDone', 'TX_READ', data: {
          'jobId': jobId,
          'client_done_before': clientDoneBefore,
          'worker_done_before': workerDoneBefore,
          'status_before': statusBefore,
        });
        
        // Update worker_done flag (as bool) and recompute status atomically
        final updates = <String, dynamic>{
          'worker_done': true,
          'updated_at': FieldValue.serverTimestamp(),
        };
        if (clientDoneBefore) {
          updates['status'] = JobStatus.completed.name;
          updates['completed_at'] = FieldValue.serverTimestamp();
        } else {
          updates['status'] = JobStatus.completedPendingConfirmation.name;
        }
        transaction.update(jobRef, updates);
        DebugLogger.log('markWorkerDone', 'TX_WRITE', data: {
          'jobId': jobId,
          'status_after': updates['status'],
        });
      });
      
      // Read back updated job AFTER transaction
      final job = await getJobById(jobId);
      DebugLogger.log('markWorkerDone', 'POST_TX_READ', data: {
        'jobId': jobId,
        'status': job?.status.name,
        'client_done': job?.clientDone,
        'worker_done': job?.workerDone,
      });
      if (job != null) {
        try {
          if (job.clientDone) {
            // Both confirmed - add to history and notify both parties
            await _addJobToHistory(job);
            
            if (job.clientId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.clientId.toString(),
                title: 'Job Completed!',
                body: 'Job "${job.title}" has been completed. You can now leave a review.',
                type: NotificationType.jobCompleted,
                senderId: job.assignedWorkerId?.toString(),
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
            if (job.assignedWorkerId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.assignedWorkerId.toString(),
                title: 'Job Completed!',
                body: 'Job "${job.title}" has been completed. You can now leave a review.',
                type: NotificationType.jobCompleted,
                senderId: job.clientId?.toString(),
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
          } else {
            // Only worker confirmed - notify client with job_marked_done
            if (job.clientId != null) {
              await NotificationServiceEnhanced.createNotification(
                userId: job.clientId.toString(),
                title: 'Worker Marked Job Finished',
                body: 'The worker has marked "${job.title}" as finished. Please confirm completion.',
                type: NotificationType.jobMarkedDone,
                senderId: job.assignedWorkerId?.toString(),
                jobId: jobId,
                clientId: job.clientId,
                workerId: job.assignedWorkerId,
                agencyId: job.agencyId,
                route: '/jobDetails',
                routeId: jobId.toString(),
              );
            }
          }
        } catch (e) {
          print('Error sending completion notifications: $e');
        }
      }
      if (job == null) {
        throw Exception('Job not found after completion');
      }
      return job;
    } catch (e, stacktrace) {
      DebugLogger.error('markWorkerDone', 'ERROR', e, stacktrace, data: {'jobId': jobId});
      rethrow;
    }
  }

  @override
  Future<List<Job>> getAvailableJobsForAgency(int agencyId) async {
    try {
      DebugLogger.log('getAvailableJobsForAgency', 'START', data: {'agencyId': agencyId});
      
      // Get jobs this agency/worker has already applied to
      final appliedJobIdsSnapshot = await FirebaseConfig.firestore
          .collection('bookings')
          .where('provider_id', isEqualTo: agencyId)
          .get();
      
      final appliedJobIds = appliedJobIdsSnapshot.docs
          .map((doc) {
            final jobId = doc.data()['job_id'];
            if (jobId is int) return jobId;
            if (jobId is String) return int.tryParse(jobId) ?? 0;
            return 0;
          })
          .where((id) => id > 0)
          .toSet();
      
      DebugLogger.log('getAvailableJobsForAgency', 'APPLIED_JOBS', data: {
        'agencyId': agencyId,
        'appliedJobIds': appliedJobIds.toList(),
      });
      
      // Get jobs that are:
      // - Status open/pending (available for application)
      // - Not deleted (is_deleted == false)
      // - Not assigned (assigned_worker_id == null)
      // NOTE: Do NOT filter by agency_id - we want client-created jobs (agency_id is null)
      QuerySnapshot snapshot;
      try {
        // Baseline query: status in ['open','pending'], is_deleted == false, assigned_worker_id == null
        snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('status', whereIn: ['open', 'pending'])
            .where('is_deleted', isEqualTo: false)
            .where('assigned_worker_id', isNull: true)
            .get();
        
        DebugLogger.log('getAvailableJobsForAgency', 'QUERY_SUCCESS', data: {
          'agencyId': agencyId,
          'resultCount': snapshot.docs.length,
          'filters': "status in ['open','pending'], is_deleted == false, assigned_worker_id == null",
        });
      } catch (e, stack) {
        DebugLogger.error('getAvailableJobsForAgency', 'QUERY_FAILED', e, stack, data: {
          'agencyId': agencyId,
          'error': e.toString(),
        });
        
        // If index is missing, provide helpful error message
        if (e.toString().contains('FAILED_PRECONDITION') || e.toString().contains('index')) {
          print('❌ [getAvailableJobsForAgency] INDEX REQUIRED: Collection=jobs, Fields=status (Ascending), is_deleted (Ascending), assigned_worker_id (Ascending)');
          print('❌ [getAvailableJobsForAgency] Create index in Firebase Console or click the link in the error message');
        }
        
        // Fallback: get all jobs, filter client-side (less efficient but works)
        DebugLogger.log('getAvailableJobsForAgency', 'QUERY_FALLBACK', data: {
          'agencyId': agencyId,
          'error': e.toString(),
        });
        snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .get();
      }
      
      final jobs = <Job>[];
      final filterReasons = <String, int>{};
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final docId = int.tryParse(doc.id) ?? 0;
          
          final status = data['status'] as String? ?? '';
          final clientId = data['client_id'];
          final assignedWorkerId = data['assigned_worker_id'];
          final isDeletedRaw = data['is_deleted'];
          final isDeleted = (isDeletedRaw is bool && isDeletedRaw) || (isDeletedRaw is int && isDeletedRaw == 1);
          
          String? filterReason;
          if (clientId == null) {
            filterReason = 'client_id_is_null';
          } else if (assignedWorkerId != null) {
            filterReason = 'already_assigned';
          } else if (status != JobStatus.open.name && status != JobStatus.pending.name && status != JobStatus.active.name) {
            filterReason = 'wrong_status_$status';
          } else if (isDeleted) {
            filterReason = 'is_deleted';
          } else if (appliedJobIds.contains(docId)) {
            filterReason = 'already_applied';
          }
          
          if (filterReason != null) {
            filterReasons[filterReason] = (filterReasons[filterReason] ?? 0) + 1;
            DebugLogger.log('getAvailableJobsForAgency', 'FILTERED', data: {
              'docId': docId,
              'reason': filterReason,
              'clientId': clientId,
              'assignedWorkerId': assignedWorkerId,
              'status': status,
              'isDeleted': isDeleted,
            });
            continue;
          }
          
          data['id'] = docId;
          final job = Job.fromMap(data);
          if (job.isAvailableForApplication && job.title.isNotEmpty && job.city.isNotEmpty && job.country.isNotEmpty) {
            jobs.add(job);
            DebugLogger.log('getAvailableJobsForAgency', 'JOB_PASSED', data: {
              'docId': docId,
              'jobId': job.id,
              'title': job.title,
            });
          } else {
            filterReasons['failed_validation'] = (filterReasons['failed_validation'] ?? 0) + 1;
          }
        } catch (e, stack) {
          DebugLogger.error('getAvailableJobsForAgency', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
          filterReasons['parse_error'] = (filterReasons['parse_error'] ?? 0) + 1;
          continue;
        }
      }
      
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      
      DebugLogger.log('getAvailableJobsForAgency', 'SUCCESS', data: {
        'agencyId': agencyId,
        'resultCount': jobs.length,
        'totalFetched': snapshot.docs.length,
        'filterReasons': filterReasons,
      });
      return jobs;
    } catch (e, stacktrace) {
      DebugLogger.error('getAvailableJobsForAgency', 'ERROR', e, stacktrace, data: {'agencyId': agencyId});
      rethrow; // DO NOT return [] - let error propagate
    }
  }

  @override
  Future<List<Job>> getJobsForClient(int clientId) async {
    try {
      DebugLogger.log('getJobsForClient', 'START', data: {
        'clientId': clientId,
        'clientIdType': clientId.runtimeType.toString(),
        'filters': 'client_id == $clientId (int), is_deleted == false (bool), orderBy posted_date desc',
      });

      QuerySnapshot snapshot;
      bool usedFallback = false;
      try {
        // Primary query (requires index):
        // where client_id == clientId (int)
        // where is_deleted == false (bool)
        // orderBy posted_date desc
        snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where('client_id', isEqualTo: clientId)
            .where('is_deleted', isEqualTo: false)
            .orderBy('posted_date', descending: true)
            .get();
        
        DebugLogger.log('getJobsForClient', 'QUERY_SUCCESS', data: {
          'clientId': clientId,
          'resultCount': snapshot.docs.length,
          'usedFallback': false,
        });
      } catch (e, stack) {
        final errorStr = e.toString();
        final isIndexError = errorStr.contains('FAILED_PRECONDITION') || 
                            errorStr.contains('requires an index') || 
                            errorStr.contains('index');
        
        if (isIndexError) {
          DebugLogger.log('getJobsForClient', 'INDEX_MISSING_FALLBACK', data: {
            'clientId': clientId,
            'error': errorStr,
          });
          print('⚠️ [getJobsForClient] Index missing, using fallback query (no orderBy)');
          
          // Fallback query WITHOUT orderBy (doesn't require composite index)
          try {
            snapshot = await FirebaseConfig.firestore
                .collection(collectionName)
                .where('client_id', isEqualTo: clientId)
                .where('is_deleted', isEqualTo: false)
                .get();
            
            usedFallback = true;
            DebugLogger.log('getJobsForClient', 'FALLBACK_SUCCESS', data: {
              'clientId': clientId,
              'resultCount': snapshot.docs.length,
            });
          } catch (fallbackError, fallbackStack) {
            DebugLogger.error('getJobsForClient', 'FALLBACK_FAILED', fallbackError, fallbackStack, data: {'clientId': clientId});
            rethrow; // If fallback also fails, rethrow
          }
        } else {
          // Non-index error - rethrow immediately
          DebugLogger.error('getJobsForClient', 'QUERY_FAILED', e, stack, data: {'clientId': clientId});
          rethrow;
        }
      }
      
      final jobs = <Job>[];
      int docIndex = 0;
      for (final doc in snapshot.docs) {
        try {
          // Safe casting: create a new mutable map
          final raw = doc.data();
          final data = Map<String, dynamic>.from(raw as Map);
          final docId = int.tryParse(doc.id) ?? (data['id'] is int ? data['id'] as int : 0);
          data['id'] = docId;
          
          // Log field types for first 3 docs (diagnostics for H3/H4)
          if (docIndex < 3) {
            DebugLogger.log('getJobsForClient', 'DOC_TYPES', data: {
              'docId': doc.id,
              'client_id': data['client_id'],
              'client_id_type': data['client_id']?.runtimeType.toString() ?? 'null',
              'is_deleted': data['is_deleted'],
              'is_deleted_type': data['is_deleted']?.runtimeType.toString() ?? 'null',
              'posted_date': data['posted_date']?.toString() ?? 'missing',
              'posted_date_type': data['posted_date']?.runtimeType.toString() ?? 'null',
            });
          }
          docIndex++;
          
          final job = Job.fromMap(data);
          
          // Additional safety check (shouldn't be needed if query is correct)
          if (job.isDeleted) {
            DebugLogger.log('getJobsForClient', 'FILTERED_DELETED', data: {
              'docId': docId,
              'title': job.title,
            });
            continue;
          }
          
          jobs.add(job);
        } catch (e, stack) {
          DebugLogger.error('getJobsForClient', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
          continue;
        }
      }

      // If fallback was used, sort client-side by postedDate descending
      if (usedFallback) {
        jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
        DebugLogger.log('getJobsForClient', 'CLIENT_SIDE_SORT', data: {
          'clientId': clientId,
          'sortedCount': jobs.length,
        });
      }

      if (jobs.isEmpty) {
        DebugLogger.log('getJobsForClient', 'EMPTY', data: {'clientId': clientId});
      }

      DebugLogger.log('getJobsForClient', 'SUCCESS', data: {
        'clientId': clientId,
        'resultCount': jobs.length,
        'usedFallback': usedFallback,
      });
      return jobs;
    } catch (e, stacktrace) {
      DebugLogger.error('getJobsForClient', 'ERROR', e, stacktrace, data: {'clientId': clientId});
      rethrow; // DO NOT return [] - let error propagate
    }
  }

  @override
  Future<List<Job>> getRecentClientJobs({int limit = 10}) async {
    try {
      DebugLogger.log('JobsDB', 'getRecentClientJobs_START', data: {
        'limit': limit,
        'filters': 'agency_id == null, status == open, assigned_worker_id == null, is_deleted == false',
      });

      // Fetch without orderBy to avoid composite index; filter and sort client-side
      // Only get jobs with status='open' for homepage display
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isNull: true)
          .get();
      
      final jobs = snapshot.docs
          .map((doc) {
            final raw = doc.data();
            final data = Map<String, dynamic>.from(raw as Map);
            data['id'] = int.tryParse(doc.id) ?? 0;
            return Job.fromMap(data);
          })
          .where((job) => 
              job.clientId != null && 
              !job.isDeleted && 
              job.status == JobStatus.open &&
              job.assignedWorkerId == null) // Only unassigned open jobs
          .toList();
      
      // Sort by posted_date descending (most recent first)
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      final result = jobs.length > limit ? jobs.sublist(0, limit) : jobs;

      // Debug log: first 3 jobs
      if (result.isNotEmpty) {
        final firstThree = result.take(3).map((job) => {
          'id': job.id,
          'status': job.status.name,
          'assignedWorkerId': job.assignedWorkerId,
          'isDeleted': job.isDeleted,
          'statusType': job.status.runtimeType.toString(),
          'assignedWorkerIdType': job.assignedWorkerId.runtimeType.toString(),
          'isDeletedType': job.isDeleted.runtimeType.toString(),
        }).toList();

        DebugLogger.log('JobsDB', 'getRecentClientJobs_RESULT', data: {
          'totalCount': result.length,
          'firstThreeJobs': firstThree,
        });
      } else {
        DebugLogger.log('JobsDB', 'getRecentClientJobs_EMPTY', data: {
          'totalDocsFetched': snapshot.docs.length,
        });
      }

      return result;
    } catch (e, stacktrace) {
      DebugLogger.error('JobsDB', 'getRecentClientJobs_ERROR', e, stacktrace, data: {
        'limit': limit,
      });
      return [];
    }
  }

  @override
  Future<void> markJobStarted(int jobId) async {
    try {
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final jobRef = FirebaseConfig.firestore
            .collection(collectionName)
            .doc(jobId.toString());
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }
        
        final jobData = jobDoc.data()!;
        final status = jobData['status'] as String?;
        
        // Only allow starting if job is assigned
        if (status != JobStatus.assigned.name && status != JobStatus.open.name && status != JobStatus.pending.name) {
          throw Exception('Job cannot be started - current status: $status');
        }
        
        transaction.update(jobRef, {
          'status': JobStatus.inProgress.name,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stacktrace) {
      print('markJobStarted error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> cancelJob(int jobId) async {
    try {
      await FirebaseConfig.firestore.runTransaction((transaction) async {
        final jobRef = FirebaseConfig.firestore
            .collection(collectionName)
            .doc(jobId.toString());
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }
        
        final jobData = jobDoc.data()!;
        final assignedWorkerId = jobData['assigned_worker_id'] as int?;
        final clientId = jobData['client_id'] as int?;
        
        // Update job status to cancelled
        transaction.update(jobRef, {
          'status': JobStatus.cancelled.name,
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        // Cancel all pending bookings for this job
        final bookingsSnapshot = await FirebaseConfig.firestore
            .collection('bookings')
            .where('job_id', isEqualTo: jobId)
            .where('status', whereIn: [BookingStatus.pending.name, BookingStatus.inProgress.name])
            .get();
        
        for (final doc in bookingsSnapshot.docs) {
          transaction.update(doc.reference, {
            'status': BookingStatus.cancelled.name,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // Send notifications (after transaction)
      final job = await getJobById(jobId);
      if (job != null) {
        try {
          // Notify assigned worker if any
          if (job.assignedWorkerId != null) {
            await NotificationBackendService.sendToUser(
              userId: job.assignedWorkerId.toString(),
              title: 'Job Cancelled',
              body: 'The job "${job.title}" has been cancelled by the client.',
              route: '/jobDetails',
              id: jobId.toString(),
            );
          }
          
          // Notify all applicants (pending bookings)
          final bookingsRepo = AbstractBookingsRepo.getInstance();
          final applications = await bookingsRepo.getApplicationsForJob(jobId);
          for (final booking in applications) {
            if (booking.status == BookingStatus.pending && booking.providerId != null) {
              await NotificationBackendService.sendToUser(
                userId: booking.providerId.toString(),
                title: 'Job Cancelled',
                body: 'The job "${job.title}" has been cancelled by the client.',
                route: '/jobDetails',
                id: jobId.toString(),
              );
            }
          }
        } catch (e) {
          print('Error sending cancellation notifications: $e');
        }
      }
    } catch (e, stacktrace) {
      print('cancelJob error: $e --> $stacktrace');
      rethrow;
    }
  }

  // ===== Added implementations to satisfy AbstractJobsRepo =====
  @override
  Future<List<Job>> getActiveJobsForWorker(int workerId) async {
    try {
      // TRUTH LOG: Query start
      DebugLogger.log('getActiveJobsForWorker', 'QUERY_START', data: {
        'workerId': workerId,
        'workerIdType': workerId.runtimeType.toString(),
        'filters': 'assigned_worker_id == $workerId (int), is_deleted == false (bool)',
      });
      
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('assigned_worker_id', isEqualTo: workerId)
          .where('is_deleted', isEqualTo: false)
          .get();
      
      DebugLogger.log('getActiveJobsForWorker', 'QUERY_RESULT', data: {
        'workerId': workerId,
        'docCount': snapshot.docs.length,
      });
      
      final activeSet = {
        JobStatus.assigned.name,
        JobStatus.inProgress.name,
        JobStatus.completedPendingConfirmation.name,
      };
      final jobs = <Job>[];
      
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          final data = Map<String, dynamic>.from(raw as Map);
          data['id'] = int.tryParse(doc.id) ?? 0;
          
          // TRUTH LOG: Document fields
          final assignedWorkerIdRaw = data['assigned_worker_id'];
          final statusRaw = data['status']?.toString();
          final isDeletedRaw = data['is_deleted'];
          
          DebugLogger.log('getActiveJobsForWorker', 'DOC_FIELDS', data: {
            'docId': doc.id,
            'assigned_worker_id': assignedWorkerIdRaw,
            'assigned_worker_id_type': assignedWorkerIdRaw?.runtimeType.toString() ?? 'null',
            'status': statusRaw,
            'is_deleted': isDeletedRaw,
            'is_deleted_type': isDeletedRaw?.runtimeType.toString() ?? 'null',
          });
          
          final job = Job.fromMap(data);
          if (activeSet.contains(job.status.name)) {
            jobs.add(job);
            DebugLogger.log('getActiveJobsForWorker', 'JOB_ADDED', data: {
              'jobId': job.id,
              'status': job.status.name,
              'assignedWorkerId': job.assignedWorkerId,
            });
          } else {
            DebugLogger.log('getActiveJobsForWorker', 'JOB_FILTERED_STATUS', data: {
              'jobId': job.id,
              'status': job.status.name,
              'expectedStatuses': activeSet.toList(),
            });
          }
        } catch (e, stack) {
          DebugLogger.error('getActiveJobsForWorker', 'PARSE_ERROR', e, stack, data: {'docId': doc.id});
        }
      }
      
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      
      DebugLogger.log('getActiveJobsForWorker', 'QUERY_COMPLETE', data: {
        'workerId': workerId,
        'totalJobs': jobs.length,
      });
      
      return jobs;
    } catch (e, stacktrace) {
      DebugLogger.error('getActiveJobsForWorker', 'ERROR', e, stacktrace, data: {'workerId': workerId});
      return [];
    }
  }

  @override
  Future<List<Job>> getCompletedJobsForWorker(int workerId) async {
    try {
      // Get jobs where worker was assigned and both parties confirmed completion
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('assigned_worker_id', isEqualTo: workerId)
          .where('is_deleted', isEqualTo: false)
          .get();
      
      final jobs = <Job>[];
      for (final doc in snapshot.docs) {
        final raw = doc.data();
        final data = Map<String, dynamic>.from(raw as Map);
        data['id'] = int.tryParse(doc.id) ?? 0;
        try {
          final job = Job.fromMap(data);
          // Only include jobs where both client_done and worker_done are true
          if (job.clientDone && job.workerDone) {
            jobs.add(job);
          }
        } catch (_) {}
      }
      
      // Sort by most recent first (use updated_at or completed_at if available)
      jobs.sort((a, b) {
        if (a.updatedAt != null && b.updatedAt != null) {
          return b.updatedAt!.compareTo(a.updatedAt!);
        } else if (a.updatedAt != null) {
          return -1;
        } else if (b.updatedAt != null) {
          return 1;
        }
        return b.postedDate.compareTo(a.postedDate);
      });
      
      return jobs;
    } catch (e, stacktrace) {
      print('getCompletedJobsForWorker error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getActiveJobsForClient(int clientId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('client_id', isEqualTo: clientId)
          .where('is_deleted', isEqualTo: false)
          .get();
      final activeSet = {
        JobStatus.assigned.name,
        JobStatus.inProgress.name,
        JobStatus.completedPendingConfirmation.name,
      };
      final jobs = <Job>[];
      for (final doc in snapshot.docs) {
        final raw = doc.data();
        final data = Map<String, dynamic>.from(raw as Map);
        data['id'] = int.tryParse(doc.id) ?? 0;
        try {
          final job = Job.fromMap(data);
          if (activeSet.contains(job.status.name)) {
            jobs.add(job);
          }
        } catch (_) {}
      }
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      return jobs;
    } catch (e, stacktrace) {
      print('getActiveJobsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getCompletedJobsForClient(int clientId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('client_id', isEqualTo: clientId)
          .where('status', isEqualTo: JobStatus.completed.name)
          .where('is_deleted', isEqualTo: false)
          .get();
      final jobs = <Job>[];
      for (final doc in snapshot.docs) {
        final raw = doc.data();
        final data = Map<String, dynamic>.from(raw as Map);
        data['id'] = int.tryParse(doc.id) ?? 0;
        try {
          final job = Job.fromMap(data);
          jobs.add(job);
        } catch (_) {}
      }
      jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      return jobs;
    } catch (e, stacktrace) {
      print('getCompletedJobsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<void> markAllClientJobsAsDeleted(int clientId) async {
    try {
      // Get all jobs for this client (including deleted ones to avoid duplicates)
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('client_id', isEqualTo: clientId)
          .get();
      
      // Use batch write for efficiency
      final batch = FirebaseConfig.firestore.batch();
      int count = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isDeleted = data['is_deleted'];
        
        // Only update if not already deleted
        if (isDeleted != true && isDeleted != 1) {
          batch.update(doc.reference, {
            'is_deleted': true,
            'updated_at': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      
      if (count > 0) {
        await batch.commit();
        print('✅ Marked $count jobs as deleted for client $clientId');
      } else {
        print('ℹ️ No jobs to mark as deleted for client $clientId');
      }
    } catch (e, stacktrace) {
      print('❌ markAllClientJobsAsDeleted error: $e --> $stacktrace');
      rethrow;
    }
  }
}

