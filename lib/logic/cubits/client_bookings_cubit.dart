import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/bookings/bookings_repo.dart';
import '../../data/repositories/jobs/jobs_repo.dart';

abstract class ClientBookingsState {}

class ClientBookingsInitial extends ClientBookingsState {}

class ClientBookingsLoading extends ClientBookingsState {}

class ClientBookingsLoaded extends ClientBookingsState {
  final List<Map<String, dynamic>> bookings;

  ClientBookingsLoaded(this.bookings);
}

class ClientBookingsError extends ClientBookingsState {
  final String message;
  ClientBookingsError(this.message);
}

class ClientBookingsCubit extends Cubit<ClientBookingsState> {
  final AbstractBookingsRepo _bookingsRepo = AbstractBookingsRepo.getInstance();
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  ClientBookingsCubit() : super(ClientBookingsInitial());

  Future<void> loadClientBookings(int clientId) async {
    emit(ClientBookingsLoading());
    try {
      final bookings = await _bookingsRepo.getBookingsForClient(clientId);

      final clientBookings = <Map<String, dynamic>>[];

      for (final booking in bookings) {
        final job = await _jobsRepo.getJobById(booking.jobId);
        if (job != null) {
          clientBookings.add({'booking': booking, 'job': job});
        }
      }

      emit(ClientBookingsLoaded(clientBookings));
    } catch (e) {
      emit(ClientBookingsError('Failed to load bookings: $e'));
    }
  }

  Future<void> createBooking({
    required int clientId,
    required int jobId,
  }) async {
    try {
      final booking = Booking(
        jobId: jobId,
        clientId: clientId,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bookingsRepo.createBooking(booking);

      await loadClientBookings(clientId);
    } catch (e) {
      emit(ClientBookingsError('Failed to create booking: $e'));
    }
  }

  Future<void> updateBookingStatus({
    required int bookingId,
    required BookingStatus status,
    required int clientId,
  }) async {
    try {
      final booking = await _bookingsRepo.getBookingById(bookingId);
      if (booking != null) {
        final updatedBooking = booking.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        await _bookingsRepo.updateBooking(updatedBooking);

        await loadClientBookings(clientId);
      }
    } catch (e) {
      emit(ClientBookingsError('Failed to update booking: $e'));
    }
  }

  Future<void> refresh(int clientId) async {
    await loadClientBookings(clientId);
  }
}
