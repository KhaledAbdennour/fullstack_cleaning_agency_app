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
      
      // Apply filters
      List<Job> filteredJobs = allJobs;
      
      // Filter by wilayas (provinces)
      if (wilayas != null && wilayas.isNotEmpty) {
        filteredJobs = filteredJobs.where((job) {
          final jobCity = job.city.toLowerCase();
          return wilayas.any((wilaya) => jobCity.contains(wilaya.toLowerCase()));
        }).toList();
      }
      
      // Filter by price range
      if (minPrice != null || maxPrice != null) {
        filteredJobs = filteredJobs.where((job) {
          final budgetMin = job.budgetMin;
          final budgetMax = job.budgetMax;
          
          // If job has budget range
          if (budgetMin != null || budgetMax != null) {
            // Check if job's budget range overlaps with filter range
            final jobMin = budgetMin ?? 0.0;
            final jobMax = budgetMax ?? double.infinity;
            
            final filterMin = minPrice ?? 0.0;
            final filterMax = maxPrice ?? double.infinity;
            
            // Overlap check: job range overlaps with filter range
            return jobMin <= filterMax && jobMax >= filterMin;
          }
          
          // If job has no budget, include it (or exclude based on requirement)
          // For now, we'll include jobs without budget
          return true;
        }).toList();
      }
      
      emit(AvailableJobsLoaded(filteredJobs));
    } catch (e, stack) {
      // Log error before emitting error state
      print('❌ [AvailableJobsCubit] loadAvailableJobs failed: $e');
      print('❌ [AvailableJobsCubit] Stack: $stack');
      emit(AvailableJobsError('Failed to load available jobs: $e'));
    }
  }

  
  Future<void> refresh(
    int agencyId, {
    List<String>? wilayas,
    double? minPrice,
    double? maxPrice,
  }) async {
    await loadAvailableJobs(agencyId, wilayas: wilayas, minPrice: minPrice, maxPrice: maxPrice);
  }
}


