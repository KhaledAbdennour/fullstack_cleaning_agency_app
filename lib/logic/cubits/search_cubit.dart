import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../utils/algerian_addresses.dart';
import '../../data/repositories/cleaner_reviews/cleaner_reviews_repo.dart';
import '../../core/utils/firestore_type.dart';
import '../../core/config/firebase_config.dart';
import '../../core/services/crashlytics_service.dart';

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
  final AbstractCleanerReviewsRepo _reviewsRepo =
      AbstractCleanerReviewsRepo.getInstance();

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

      final cleanersAndAgencies = allProfiles.where((profile) {
        final profileUserType = (profile['user_type'] as String?)?.trim();

        if (profileUserType == null || profileUserType.isEmpty) return false;
        if (profileUserType.toLowerCase() == 'client') return false;

        if (userType != null && userType.isNotEmpty) {
          return profileUserType == userType;
        }

        return true;
      }).toList();

      print('[SearchCubit] Total profiles: ${allProfiles.length}');
      print('[SearchCubit] Non-client profiles: ${cleanersAndAgencies.length}');

      final profileIds = cleanersAndAgencies
          .map((p) => readInt(p['id']))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      final reviewsCountMap = <int, int>{};
      final ratingsMap = <int, double>{};

      if (profileIds.isNotEmpty) {
        try {
          for (final profileId in profileIds) {
            try {
              final reviewCount = await _reviewsRepo.getReviewCountForCleaner(
                profileId,
              );
              final avgRating = await _reviewsRepo.getAverageRatingForCleaner(
                profileId,
              );
              reviewsCountMap[profileId] = reviewCount;
              ratingsMap[profileId] = avgRating;
            } catch (e) {
              reviewsCountMap[profileId] = 0;
              ratingsMap[profileId] = 0.0;
            }
          }
        } catch (e) {
          print('Error querying reviews: $e');
        }
      }

      final cleanerAgencyMap = <int, int>{};
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

        String? cleanerAgencyName;
        if (userType == 'Individual Cleaner' && profileId != null) {
          final agencyId = cleanerAgencyMap[profileId];
          if (agencyId != null) {
            cleanerAgencyName = agencyNamesMap[agencyId];
          }
        }

        final rating = profileId != null && ratingsMap.containsKey(profileId)
            ? ratingsMap[profileId]!
            : ((profile['rating_avg'] as num?)?.toDouble() ??
                (profile['rating'] as num?)?.toDouble() ??
                0.0);

        final reviewsCount =
            profileId != null && reviewsCountMap.containsKey(profileId)
                ? reviewsCountMap[profileId]!
                : (profile['rating_count'] as int? ??
                    profile['reviews_count'] as int? ??
                    0);

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
          'price': hourlyRate?.toString(),
          'rating': rating,
          'reviews': reviewsCount,
          'image': profile['picture'] as String?,
          'isVerified': profile['is_verified'] as bool? ?? false,
          'type': userType == 'Agency' ? 'Agency' : 'Individual',
          'userType': userType,
          'aboutMe': bio ?? '',
          'experience':
              experienceYears != null ? '$experienceYears+ Years' : null,
          'experience_level': experienceLevel,
          'services': services,
          'age': age?.toString(),
          'languages': languages,
          'agency': userType == 'Agency'
              ? null
              : (cleanerAgencyName ?? profile['agency_name'] as String?),
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

      emit(
        SearchLoaded(
          results: results,
          searchQuery: query,
          locationFilter: wilayas?.join(', '),
          ratingFilter: minRating != null || maxRating != null
              ? '${minRating ?? 0.0}-${maxRating ?? 5.0}'
              : null,
          priceFilter: minPrice != null || maxPrice != null
              ? '${minPrice ?? 0}-${maxPrice ?? "∞"} DZD'
              : null,
        ),
      );
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace,
          reason: 'Failed to load search results');
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

    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        final description =
            (item['description'] as String? ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }

    if (wilayas != null && wilayas.isNotEmpty) {
      filtered = filtered.where((item) {
        final itemLocation = (item['location'] as String? ?? '').toLowerCase();

        return wilayas.any(
          (wilaya) => itemLocation.contains(wilaya.toLowerCase()),
        );
      }).toList();
    }

    if (minRating != null || maxRating != null) {
      filtered = filtered.where((item) {
        final itemRating = (item['rating'] as num? ?? 0.0).toDouble();
        if (minRating != null && itemRating < minRating) return false;
        if (maxRating != null && itemRating > maxRating) return false;
        return true;
      }).toList();
    }

    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((item) {
        final priceStr = item['price'] as String? ?? '';

        final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(priceStr);
        if (priceMatch == null) return true;

        final itemPrice = double.tryParse(priceMatch.group(1) ?? '');
        if (itemPrice == null) return true;

        if (minPrice != null && itemPrice < minPrice) return false;
        if (maxPrice != null && itemPrice > maxPrice) return false;
        return true;
      }).toList();
    }

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

    final wilaya = AlgerianAddresses.extractWilaya(address);
    if (wilaya == null) {
      final parts = address.split(',');
      return parts.isNotEmpty ? parts.first.trim() : address;
    }

    final baladiya = AlgerianAddresses.extractBaladiya(address, wilaya);

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
