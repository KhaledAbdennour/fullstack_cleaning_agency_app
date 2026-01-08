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
    List<String>? wilayas,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
  }) async {
    emit(SearchLoading());
    try {
      
      final allProfiles = await _profileRepo.getAllProfiles();
      // Filter out clients - show all non-client profiles (cleaners, agencies, etc.)
      final cleanersAndAgencies = allProfiles.where((profile) {
        final userType = (profile['user_type'] as String?)?.trim();
        // Show all profiles that are NOT clients (case-insensitive check)
        if (userType == null || userType.isEmpty) return false;
        return userType.toLowerCase() != 'client';
      }).toList();
      
      print('📊 [SearchCubit] Total profiles: ${allProfiles.length}');
      print('📊 [SearchCubit] Non-client profiles: ${cleanersAndAgencies.length}');

      
      List<Map<String, dynamic>> results = cleanersAndAgencies.map((profile) {
        final userType = profile['user_type'] as String?;
        final agencyName = profile['agency_name'] as String?;
        final fullName = profile['full_name'] as String?;
        final name = userType == 'Agency' 
            ? (agencyName ?? fullName ?? 'Unknown')
            : (fullName ?? 'Unknown');
        
        // Use real data only - no dummy defaults
        final rating = (profile['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewsCount = profile['reviews_count'] as int? ?? (profile['jobs_completed'] as int?) ?? 0;
        final bio = profile['bio'] as String?;
        final experienceYears = profile['experience_years'] as int?;
        final age = profile['age'];
        final languages = profile['languages'] as String?;
        final hourlyRate = profile['hourly_rate'];
        
        return {
          'id': profile['id'],
          'name': name,
          'description': bio ?? '',
          'location': _extractLocation(profile['address'] as String?),
          'price': hourlyRate != null 
              ? 'From $hourlyRate DZD/hr'
              : 'Contact for pricing',
          'rating': rating,
          'reviews': reviewsCount,
          'image': profile['picture'] as String?,
          'isVerified': profile['is_verified'] as bool? ?? false,
          'type': userType == 'Agency' ? 'Agency' : 'Individual',
          'userType': userType,
          'aboutMe': bio ?? '',
          'experience': experienceYears != null 
              ? '$experienceYears+ Years'
              : null,
          'age': age != null ? age.toString() : null,
          'languages': languages,
          'agency': userType == 'Agency' ? null : (profile['agency_name'] as String?),
          'profileData': profile,
        };
      }).toList();

      
      results = _applyFilters(
        results, 
        query: query, 
        wilayas: wilayas,
        minRating: minRating,
        maxRating: maxRating,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      emit(SearchLoaded(
        results: results,
        searchQuery: query,
        locationFilter: wilayas?.join(', '),
        ratingFilter: minRating != null || maxRating != null
            ? '${minRating ?? 0.0}-${maxRating ?? 5.0}'
            : null,
        priceFilter: minPrice != null || maxPrice != null
            ? '${minPrice ?? 0}-${maxPrice ?? "∞"} DZD'
            : null,
      ));
    } catch (e) {
      emit(SearchError('Failed to load search results: $e'));
    }
  }

  
  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> results, {
    String? query,
    List<String>? wilayas,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
  }) {
    var filtered = results;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        final description = (item['description'] as String? ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }

    // Filter by wilayas (multiple selection)
    if (wilayas != null && wilayas.isNotEmpty) {
      filtered = filtered.where((item) {
        final itemLocation = (item['location'] as String? ?? '').toLowerCase();
        // Check if location contains any of the selected wilayas
        return wilayas.any((wilaya) => 
          itemLocation.contains(wilaya.toLowerCase())
        );
      }).toList();
    }

    // Filter by rating range
    if (minRating != null || maxRating != null) {
      filtered = filtered.where((item) {
        final itemRating = (item['rating'] as num? ?? 0.0).toDouble();
        if (minRating != null && itemRating < minRating) return false;
        if (maxRating != null && itemRating > maxRating) return false;
        return true;
      }).toList();
    }

    // Filter by price range
    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((item) {
        // Extract price from hourly_rate or price field
        final priceStr = item['price'] as String? ?? '';
        // Try to extract numeric value (e.g., "From 2500 DZD/hr" -> 2500)
        final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(priceStr);
        if (priceMatch == null) return true; // Include if can't parse
        
        final itemPrice = double.tryParse(priceMatch.group(1) ?? '');
        if (itemPrice == null) return true;
        
        if (minPrice != null && itemPrice < minPrice) return false;
        if (maxPrice != null && itemPrice > maxPrice) return false;
        return true;
      }).toList();
    }

    return filtered;
  }

  
  String _extractLocation(String? address) {
    if (address == null || address.isEmpty) return 'Unknown';
    
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  Future<void> refresh({
    String? query,
    List<String>? wilayas,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
  }) async {
    await loadSearchResults(
      query: query,
      wilayas: wilayas,
      minRating: minRating,
      maxRating: maxRating,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}

