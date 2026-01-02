import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profiles/profile_repo.dart';



abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Map<String, dynamic>> results;
  final String? searchQuery;
  final String? locationFilter;
  final String? ratingFilter;
  final String? priceFilter;
  
  SearchLoaded({
    required this.results,
    this.searchQuery,
    this.locationFilter,
    this.ratingFilter,
    this.priceFilter,
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

class SearchCubit extends Cubit<SearchState> {
  final AbstractProfileRepo _profileRepo = AbstractProfileRepo.getInstance();

  SearchCubit() : super(SearchInitial());

  
  Future<void> loadSearchResults({
    String? query,
    String? location,
    String? rating,
    String? price,
  }) async {
    emit(SearchLoading());
    try {
      
      final allProfiles = await _profileRepo.getAllProfiles();
      final cleanersAndAgencies = allProfiles.where((profile) {
        final userType = profile['user_type'] as String?;
        return userType == 'Individual Cleaner' || userType == 'Agency';
      }).toList();

      
      List<Map<String, dynamic>> results = cleanersAndAgencies.map((profile) {
        final userType = profile['user_type'] as String?;
        final agencyName = profile['agency_name'] as String?;
        final fullName = profile['full_name'] as String?;
        final name = userType == 'Agency' 
            ? (agencyName ?? fullName ?? 'Unknown')
            : (fullName ?? 'Unknown');
        
        return {
          'id': profile['id'],
          'name': name,
          'description': profile['bio'] as String? ?? '',
          'location': _extractLocation(profile['address'] as String?),
          'price': profile['hourly_rate'] != null 
              ? 'From ${profile['hourly_rate']} DZD/hr'
              : 'Contact for pricing',
          'rating': (profile['rating'] as num?)?.toDouble() ?? 4.5,
          'reviews': profile['reviews_count'] as int? ?? 0,
          'image': profile['avatar_url'] as String?,
          'isVerified': profile['is_verified'] as bool? ?? false,
          'type': userType == 'Agency' ? 'Agency' : 'Individual',
          'userType': userType,
          'aboutMe': profile['bio'] as String? ?? 'Professional cleaning service provider.',
          'experience': profile['experience_years'] != null 
              ? '${profile['experience_years']}+ Years'
              : '5+ Years',
          'age': profile['age'] != null ? profile['age'].toString() : '28',
          'languages': profile['languages'] as String? ?? 'Arabic, French',
          'agency': userType == 'Agency' ? null : (profile['agency_name'] as String?),
          'profileData': profile,
        };
      }).toList();

      
      results = _applyFilters(results, query: query, location: location, rating: rating, price: price);

      emit(SearchLoaded(
        results: results,
        searchQuery: query,
        locationFilter: location,
        ratingFilter: rating,
        priceFilter: price,
      ));
    } catch (e) {
      emit(SearchError('Failed to load search results: $e'));
    }
  }

  
  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> results, {
    String? query,
    String? location,
    String? rating,
    String? price,
  }) {
    var filtered = results;

    
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        final description = (item['description'] as String? ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }

    
    if (location != null && location != 'All') {
      filtered = filtered.where((item) {
        final itemLocation = (item['location'] as String? ?? '').toLowerCase();
        return itemLocation.contains(location.toLowerCase());
      }).toList();
    }

    
    if (rating != null && rating != 'All') {
      final minRating = _parseRatingFilter(rating);
      filtered = filtered.where((item) {
        final itemRating = (item['rating'] as num? ?? 0.0).toDouble();
        return itemRating >= minRating;
      }).toList();
    }

    
    if (price != null && price != 'All') {
      
      
    }

    return filtered;
  }

  
  String _extractLocation(String? address) {
    if (address == null || address.isEmpty) return 'Unknown';
    
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  
  double _parseRatingFilter(String rating) {
    switch (rating) {
      case '4.5+':
        return 4.5;
      case '4.0+':
        return 4.0;
      case '3.5+':
        return 3.5;
      default:
        return 0.0;
    }
  }

  
  Future<void> refresh({
    String? query,
    String? location,
    String? rating,
    String? price,
  }) async {
    await loadSearchResults(
      query: query,
      location: location,
      rating: rating,
      price: price,
    );
  }
}

