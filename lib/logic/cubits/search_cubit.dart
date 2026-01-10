import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../utils/algerian_addresses.dart';
import '../../data/repositories/cleaner_reviews/cleaner_reviews_repo.dart';
import '../../core/utils/firestore_type.dart';
import '../../core/config/firebase_config.dart';



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
  final AbstractCleanerReviewsRepo _reviewsRepo = AbstractCleanerReviewsRepo.getInstance();

  SearchCubit() : super(SearchInitial());

  
  Future<void> loadSearchResults({
    String? query,
    List<String>? wilayas,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
    String? userType,
  }) async {
    emit(SearchLoading());
    try {
      
      final allProfiles = await _profileRepo.getAllProfiles();
      // Filter out clients - show all non-client profiles (cleaners, agencies, etc.)
      // Also filter by userType if specified
      final cleanersAndAgencies = allProfiles.where((profile) {
        final profileUserType = (profile['user_type'] as String?)?.trim();
        // Show all profiles that are NOT clients (case-insensitive check)
        if (profileUserType == null || profileUserType.isEmpty) return false;
        if (profileUserType.toLowerCase() == 'client') return false;
        
        // Filter by userType if specified
        if (userType != null && userType.isNotEmpty) {
          return profileUserType == userType;
        }
        
        return true;
      }).toList();
      
      print('📊 [SearchCubit] Total profiles: ${allProfiles.length}');
      print('📊 [SearchCubit] Non-client profiles: ${cleanersAndAgencies.length}');

      
      // Get profile IDs to query reviews in batch
      final profileIds = cleanersAndAgencies
          .map((p) => readInt(p['id']))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      
      // Query reviews for all profiles at once (more efficient)
      final reviewsCountMap = <int, int>{};
      final ratingsMap = <int, double>{};
      
      // Query cleaner_reviews collection for all cleaner IDs
      if (profileIds.isNotEmpty) {
        try {
          // Query reviews for each profile (we'll optimize this if needed)
          for (final profileId in profileIds) {
            try {
              final reviewCount = await _reviewsRepo.getReviewCountForCleaner(profileId);
              final avgRating = await _reviewsRepo.getAverageRatingForCleaner(profileId);
              reviewsCountMap[profileId] = reviewCount;
              ratingsMap[profileId] = avgRating;
            } catch (e) {
              // If query fails, use aggregate from profile
              reviewsCountMap[profileId] = 0;
              ratingsMap[profileId] = 0.0;
            }
          }
        } catch (e) {
          // If batch query fails, fall back to aggregates
          print('Error querying reviews: $e');
        }
      }

      // Check which Individual Cleaners belong to agencies (from cleaners collection)
      final cleanerAgencyMap = <int, int>{}; // Map cleaner profile ID to agency ID
      try {
        final cleanersSnapshot = await FirebaseConfig.firestore
            .collection('cleaners')
            .where('is_active', isEqualTo: true)
            .get();
        
        for (final doc in cleanersSnapshot.docs) {
          final data = doc.data();
          final cleanerProfileId = readInt(data['id']);
          final agencyId = readInt(data['agency_id']);
          if (cleanerProfileId != null && agencyId != null) {
            cleanerAgencyMap[cleanerProfileId] = agencyId;
          }
        }
      } catch (e) {
        print('Error querying cleaners collection: $e');
      }

      // Get agency names for cleaners that belong to agencies
      final agencyNamesMap = <int, String>{};
      if (cleanerAgencyMap.isNotEmpty) {
        final agencyIds = cleanerAgencyMap.values.toSet();
        for (final agencyId in agencyIds) {
          try {
            final agencyProfile = await _profileRepo.getProfileById(agencyId);
            if (agencyProfile != null) {
              final agencyName = agencyProfile['agency_name'] as String? ?? 
                                agencyProfile['full_name'] as String?;
              if (agencyName != null && agencyName.isNotEmpty) {
                agencyNamesMap[agencyId] = agencyName;
              }
            }
          } catch (e) {
            print('Error fetching agency profile for ID $agencyId: $e');
          }
        }
      }
      
      List<Map<String, dynamic>> results = cleanersAndAgencies.map((profile) {
        final userType = profile['user_type'] as String?;
        final agencyName = profile['agency_name'] as String?;
        final fullName = profile['full_name'] as String?;
        final name = userType == 'Agency' 
            ? (agencyName ?? fullName ?? 'Unknown')
            : (fullName ?? 'Unknown');
        
        final profileId = readInt(profile['id']);
        
        // Check if this Individual Cleaner belongs to an agency (from cleaners collection)
        String? cleanerAgencyName;
        if (userType == 'Individual Cleaner' && profileId != null) {
          final agencyId = cleanerAgencyMap[profileId];
          if (agencyId != null) {
            cleanerAgencyName = agencyNamesMap[agencyId];
          }
        }
        
        // Use queried reviews count and rating if available, otherwise fall back to aggregates
        final rating = profileId != null && ratingsMap.containsKey(profileId)
            ? ratingsMap[profileId]!
            : ((profile['rating_avg'] as num?)?.toDouble() 
                ?? (profile['rating'] as num?)?.toDouble() 
                ?? 0.0);
        
        final reviewsCount = profileId != null && reviewsCountMap.containsKey(profileId)
            ? reviewsCountMap[profileId]!
            : (profile['rating_count'] as int? 
                ?? profile['reviews_count'] as int? 
                ?? 0);
        
        final bio = profile['bio'] as String?;
        final experienceYears = profile['experience_years'] as int?;
        final experienceLevel = profile['experience_level'] as String?;
        final age = profile['age'];
        final languages = profile['languages'] as String?;
        final hourlyRate = profile['hourly_rate'];
        final services = profile['services'] as String?;
        
        return {
          'id': profile['id'],
          'name': name,
          'description': bio ?? '',
          'location': _extractLocation(profile['address'] as String?),
          'price': hourlyRate != null 
              ? hourlyRate.toString() // Store just the number, UI will format it
              : null, // UI will handle "Contact for pricing" localization
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
          'experience_level': experienceLevel,
          'services': services,
          'age': age != null ? age.toString() : null,
          'languages': languages,
          'agency': userType == 'Agency' ? null : (cleanerAgencyName ?? profile['agency_name'] as String?),
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
        userType: userType,
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
    String? userType,
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

    // Filter by user type (already filtered in loadSearchResults, but double-check here)
    if (userType != null && userType.isNotEmpty) {
      filtered = filtered.where((item) {
        final itemUserType = item['userType'] as String?;
        return itemUserType == userType;
      }).toList();
    }

    return filtered;
  }

  
  String _extractLocation(String? address) {
    if (address == null || address.isEmpty) return 'Unknown';
    
    // Extract wilaya and baladiya from the address
    final wilaya = AlgerianAddresses.extractWilaya(address);
    if (wilaya == null) {
      // If no wilaya found, return the original address or first part
      final parts = address.split(',');
      return parts.isNotEmpty ? parts.first.trim() : address;
    }
    
    // Try to extract baladiya for the found wilaya
    final baladiya = AlgerianAddresses.extractBaladiya(address, wilaya);
    
    // Format: "Wilaya, Baladiya" if baladiya exists, otherwise just "Wilaya"
    if (baladiya != null && baladiya.isNotEmpty) {
      return '$wilaya, $baladiya';
    } else {
      return wilaya;
    }
  }

  Future<void> refresh({
    String? query,
    List<String>? wilayas,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
    String? userType,
  }) async {
    await loadSearchResults(
      query: query,
      wilayas: wilayas,
      minRating: minRating,
      maxRating: maxRating,
      minPrice: minPrice,
      maxPrice: maxPrice,
      userType: userType,
    );
  }
}

