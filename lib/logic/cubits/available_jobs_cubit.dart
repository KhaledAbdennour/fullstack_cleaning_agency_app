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

  Future<void> loadAvailableJobs(
    int agencyId, {
    List<String>? wilayas,
    double? minPrice,
    double? maxPrice,
  }) async {
    emit(AvailableJobsLoading());
    try {
      final allJobs = await _jobsRepo.getAvailableJobsForAgency(agencyId);

      List<Job> filteredJobs = allJobs;

      if (wilayas != null && wilayas.isNotEmpty) {
        filteredJobs = filteredJobs.where((job) {
          final jobCity = job.city.toLowerCase();
          return wilayas.any(
            (wilaya) => jobCity.contains(wilaya.toLowerCase()),
          );
        }).toList();
      }

      if (minPrice != null || maxPrice != null) {
        filteredJobs = filteredJobs.where((job) {
          final budgetMin = job.budgetMin;
          final budgetMax = job.budgetMax;

          if (budgetMin != null || budgetMax != null) {
            final jobMin = budgetMin ?? 0.0;
            final jobMax = budgetMax ?? double.infinity;

            final filterMin = minPrice ?? 0.0;
            final filterMax = maxPrice ?? double.infinity;

            return jobMin <= filterMax && jobMax >= filterMin;
          }

          return true;
        }).toList();
      }

      emit(AvailableJobsLoaded(filteredJobs));
    } catch (e, stack) {
      print('[AvailableJobsCubit] loadAvailableJobs failed: $e');
      print('[AvailableJobsCubit] Stack: $stack');
      emit(AvailableJobsError('Failed to load available jobs: $e'));
    }
  }

  Future<void> refresh(
    int agencyId, {
    List<String>? wilayas,
    double? minPrice,
    double? maxPrice,
  }) async {
    await loadAvailableJobs(
      agencyId,
      wilayas: wilayas,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
