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
      // best-effort: treat as epoch milliseconds
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  DateTime _profileRecency(Map<String, dynamic> profile) {
    // Prefer updated_at when present, otherwise created_at.
    // Falls back to epoch start so "unknown" is always least recent.
    final updated = _parseDate(profile['updated_at']);
    final created = _parseDate(profile['created_at']);
    return updated ?? created ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  
  Future<void> loadListings() async {
    emit(ListingsLoading());
    try {
      // Load ALL recent client jobs (not just limit 10, we'll sort and take most recent)
      // Get recent jobs from database, sorted by posted_date descending
      final recentClientJobs = await _jobsRepo.getRecentClientJobs(limit: 100);
      
      // Filter out deleted jobs AND non-open jobs (only "Open" should appear on homepage)
      // Note: getRecentClientJobs already filters for open status, but double-check here
      final validJobs = recentClientJobs
          .where((job) =>
              !job.isDeleted &&
              job.status == JobStatus.open &&
              job.assignedWorkerId == null)
          .toList();
      // Sort by posted_date descending (most recent at the left)
      validJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      final recent = validJobs.take(50).toList(); // Show top 50 most recent

      // Get ALL agencies from database; sort by rating desc, then recency desc (tie-breaker)
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      
      final allAgencies = profiles
          .where((p) => p['user_type'] == 'Agency')
          .map((p) => {
                'name': p['agency_name'] ?? p['full_name'] ?? 'Unknown Agency',
                'rating': (p['rating'] as num?)?.toDouble() ?? 0.0,
                'jobsCompleted': (p['jobs_completed'] as int?) ?? 0,
                'location': p['address'] ?? 'Unknown',
                'image': p['picture'] ?? '',
                'id': p['id'],
                'created_at': p['created_at'],
                'updated_at': p['updated_at'],
              })
          .toList();
      
      // Sort by rating descending, then by recency descending (most recent/highest rated at left)
      allAgencies.sort((a, b) {
        final ratingA = (a['rating'] as double? ?? 0.0);
        final ratingB = (b['rating'] as double? ?? 0.0);
        final ratingCmp = ratingB.compareTo(ratingA); // Higher rating first
        if (ratingCmp != 0) return ratingCmp;
        // Tie-breaker: most recent first (higher timestamp = more recent)
        final recencyA = _profileRecency(a);
        final recencyB = _profileRecency(b);
        return recencyB.compareTo(recencyA); // More recent first
      });

      // Debug log: top 5 agencies
      if (allAgencies.isNotEmpty) {
        final topFive = allAgencies.take(5).map((a) => {
          'id': a['id'],
          'name': a['name'],
          'rating': a['rating'],
          'created_at_ms': _profileRecency(a).millisecondsSinceEpoch,
        }).toList();

        DebugLogger.log('ListingsCubit', 'loadListings_TOP_AGENCIES', data: {
          'totalAgencies': allAgencies.length,
          'topFive': topFive,
        });
      }

      // Get ALL individuals/cleaners from database; sort by rating desc, then recency desc (tie-breaker)
      final allCleaners = profiles
          .where((p) => p['user_type'] == 'Individual Cleaner')
          .map((p) => {
                'name': p['full_name'] ?? 'Unknown Cleaner',
                'rating': (p['rating'] as num?)?.toDouble() ?? 0.0,
                'jobsCompleted': (p['jobs_completed'] as int?) ?? 0,
                'location': p['address'] ?? 'Unknown',
                'image': p['picture'] ?? '',
                'id': p['id'],
                'created_at': p['created_at'],
                'updated_at': p['updated_at'],
              })
          .toList();
      
      // Sort by rating descending, then by recency descending (most recent/highest rated at left)
      allCleaners.sort((a, b) {
        final ratingA = (a['rating'] as double? ?? 0.0);
        final ratingB = (b['rating'] as double? ?? 0.0);
        final ratingCmp = ratingB.compareTo(ratingA); // Higher rating first
        if (ratingCmp != 0) return ratingCmp;
        // Tie-breaker: most recent first (higher timestamp = more recent)
        final recencyA = _profileRecency(a);
        final recencyB = _profileRecency(b);
        return recencyB.compareTo(recencyA); // More recent first
      });

      // Debug log: top 5 cleaners
      if (allCleaners.isNotEmpty) {
        final topFive = allCleaners.take(5).map((c) => {
          'id': c['id'],
          'name': c['name'],
          'rating': c['rating'],
          'created_at_ms': _profileRecency(c).millisecondsSinceEpoch,
        }).toList();

        DebugLogger.log('ListingsCubit', 'loadListings_TOP_CLEANERS', data: {
          'totalCleaners': allCleaners.length,
          'topFive': topFive,
        });
      }

      emit(ListingsLoaded(
        recentListings: recent,
        topAgencies: allAgencies, // ALL agencies, not just top 5
        topCleaners: allCleaners, // ALL individuals, not just top 5
      ));
    } catch (e) {
      emit(ListingsError('Failed to load listings: $e'));
    }
  }

  
  Future<void> refresh() async {
    await loadListings();
  }}

