import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cleaning_history_item.dart';
import '../../data/repositories/jobs/jobs_repo.dart';

abstract class CleanerHistoryState {}

class CleanerHistoryInitial extends CleanerHistoryState {}

class CleanerHistoryLoading extends CleanerHistoryState {}

class CleanerHistoryLoaded extends CleanerHistoryState {
  final List<CleaningHistoryItem> items;

  CleanerHistoryLoaded(this.items);
}

class CleanerHistoryError extends CleanerHistoryState {
  final String message;
  CleanerHistoryError(this.message);
}

class CleanerHistoryCubit extends Cubit<CleanerHistoryState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  CleanerHistoryCubit() : super(CleanerHistoryInitial());

  Future<void> loadHistory(int cleanerId, {bool refresh = false}) async {
    if (refresh || state is CleanerHistoryInitial) {
      emit(CleanerHistoryLoading());
    }

    try {
      final completedJobs = await _jobsRepo.getCompletedJobsForWorker(
        cleanerId,
      );

      final items = completedJobs.map((job) {
        CleaningHistoryType type = CleaningHistoryType.apartment;
        if (job.requiredServices != null && job.requiredServices!.isNotEmpty) {
          final services = job.requiredServices!.join(',').toLowerCase();
          if (services.contains('office') || services.contains('commercial')) {
            type = CleaningHistoryType.office;
          } else if (services.contains('villa')) {
            type = CleaningHistoryType.villa;
          } else if (services.contains('house') ||
              services.contains('home') ||
              services.contains('residential')) {
            type = CleaningHistoryType.house;
          } else if (services.contains('industrial')) {
            type = CleaningHistoryType.commercial;
          } else {
            type = CleaningHistoryType.apartment;
          }
        }

        final completionDate = job.updatedAt ?? job.postedDate;

        return CleaningHistoryItem(
          cleanerId: cleanerId,
          title: job.title,
          date: completionDate,
          description: job.description,
          type: type,
          jobId: job.id,
        );
      }).toList();

      emit(CleanerHistoryLoaded(items));
    } catch (e) {
      emit(CleanerHistoryError('Failed to load history: $e'));
    }
  }

  Future<void> refresh(int cleanerId) async {
    await loadHistory(cleanerId, refresh: true);
  }
}
