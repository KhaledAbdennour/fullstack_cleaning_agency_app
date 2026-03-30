import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/agency_dashboard_cubit.dart';
import '../logic/cubits/search_cubit.dart';
import '../data/repositories/cleaners/cleaners_repo.dart';
import '../data/models/cleaner_model.dart';
import '../l10n/app_localizations.dart';
import '../utils/image_helper.dart';
import '../utils/age_helper.dart';
import '../data/repositories/profiles/profile_repo.dart';
import 'cleaner_profile_page.dart';

class CleanerTeamPage extends StatefulWidget {
  final int agencyId;

  const CleanerTeamPage({super.key, required this.agencyId});

  @override
  State<CleanerTeamPage> createState() => _CleanerTeamPageState();
}

class _CleanerTeamPageState extends State<CleanerTeamPage> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _teamCleanerIds = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CleanerTeamCubit>().loadCleaners(widget.agencyId);
        context.read<SearchCubit>().loadSearchResults(
              userType: 'Individual Cleaner',
            );
        _loadTeamCleanerIds();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final query = _searchController.text.trim();
        setState(() {
          _isSearching = query.isNotEmpty;
        });
        if (query.isNotEmpty) {
          context.read<SearchCubit>().loadSearchResults(
                query: query,
                userType: 'Individual Cleaner',
              );
        }
      }
    });
  }

  Future<void> _loadTeamCleanerIds() async {
    try {
      final cleanersRepo = AbstractCleanersRepo.getInstance();
      final cleaners = await cleanersRepo.getCleanersForAgency(widget.agencyId);
      if (mounted) {
        setState(() {
          _teamCleanerIds =
              cleaners.map((c) => c.id ?? 0).where((id) => id != 0).toList();
        });
      }
    } catch (e) {
      print('Error loading team cleaner IDs: $e');
    }
  }

  Future<void> _removeCleanerFromTeam(int cleanerId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.removeCleaner),
          content: Text(AppLocalizations.of(context)!.areYouSureRemoveCleaner),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.remove),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      final cleanersRepo = AbstractCleanersRepo.getInstance();
      await cleanersRepo.removeCleaner(cleanerId);

      if (mounted) {
        context.read<CleanerTeamCubit>().refresh(widget.agencyId);
        await _loadTeamCleanerIds();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cleanerRemovedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorRemovingCleaner}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCleanerToTeam(Map<String, dynamic> profile) async {
    try {
      final cleanerId = profile['id'] as int?;
      if (cleanerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidProfile),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cleanersRepo = AbstractCleanersRepo.getInstance();
      final existingCleaners = await cleanersRepo.getCleanersForAgency(
        widget.agencyId,
      );
      if (!mounted) return;

      if (existingCleaners.any((c) => c.id == cleanerId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.cleanerAlreadyInTeam),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final cleaner = Cleaner(
        name: profile['full_name'] as String? ?? 'Unknown',
        avatarUrl: profile['picture'] as String?,
        rating: (profile['rating'] as num?)?.toDouble() ?? 0.0,
        jobsCompleted: 0,
        agencyId: widget.agencyId,
        isActive: true,
      );

      await cleanersRepo.addCleaner(cleaner);

      if (mounted) {
        context.read<CleanerTeamCubit>().refresh(widget.agencyId);
        await _loadTeamCleanerIds();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cleanerAddedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorAddingCleaner}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.cleanerTeam,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                )!
                    .searchForCleaningServices,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildTeamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList() {
    return BlocBuilder<CleanerTeamCubit, CleanerTeamState>(
      builder: (context, state) {
        if (state is CleanerTeamLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        } else if (state is CleanerTeamError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<CleanerTeamCubit>().refresh(widget.agencyId);
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is CleanerTeamLoaded) {
          if (state.cleaners.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noCleanersInTeamYet,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<CleanerTeamCubit>().refresh(widget.agencyId);
              await _loadTeamCleanerIds();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.cleaners.length,
              itemBuilder: (context, index) {
                return _buildCleanerCard(state.cleaners[index], isInTeam: true);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        } else if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<SearchCubit>().loadSearchResults(
                          query: _searchController.text.trim(),
                          userType: 'Individual Cleaner',
                        );
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is SearchLoaded) {
          final availableCleaners = state.results.where((cleaner) {
            final cleanerId = cleaner['id'] as int?;
            return cleanerId != null && !_teamCleanerIds.contains(cleanerId);
          }).toList();

          if (availableCleaners.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noCleanersFound,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableCleaners.length,
            itemBuilder: (context, index) {
              return _buildSearchResultCard(availableCleaners[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner, {bool isInTeam = false}) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: cleaner.id != null
          ? AbstractProfileRepo.getInstance().getProfileById(cleaner.id!)
          : Future.value(null),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?['full_name'] as String? ?? cleaner.name;
        final description = profile?['bio'] as String? ?? '';
        final location = _extractLocation(profile?['address'] as String?);
        final priceValue = profile?['hourly_rate'] as String?;
        final price = priceValue != null && priceValue.isNotEmpty
            ? AppLocalizations.of(context)!.fromDzdPerHr(priceValue)
            : AppLocalizations.of(context)!.contactForPricing;
        final rating = cleaner.rating;
        final reviews = profile?['reviews_count'] as int? ?? 0;
        final imageUrl = profile?['picture'] as String? ?? cleaner.avatarUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6),
                    ),
                    child: ClipOval(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? AppImage(
                              imageUrl: imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${rating.toStringAsFixed(1)} ($reviews ${AppLocalizations.of(context)!.reviews})',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (cleaner.id != null) {
                      final profileRepo = AbstractProfileRepo.getInstance();
                      try {
                        final profileData = await profileRepo.getProfileById(
                          cleaner.id!,
                        );
                        if (profileData != null && mounted) {
                          final cleanerProfile = {
                            'id': profileData['id'],
                            'name': profileData['full_name'] as String? ??
                                cleaner.name,
                            'image': profileData['picture'] as String? ??
                                cleaner.avatarUrl,
                            'rating': cleaner.rating,
                            'reviews':
                                profileData['reviews_count'] as int? ?? 0,
                            'isVerified':
                                profileData['is_verified'] as bool? ?? false,
                            'aboutMe': profileData['bio'] as String? ??
                                'Professional cleaning service provider.',
                            'experience': profileData['experience_years'] !=
                                    null
                                ? '${profileData['experience_years']}+ Years'
                                : '5+ Years',
                            'age': AgeHelper.formatAge(
                              profileData['birthdate'] as String?,
                            ),
                            'languages': profileData['languages'] as String? ??
                                'Arabic, French',
                            'location': _extractLocation(
                              profileData['address'] as String?,
                            ),
                            'type': 'Individual',
                            'userType': profileData['user_type'],
                            'profileData': profileData,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CleanerProfilePage(
                                cleaner: cleanerProfile,
                                isOwnProfile: false,
                                hideBars: true,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error loading cleaner profile: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.viewProfile,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    if (cleaner.id != null) {
                      await _removeCleanerFromTeam(cleaner.id!);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.remove,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> cleaner) {
    final name = cleaner['name'] as String? ?? 'Unknown';
    final description = cleaner['description'] as String? ?? '';
    final location = cleaner['location'] as String? ?? 'Unknown';
    final price = cleaner['price'] as String? ??
        AppLocalizations.of(context)!.contactForPricing;
    final rating = cleaner['rating'] as num? ?? 0.0;
    final reviews = cleaner['reviews'] as int? ?? 0;
    final imageUrl = cleaner['image'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? AppImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person, size: 30, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 18,
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviews ${AppLocalizations.of(context)!.reviews})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final profileRepo = AbstractProfileRepo.getInstance();
                try {
                  final cleanerId = cleaner['id'] as int?;
                  if (cleanerId != null) {
                    final profileData = await profileRepo.getProfileById(
                      cleanerId,
                    );
                    if (profileData != null && mounted) {
                      final cleanerProfile = {
                        'id': profileData['id'],
                        'name': profileData['full_name'] as String? ?? name,
                        'image': profileData['picture'] as String? ?? imageUrl,
                        'rating': rating.toDouble(),
                        'reviews':
                            profileData['reviews_count'] as int? ?? reviews,
                        'isVerified':
                            profileData['is_verified'] as bool? ?? false,
                        'aboutMe': profileData['bio'] as String? ?? description,
                        'experience': profileData['experience_years'] != null
                            ? '${profileData['experience_years']}+ Years'
                            : '5+ Years',
                        'age': AgeHelper.formatAge(
                          profileData['birthdate'] as String?,
                        ),
                        'languages': profileData['languages'] as String? ??
                            'Arabic, French',
                        'location': _extractLocation(
                          profileData['address'] as String?,
                        ),
                        'type': 'Individual',
                        'userType': profileData['user_type'],
                        'profileData': profileData,
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CleanerProfilePage(
                            cleaner: cleanerProfile,
                            isOwnProfile: false,
                            hideBars: true,
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error loading cleaner profile: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.viewProfile,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final cleanerId = cleaner['id'] as int?;
                if (cleanerId != null) {
                  final profileRepo = AbstractProfileRepo.getInstance();
                  try {
                    final profileData = await profileRepo.getProfileById(
                      cleanerId,
                    );
                    if (profileData != null && mounted) {
                      await _addCleanerToTeam(profileData);
                      await _loadTeamCleanerIds();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.addToTeam,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractLocation(String? address) {
    if (address == null || address.isEmpty) return 'Unknown';
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }
}
