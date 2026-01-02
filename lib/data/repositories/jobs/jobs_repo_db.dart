import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/job_model.dart';
import '../../models/booking_model.dart';
import 'jobs_repo.dart';

class JobsDB extends AbstractJobsRepo {
  static const String tableName = 'jobs';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $tableName (
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
      final jobsResponse = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('agency_id', agencyId)
          .is_('client_id', null)
          .eq('is_deleted', false)
          .in_('status', [JobStatus.active.name, JobStatus.inProgress.name])
          .order('posted_date', ascending: false);

      // Also get jobs where agency has bookings in progress
      final bookingsResponse = await SupabaseConfig.client
          .from('bookings')
          .select('job_id')
          .eq('provider_id', agencyId)
          .eq('status', BookingStatus.inProgress.name);

      final bookingJobIds = (bookingsResponse as List)
          .map((b) => b['job_id'] as int)
          .toSet();

      final allJobs = <Job>[];
      
      // Add agency-owned jobs
      for (final map in jobsResponse) {
        try {
          allJobs.add(Job.fromMap(Map<String, dynamic>.from(map)));
        } catch (e) {
          print('Error parsing job: $e');
        }
      }

      // Add jobs with bookings
      if (bookingJobIds.isNotEmpty) {
        final bookedJobsResponse = await SupabaseConfig.client
            .from(tableName)
            .select()
            .in_('id', bookingJobIds.toList())
            .eq('is_deleted', false)
            .order('posted_date', ascending: false);

        for (final map in bookedJobsResponse) {
          try {
            final job = Job.fromMap(Map<String, dynamic>.from(map));
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
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('agency_id', agencyId)
          .is_('client_id', null)
          .eq('is_deleted', false)
          .order('posted_date', ascending: false);
      
      return (response as List)
          .map((map) => Job.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getPastJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getAllJobsForAgency(int agencyId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('agency_id', agencyId)
          .is_('client_id', null)
          .eq('is_deleted', false)
          .order('posted_date', ascending: false);
      
      return (response as List)
          .map((map) => Job.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getAllJobsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Job?> getJobById(int jobId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('id', jobId)
          .eq('is_deleted', false)
          .maybeSingle();
      
      if (response == null) return null;
      return Job.fromMap(Map<String, dynamic>.from(response));
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
      jobMap.remove('id');
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(jobMap)
          .select()
          .single();
      
      return Job.fromMap(Map<String, dynamic>.from(response));
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
      
      await SupabaseConfig.client
          .from(tableName)
          .update(jobMap)
          .eq('id', job.id!);
      
      return job.copyWith(updatedAt: now);
    } catch (e, stacktrace) {
      print('updateJob error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteJob(int jobId) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
    } catch (e, stacktrace) {
      print('deleteJob error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> changeJobStatus(int jobId, JobStatus status) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
    } catch (e, stacktrace) {
      print('changeJobStatus error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<int> getTotalJobsCompletedForAgency(int agencyId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('agency_id', agencyId)
          .eq('status', JobStatus.completed.name)
          .eq('is_deleted', false);
      
      return response.count ?? 0;
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
      final appliedJobIdsResponse = await SupabaseConfig.client
          .from('bookings')
          .select('job_id')
          .eq('provider_id', agencyId);
      
      final appliedJobIds = (appliedJobIdsResponse as List)
          .map((b) => b['job_id'] as int)
          .toSet();
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .not_('client_id', 'is', null)
          .is_('agency_id', null)
          .eq('status', JobStatus.active.name)
          .eq('is_deleted', false)
          .order('posted_date', ascending: false);
      
      final jobs = <Job>[];
      for (final map in response) {
        try {
          final job = Job.fromMap(Map<String, dynamic>.from(map));
          if (!appliedJobIds.contains(job.id) &&
              job.title.isNotEmpty &&
              job.city.isNotEmpty &&
              job.country.isNotEmpty) {
            jobs.add(job);
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
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('client_id', clientId)
          .eq('is_deleted', false)
          .order('posted_date', ascending: false);
      
      return (response as List)
          .map((map) => Job.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getJobsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Job>> getRecentClientJobs({int limit = 10}) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .not_('client_id', 'is', null)
          .is_('agency_id', null)
          .eq('is_deleted', false)
          .order('posted_date', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((map) => Job.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getRecentClientJobs error: $e --> $stacktrace');
      return [];
    }
  }
}
