import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';


abstract class ClientJobsState {}

class ClientJobsInitial extends ClientJobsState {}

class ClientJobsLoading extends ClientJobsState {}

class ClientJobsLoaded extends ClientJobsState {
  final List<Job> jobs;
  
  ClientJobsLoaded(this.jobs);
}

class ClientJobsError extends ClientJobsState {
  final String message;
  ClientJobsError(this.message);
}

class ClientJobsCubit extends Cubit<ClientJobsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  ClientJobsCubit() : super(ClientJobsInitial());

  
  Future<void> loadClientJobs(int clientId) async {
    emit(ClientJobsLoading());
    try {
      final jobs = await _jobsRepo.getJobsForClient(clientId);
      emit(ClientJobsLoaded(jobs));
    } catch (e) {
      emit(ClientJobsError('Failed to load client jobs: $e'));
    }
  }

  
  Future<void> refresh(int clientId) async {
    await loadClientJobs(clientId);
  }
}




