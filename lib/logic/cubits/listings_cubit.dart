import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../core/debug/debug_logger.dart';

abstract class ListingsState {}

class ListingsInitial extends ListingsState {}

class ListingsLoading extends ListingsState {}

class ListingsLoaded extends ListingsState {
  final List<Job> recentListings;
  final List<Map<String, dynamic>> topAgencies;
  final List<Map<String, dynamic>> topCleaners;

  ListingsLoaded({
    required this.recentListings,
    required this.topAgencies,
    required this.topCleaners,
  });
}

class ListingsError extends ListingsState {
  final String message;
  ListingsError(this.message);
}

class ListingsCubit extends Cubit<ListingsState> {
  final AbstractJobsRepo _jobsRepo = AbstractJobsRepo.getInstance();

  ListingsCubit() : super(ListingsInitial());

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  DateTime _profileRecency(Map<String, dynamic> profile) {
    final updated = _parseDate(profile['updated_at']);
    final created = _parseDate(profile['created_at']);
    return updated ?? created ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> loadListings() async {
    emit(ListingsLoading());
    try {
      final recentClientJobs = await _jobsRepo.getRecentClientJobs(limit: 100);

      final validJobs = recentClientJobs
          .where(
            (job) =>
                !job.isDeleted &&
                job.status == JobStatus.open &&
                job.assignedWorkerId == null,
          )
          .toList();

      validJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      final recent = validJobs.take(50).toList();

      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();

      final allAgencies = profiles
          .where((p) => p['user_type'] == 'Agency')
          .map(
            (p) => {
              'name': p['agency_name'] ?? p['full_name'] ?? 'Unknown Agency',
              'rating': (p['rating'] as num?)?.toDouble() ?? 0.0,
              'jobsCompleted': (p['jobs_completed'] as int?) ?? 0,
              'location': p['address'] ?? 'Unknown',
              'image': p['picture'] ?? '',
              'id': p['id'],
              'created_at': p['created_at'],
              'updated_at': p['updated_at'],
              'bio': p['bio'],
              'hourly_rate': p['hourly_rate'],
              'is_verified': p['is_verified'] ?? false,
            },
          )
          .toList();

      allAgencies.sort((a, b) {
        final ratingA = (a['rating'] as double? ?? 0.0);
        final ratingB = (b['rating'] as double? ?? 0.0);
        final ratingCmp = ratingB.compareTo(ratingA);
        if (ratingCmp != 0) return ratingCmp;

        final recencyA = _profileRecency(a);
        final recencyB = _profileRecency(b);
        return recencyB.compareTo(recencyA);
      });

      if (allAgencies.isNotEmpty) {
        final topFive = allAgencies
            .take(5)
            .map(
              (a) => {
                'id': a['id'],
                'name': a['name'],
                'rating': a['rating'],
                'created_at_ms': _profileRecency(a).millisecondsSinceEpoch,
              },
            )
            .toList();

        DebugLogger.log(
          'ListingsCubit',
          'loadListings_TOP_AGENCIES',
          data: {'totalAgencies': allAgencies.length, 'topFive': topFive},
        );
      }

      final allCleaners = profiles
          .where((p) => p['user_type'] == 'Individual Cleaner')
          .map(
            (p) => {
              'name': p['full_name'] ?? 'Unknown Cleaner',
              'rating': (p['rating'] as num?)?.toDouble() ?? 0.0,
              'jobsCompleted': (p['jobs_completed'] as int?) ?? 0,
              'location': p['address'] ?? 'Unknown',
              'image': p['picture'] ?? '',
              'id': p['id'],
              'created_at': p['created_at'],
              'updated_at': p['updated_at'],
              'bio': p['bio'],
              'hourly_rate': p['hourly_rate'],
              'is_verified': p['is_verified'] ?? false,
            },
          )
          .toList();

      allCleaners.sort((a, b) {
        final ratingA = (a['rating'] as double? ?? 0.0);
        final ratingB = (b['rating'] as double? ?? 0.0);
        final ratingCmp = ratingB.compareTo(ratingA);
        if (ratingCmp != 0) return ratingCmp;

        final recencyA = _profileRecency(a);
        final recencyB = _profileRecency(b);
        return recencyB.compareTo(recencyA);
      });

      if (allCleaners.isNotEmpty) {
        final topFive = allCleaners
            .take(5)
            .map(
              (c) => {
                'id': c['id'],
                'name': c['name'],
                'rating': c['rating'],
                'created_at_ms': _profileRecency(c).millisecondsSinceEpoch,
              },
            )
            .toList();

        DebugLogger.log(
          'ListingsCubit',
          'loadListings_TOP_CLEANERS',
          data: {'totalCleaners': allCleaners.length, 'topFive': topFive},
        );
      }

      emit(
        ListingsLoaded(
          recentListings: recent,
          topAgencies: allAgencies,
          topCleaners: allCleaners,
        ),
      );
    } catch (e) {
      emit(ListingsError('Failed to load listings: $e'));
    }
  }

  Future<void> refresh() async {
    await loadListings();
  }
}
