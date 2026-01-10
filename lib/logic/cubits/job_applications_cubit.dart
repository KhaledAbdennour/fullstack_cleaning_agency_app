import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/bookings/bookings_repo.dart';

abstract class JobApplicationsState {}

class JobApplicationsInitial extends JobApplicationsState {}

class JobApplicationsLoading extends JobApplicationsState {}

class JobApplicationsLoaded extends JobApplicationsState {
  final List<Booking> applications;

  JobApplicationsLoaded(this.applications);
}

class JobApplicationsError extends JobApplicationsState {
  final String message;
  JobApplicationsError(this.message);
}

class JobApplicationsCubit extends Cubit<JobApplicationsState> {
  final AbstractBookingsRepo _bookingsRepo = AbstractBookingsRepo.getInstance();

  JobApplicationsCubit() : super(JobApplicationsInitial());

  Future<void> loadApplicationsForJob(int jobId) async {
    emit(JobApplicationsLoading());
    try {
      final applications = await _bookingsRepo.getApplicationsForJob(jobId);
      emit(JobApplicationsLoaded(applications));
    } catch (e) {
      emit(JobApplicationsError('Failed to load applications: $e'));
    }
  }

  Future<void> acceptApplication(int bookingId, int jobId) async {
    try {
      await _bookingsRepo.acceptApplication(bookingId);

      await loadApplicationsForJob(jobId);
    } catch (e) {
      emit(JobApplicationsError('Failed to accept application: $e'));
    }
  }

  Future<void> rejectApplication(int bookingId, int jobId) async {
    try {
      await _bookingsRepo.rejectApplication(bookingId);

      await loadApplicationsForJob(jobId);
    } catch (e) {
      emit(JobApplicationsError('Failed to reject application: $e'));
    }
  }

  Future<void> refresh(int jobId) async {
    await loadApplicationsForJob(jobId);
  }
}
