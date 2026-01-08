import '../../models/booking_model.dart';
import 'bookings_repo_db.dart';


abstract class AbstractBookingsRepo {
  Future<List<Booking>> getBookingsForAgency(int agencyId);
  Future<List<Booking>> getBookingsForClient(int clientId);
  Future<List<Booking>> getApplicationsForJob(int jobId); 
  Future<List<Booking>> getAcceptedJobsForCleaner(int cleanerId); 
  Future<Booking?> getBookingById(int bookingId);
  Future<Booking> createBooking(Booking booking);
  Future<Booking> updateBooking(Booking booking);
  Future<void> acceptApplication(int bookingId); 
  Future<void> rejectApplication(int bookingId);
  Future<void> withdrawApplication(int bookingId); // Worker withdraws their application 

  static AbstractBookingsRepo? _instance;
  static AbstractBookingsRepo getInstance() {
    _instance ??= BookingsDB();
    return _instance!;
  }
}

