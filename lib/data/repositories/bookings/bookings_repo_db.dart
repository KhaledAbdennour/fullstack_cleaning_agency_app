import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/booking_model.dart';
import '../../models/job_model.dart';
import 'bookings_repo.dart';
import '../jobs/jobs_repo.dart';

class BookingsDB extends AbstractBookingsRepo {
  static const String collectionName = 'bookings';

  // Keep SQL code for reference
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
      // Get bookings for jobs owned by this agency
      // First get all jobs for this agency
      final jobsRepo = AbstractJobsRepo.getInstance();
      final agencyJobs = await jobsRepo.getAllJobsForAgency(agencyId);
      final jobIds = agencyJobs.map((j) => j.id).whereType<int>().toList();
      
      if (jobIds.isEmpty) return [];
      
      // Get bookings for these jobs
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
      final bookingMap = booking.toMap();
      final id = bookingMap.remove('id');
      bookingMap['created_at'] = FieldValue.serverTimestamp();
      bookingMap['updated_at'] = FieldValue.serverTimestamp();
      
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
        bookingMap['id'] = newId;
      }
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(bookingMap);
      
      final data = bookingMap;
      data['id'] = int.parse(docId);
      return Booking.fromMap(data);
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
      // Get bookings for this job where provider_id is not null (applications)
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('job_id', isEqualTo: jobId)
          .orderBy('created_at', descending: true)
          .get();
      
      // Filter to only include bookings where provider_id is not null (client-side filter)
      return snapshot.docs
          .where((doc) => doc.data()['provider_id'] != null)
          .map((doc) {
            final data = doc.data();
            data['id'] = int.tryParse(doc.id) ?? 0;
            return Booking.fromMap(data);
          })
          .toList();
    } catch (e, stacktrace) {
      print('getApplicationsForJob error: $e --> $stacktrace');
      return [];
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
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(bookingId.toString())
          .update({
            'status': BookingStatus.inProgress.name,
            'updated_at': FieldValue.serverTimestamp(),
          });
      
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
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(bookingId.toString())
          .update({
            'status': BookingStatus.cancelled.name,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e, stacktrace) {
      print('rejectApplication error: $e --> $stacktrace');
      rethrow;
    }
  }
}
