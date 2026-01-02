import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';


abstract class AvailableJobsState {}

class AvailableJobsInitial extends AvailableJobsState {}

class AvailableJobsLoading extends AvailableJobsState {}

class AvailableJobsLoaded extends AvailableJobsState {
  final List<Job> jobs;
  
  AvailableJobsLoaded(this.jobs);
}

class AvailableJobsError extends AvailableJobsState {
  final String message;
  AvailableJobsError(this.message);
}

class AvailableJobsCubit extends Cubit<AvailableJobsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  AvailableJobsCubit() : super(AvailableJobsInitial());

  
  Future<void> loadAvailableJobs(int agencyId) async {
    emit(AvailableJobsLoading());
    try {
      final jobs = await _jobsRepo.getAvailableJobsForAgency(agencyId);
      emit(AvailableJobsLoaded(jobs));
    } catch (e) {
      emit(AvailableJobsError('Failed to load available jobs: $e'));
    }
  }

  
  Future<void> refresh(int agencyId) async {
    await loadAvailableJobs(agencyId);
  }
}


