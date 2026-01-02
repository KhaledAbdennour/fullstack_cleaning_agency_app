import '../../databases/dbhelper.dart';
import '../../models/booking_model.dart';
import '../../models/job_model.dart';
import 'bookings_repo.dart';
import '../jobs/jobs_repo_db.dart';
import '../jobs/jobs_repo.dart';

class BookingsDB extends AbstractBookingsRepo {
  static const String tableName = 'bookings';

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
      FOREIGN KEY (job_id) REFERENCES ${JobsDB.tableName}(id),
      FOREIGN KEY (client_id) REFERENCES profiles(id),
      FOREIGN KEY (provider_id) REFERENCES profiles(id)
    )
  ''';

  @override
  Future<List<Booking>> getBookingsForAgency(int agencyId) async {
    try {
      final db = await DBHelper.getDatabase();
      final maps = await db.rawQuery('''
        SELECT b.* FROM $tableName b
        INNER JOIN ${JobsDB.tableName} j ON b.job_id = j.id
        WHERE j.agency_id = ?
        ORDER BY b.created_at DESC
      ''', [agencyId]);
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getBookingsForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Booking>> getBookingsForClient(int clientId) async {
    try {
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getBookingsForClient error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Booking?> getBookingById(int bookingId) async {
    try {
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      if (maps.isEmpty) return null;
      return Booking.fromMap(maps.first);
    } catch (e, stacktrace) {
      print('getBookingById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      final db = await DBHelper.getDatabase();
      final bookingMap = booking.toMap();
      bookingMap.remove('id');
      final id = await db.insert(tableName, bookingMap);
      return booking.copyWith(id: id);
    } catch (e, stacktrace) {
      print('createBooking error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Booking> updateBooking(Booking booking) async {
    try {
      final db = await DBHelper.getDatabase();
      final bookingMap = booking.toMap();
      bookingMap.remove('id');
      await db.update(
        tableName,
        bookingMap,
        where: 'id = ?',
        whereArgs: [booking.id],
      );
      return booking;
    } catch (e, stacktrace) {
      print('updateBooking error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getApplicationsForJob(int jobId) async {
    try {
      final db = await DBHelper.getDatabase();
      
      final maps = await db.query(
        tableName,
        where: 'job_id = ? AND provider_id IS NOT NULL',
        whereArgs: [jobId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getApplicationsForJob error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<List<Booking>> getAcceptedJobsForCleaner(int cleanerId) async {
    try {
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'provider_id = ? AND status = ?',
        whereArgs: [cleanerId, BookingStatus.inProgress.name],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getAcceptedJobsForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<void> acceptApplication(int bookingId) async {
    try {
      final db = await DBHelper.getDatabase();
      final now = DateTime.now().toIso8601String();
      
      await db.update(
        tableName,
        {
          'status': BookingStatus.inProgress.name,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      
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
      final db = await DBHelper.getDatabase();
      final now = DateTime.now().toIso8601String();
      
      await db.update(
        tableName,
        {
          'status': BookingStatus.cancelled.name,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );
    } catch (e, stacktrace) {
      print('rejectApplication error: $e --> $stacktrace');
      rethrow;
    }
  }
}


