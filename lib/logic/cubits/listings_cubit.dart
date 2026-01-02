import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/profiles/profile_repo.dart';



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

  
  Future<void> loadListings() async {
    emit(ListingsLoading());
    try {
      
      final recentClientJobs = await _jobsRepo.getRecentClientJobs(limit: 10);
      
      
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      final agency = profiles.firstWhere(
        (p) => p['user_type'] == 'Agency',
        orElse: () => profiles.first,
      );
      final agencyId = agency['id'] as int?;
      
      List<Job> agencyJobs = [];
      if (agencyId != null) {
        agencyJobs = await _jobsRepo.getAllJobsForAgency(agencyId);
      }
      
      
      final allJobs = [...recentClientJobs, ...agencyJobs];
      allJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      final recent = allJobs.take(10).toList();

      
      
      final topAgencies = _getDummyTopAgencies();
      final topCleaners = _getDummyTopCleaners();

      emit(ListingsLoaded(
        recentListings: recent,
        topAgencies: topAgencies,
        topCleaners: topCleaners,
      ));
    } catch (e) {
      emit(ListingsError('Failed to load listings: $e'));
    }
  }

  
  Future<void> refresh() async {
    await loadListings();
  }

  
  List<Map<String, dynamic>> _getDummyTopAgencies() {
    return [
      {
        'name': 'CleanSpace Agency',
        'rating': 4.9,
        'jobsCompleted': 1234,
        'location': 'Algiers',
        'image': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop',
        'id': 1,
      },
      {
        'name': 'ProClean Services',
        'rating': 4.7,
        'jobsCompleted': 856,
        'location': 'Oran',
        'image': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop',
        'id': 2,
      },
    ];
  }

  
  List<Map<String, dynamic>> _getDummyTopCleaners() {
    return [
      {
        'name': 'Fatima Zahra',
        'rating': 4.8,
        'jobsCompleted': 124,
        'location': 'Algiers',
        'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
        'id': 1,
      },
      {
        'name': 'Ahmed Ali',
        'rating': 5.0,
        'jobsCompleted': 98,
        'location': 'Constantine',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        'id': 2,
      },
      {
        'name': 'Yasmine K.',
        'rating': 4.5,
        'jobsCompleted': 76,
        'location': 'Oran',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop',
        'id': 3,
      },
    ];
  }
}

