import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/models/cleaner_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/cleaners/cleaners_repo.dart';

abstract class ActiveListingsState {}

class ActiveListingsInitial extends ActiveListingsState {}

class ActiveListingsLoading extends ActiveListingsState {}

class ActiveListingsLoaded extends ActiveListingsState {
  final List<Job> jobs;
  final int totalJobsCompleted;
  ActiveListingsLoaded(this.jobs, this.totalJobsCompleted);
}

class ActiveListingsError extends ActiveListingsState {
  final String message;
  ActiveListingsError(this.message);
}

abstract class PastBookingsState {}

class PastBookingsInitial extends PastBookingsState {}

class PastBookingsLoading extends PastBookingsState {}

class PastBookingsLoaded extends PastBookingsState {
  final List<Job> jobs;
  PastBookingsLoaded(this.jobs);
}

class PastBookingsError extends PastBookingsState {
  final String message;
  PastBookingsError(this.message);
}

abstract class CleanerTeamState {}

class CleanerTeamInitial extends CleanerTeamState {}

class CleanerTeamLoading extends CleanerTeamState {}

class CleanerTeamLoaded extends CleanerTeamState {
  final List<Cleaner> cleaners;
  CleanerTeamLoaded(this.cleaners);
}

class CleanerTeamError extends CleanerTeamState {
  final String message;
  CleanerTeamError(this.message);
}

class ActiveListingsCubit extends Cubit<ActiveListingsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  ActiveListingsCubit() : super(ActiveListingsInitial());

  Future<void> loadActiveListings(int agencyId) async {
    emit(ActiveListingsLoading());
    try {
      final jobs = await _jobsRepo.getActiveJobsForAgency(agencyId);
      final totalCompleted = await _jobsRepo.getTotalJobsCompletedForAgency(
        agencyId,
      );
      emit(ActiveListingsLoaded(jobs, totalCompleted));
    } catch (e) {
      emit(ActiveListingsError('Failed to load active listings: $e'));
    }
  }

  Future<void> refresh(int agencyId) async {
    await loadActiveListings(agencyId);
  }
}

class PastBookingsCubit extends Cubit<PastBookingsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  PastBookingsCubit() : super(PastBookingsInitial());

  Future<void> loadPastBookings(int agencyId) async {
    emit(PastBookingsLoading());
    try {
      final jobs = await _jobsRepo.getPastJobsForAgency(agencyId);
      emit(PastBookingsLoaded(jobs));
    } catch (e) {
      emit(PastBookingsError('Failed to load past bookings: $e'));
    }
  }

  Future<void> refresh(int agencyId) async {
    await loadPastBookings(agencyId);
  }

  Future<void> changeJobStatus(
    int jobId,
    JobStatus status,
    int agencyId,
  ) async {
    try {
      await _jobsRepo.changeJobStatus(jobId, status);

      await loadPastBookings(agencyId);
    } catch (e) {
      emit(PastBookingsError('Failed to change job status: $e'));
    }
  }

  Future<void> deleteJob(int jobId, int agencyId) async {
    try {
      await _jobsRepo.deleteJob(jobId);
      await loadPastBookings(agencyId);
    } catch (e) {
      emit(PastBookingsError('Failed to delete job: $e'));
    }
  }
}

class CleanerTeamCubit extends Cubit<CleanerTeamState> {
  final AbstractCleanersRepo _cleanersRepo = AbstractCleanersRepo.getInstance();

  CleanerTeamCubit() : super(CleanerTeamInitial());

  Future<void> loadCleaners(int agencyId) async {
    emit(CleanerTeamLoading());
    try {
      final cleaners = await _cleanersRepo.getCleanersForAgency(agencyId);
      emit(CleanerTeamLoaded(cleaners));
    } catch (e) {
      emit(CleanerTeamError('Failed to load cleaners: $e'));
    }
  }

  Future<void> refresh(int agencyId) async {
    await loadCleaners(agencyId);
  }
}
