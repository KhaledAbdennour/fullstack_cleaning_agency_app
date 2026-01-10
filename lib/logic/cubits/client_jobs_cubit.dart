import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../core/debug/debug_logger.dart';

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

  Future<void> loadClientJobs(int? clientId) async {
    emit(ClientJobsLoading());

    // Diagnostics for H5: Validate clientId resolution
    DebugLogger.log(
      'ClientJobsCubit',
      'loadClientJobs_START',
      data: {
        'clientId': clientId,
        'clientIdType': clientId?.runtimeType.toString() ?? 'null',
      },
    );

    if (clientId == null) {
      final errorMsg = 'Client ID is null (profile not loaded)';
      DebugLogger.error(
        'ClientJobsCubit',
        'NULL_CLIENT_ID',
        Exception(errorMsg),
        StackTrace.current,
      );
      emit(ClientJobsError(errorMsg));
      return;
    }

    try {
      final jobs = await _jobsRepo.getJobsForClient(clientId);

      // Filter out deleted jobs
      final validJobs = jobs.where((job) => !job.isDeleted).toList();

      // Sort by most recent first (postedDate descending) - same as homepage
      validJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

      DebugLogger.log(
        'ClientJobsCubit',
        'loadClientJobs_SUCCESS',
        data: {
          'clientId': clientId,
          'jobsCount': validJobs.length,
          'filteredDeleted': jobs.length - validJobs.length,
        },
      );
      emit(ClientJobsLoaded(validJobs));
    } catch (e, stack) {
      // Log error before emitting error state
      DebugLogger.error(
        'ClientJobsCubit',
        'loadClientJobs_FAILED',
        e,
        stack,
        data: {'clientId': clientId},
      );
      print('[ClientJobsCubit] loadClientJobs failed: $e');
      print('[ClientJobsCubit] Stack: $stack');
      emit(ClientJobsError('Failed to load client jobs: $e'));
    }
  }

  Future<void> refresh(int? clientId) async {
    await loadClientJobs(clientId);
  }
}
