import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';

abstract class WorkerActiveJobsState {}

class WorkerActiveJobsInitial extends WorkerActiveJobsState {}

class WorkerActiveJobsLoading extends WorkerActiveJobsState {}

class WorkerActiveJobsLoaded extends WorkerActiveJobsState {
  final List<Job> activeJobs;
  WorkerActiveJobsLoaded(this.activeJobs);
}

class WorkerActiveJobsError extends WorkerActiveJobsState {
  final String message;
  WorkerActiveJobsError(this.message);
}

class WorkerActiveJobsCubit extends Cubit<WorkerActiveJobsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  WorkerActiveJobsCubit() : super(WorkerActiveJobsInitial());

  Future<void> loadActiveJobs(int workerId) async {
    emit(WorkerActiveJobsLoading());
    try {
      final jobs = await _jobsRepo.getActiveJobsForWorker(workerId);
      emit(WorkerActiveJobsLoaded(jobs));
    } catch (e) {
      emit(WorkerActiveJobsError('Failed to load active jobs: $e'));
    }
  }

  Future<void> refresh(int workerId) async {
    await loadActiveJobs(workerId);
  }
}
