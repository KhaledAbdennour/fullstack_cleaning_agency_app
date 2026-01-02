import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/job_model.dart';
import '../../models/booking_model.dart';
import 'jobs_repo.dart';

class JobsDB extends AbstractJobsRepo {
  static const String collectionName = 'jobs';

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
      // Get jobs where agency is owner and status is active/in_progress
      final jobsSnapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('client_id', isNull: true)
          .where('is_deleted', isEqualTo: false)
          .where('status', whereIn: [JobStatus.active.name, JobStatus.inProgress.name])
          .orderBy('posted_date', descending: true)
          .get();

      // Also get jobs where agency has bookings in progress
      final bookingsSnapshot = await FirebaseConfig.firestore
          .collection('bookings')
          .where('provider_id', isEqualTo: agencyId)
          .where('status', isEqualTo: BookingStatus.inProgress.name)
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
          allJobs.add(Job.fromMap(data));
        } catch (e) {
          print('Error parsing job: $e');
        }
      }

      // Add jobs with bookings
      if (bookingJobIds.isNotEmpty) {
        final bookedJobsSnapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .where(FieldPath.documentId, whereIn: bookingJobIds.map((id) => id.toString()).toList())
            .where('is_deleted', isEqualTo: false)
            .orderBy('posted_date', descending: true)
            .get();

        for (final doc in bookedJobsSnapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = int.tryParse(doc.id) ?? 0;
            final job = Job.fromMap(data);
            if (!allJobs.any((j) => j.id == job.id)) {
              allJobs.add(job);
            }
          } catch (e) {
            print('Error parsing booked job: $e');
          }
        }
      }

      return allJobs;
    } catch (e, stacktrace) {
      print('getActiveJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getPastJobsForAgency(int agencyId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('client_id', isNull: true)
          .where('is_deleted', isEqualTo: false)
          .orderBy('posted_date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Job.fromMap(data);
      }).toList();
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
          .where('is_deleted', isEqualTo: false)
          .orderBy('posted_date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Job.fromMap(data);
      }).toList();
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
      final now = DateTime.now();
      final jobMap = job.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toMap();
      
      final id = jobMap.remove('id');
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
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(jobMap);
      
      return job.copyWith(id: int.parse(docId), createdAt: now, updatedAt: now);
    } catch (e, stacktrace) {
      print('createJob error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Job> updateJob(Job job) async {
    try {
      final now = DateTime.now();
      final jobMap = job.copyWith(updatedAt: now).toMap();
      jobMap.remove('id');
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
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(jobId.toString())
          .update({
            'is_deleted': true,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e, stacktrace) {
      print('deleteJob error: $e --> $stacktrace');
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

  @override
  Future<List<Job>> getAvailableJobsForAgency(int agencyId) async {
    try {
      // Get jobs posted by clients (not agencies) that are active
      // and not already applied to by this agency
      final appliedJobIdsSnapshot = await FirebaseConfig.firestore
          .collection('bookings')
          .where('provider_id', isEqualTo: agencyId)
          .get();
      
      final appliedJobIds = appliedJobIdsSnapshot.docs
          .map((doc) => doc.data()['job_id'] as int? ?? 0)
          .where((id) => id > 0)
          .toSet();
      
      // Get jobs posted by clients (client_id IS NOT NULL) and not by agencies (agency_id IS NULL)
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isNull: true)
          .where('status', isEqualTo: JobStatus.active.name)
          .where('is_deleted', isEqualTo: false)
          .orderBy('posted_date', descending: true)
          .get();
      
      final jobs = <Job>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Filter client-side for client_id not null
          if (data['client_id'] != null) {
            data['id'] = int.tryParse(doc.id) ?? 0;
            final job = Job.fromMap(data);
            if (!appliedJobIds.contains(job.id) &&
                job.title.isNotEmpty &&
                job.city.isNotEmpty &&
                job.country.isNotEmpty) {
              jobs.add(job);
            }
          }
        } catch (e) {
          print('Error parsing job from map: $e');
          continue;
        }
      }
      return jobs;
    } catch (e, stacktrace) {
      print('getAvailableJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getJobsForClient(int clientId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('client_id', isEqualTo: clientId)
          .where('is_deleted', isEqualTo: false)
          .orderBy('posted_date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Job.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getJobsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getRecentClientJobs({int limit = 10}) async {
    try {
      // Get jobs posted by clients (client_id IS NOT NULL) and not by agencies (agency_id IS NULL)
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isNull: true)
          .where('is_deleted', isEqualTo: false)
          .orderBy('posted_date', descending: true)
          .limit(limit)
          .get();
      
      // Filter to only include jobs where client_id is not null (client-side filter)
      return snapshot.docs
          .where((doc) => doc.data()['client_id'] != null)
          .map((doc) {
            final data = doc.data();
            data['id'] = int.tryParse(doc.id) ?? 0;
            return Job.fromMap(data);
          })
          .toList();
    } catch (e, stacktrace) {
      print('getRecentClientJobs error: $e --> $stacktrace');
      return [];
    }
  }
}
