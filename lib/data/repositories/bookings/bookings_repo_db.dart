import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/booking_model.dart';
import '../../models/job_model.dart';
import 'bookings_repo.dart';
import '../jobs/jobs_repo.dart';

class BookingsDB extends AbstractBookingsRepo {
  static const String tableName = 'bookings';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $tableName (
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
      // Get bookings for jobs owned by this agency
      final response = await SupabaseConfig.client
          .from(tableName)
          .select('*, jobs!inner(agency_id)')
          .eq('jobs.agency_id', agencyId)
          .order('created_at', ascending: false);
      
      // Filter and map results
      final bookings = <Booking>[];
      for (final item in response) {
        try {
          final bookingData = Map<String, dynamic>.from(item);
          // Remove nested jobs data
          bookingData.remove('jobs');
          bookings.add(Booking.fromMap(bookingData));
        } catch (e) {
          print('Error parsing booking: $e');
        }
      }
      return bookings;
    } catch (e, stacktrace) {
      print('getBookingsForAgency error: $e --> $stacktrace');
      // Fallback: get bookings by querying jobs first
      try {
        final jobsRepo = AbstractJobsRepo.getInstance();
        final agencyJobs = await jobsRepo.getAllJobsForAgency(agencyId);
        final jobIds = agencyJobs.map((j) => j.id).whereType<int>().toList();
        
        if (jobIds.isEmpty) return [];
        
        final response = await SupabaseConfig.client
            .from(tableName)
            .select()
            .in_('job_id', jobIds)
            .order('created_at', ascending: false);
        
        return (response as List)
            .map((map) => Booking.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      } catch (e2) {
        print('Fallback query error: $e2');
        return [];
      }
    }
  }

  @override
  Future<List<Booking>> getBookingsForClient(int clientId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Booking.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getBookingsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Booking?> getBookingById(int bookingId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('id', bookingId)
          .maybeSingle();
      
      if (response == null) return null;
      return Booking.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('getBookingById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      final bookingMap = booking.toMap();
      bookingMap.remove('id');
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(bookingMap)
          .select()
          .single();
      
      return Booking.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('createBooking error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Booking> updateBooking(Booking booking) async {
    try {
      final bookingMap = booking.toMap();
      bookingMap.remove('id');
      
      await SupabaseConfig.client
          .from(tableName)
          .update(bookingMap)
          .eq('id', booking.id!);
      
      return booking;
    } catch (e, stacktrace) {
      print('updateBooking error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getApplicationsForJob(int jobId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('job_id', jobId)
          .not_('provider_id', 'is', null)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Booking.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getApplicationsForJob error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Booking>> getAcceptedJobsForCleaner(int cleanerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('provider_id', cleanerId)
          .eq('status', BookingStatus.inProgress.name)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Booking.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getAcceptedJobsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<void> acceptApplication(int bookingId) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await SupabaseConfig.client
          .from(tableName)
          .update({
            'status': BookingStatus.inProgress.name,
            'updated_at': now,
          })
          .eq('id', bookingId);
      
      // Update job status
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        final jobsRepo = AbstractJobsRepo.getInstance();
        final job = await jobsRepo.getJobById(booking.jobId);
        if (job != null) {
          await jobsRepo.changeJobStatus(booking.jobId, JobStatus.booked);
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
      final now = DateTime.now().toIso8601String();
      
      await SupabaseConfig.client
          .from(tableName)
          .update({
            'status': BookingStatus.cancelled.name,
            'updated_at': now,
          })
          .eq('id', bookingId);
    } catch (e, stacktrace) {
      print('rejectApplication error: $e --> $stacktrace');
      rethrow;
    }
  }
}
