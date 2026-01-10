import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/cleaner_history_cubit.dart';
import '../logic/cubits/cleaner_reviews_cubit.dart';
import '../data/models/cleaning_history_item.dart';
import '../data/models/cleaner_review.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/image_helper.dart';
import '../l10n/app_localizations.dart';
import 'EditProfilePage.dart';


class CleanerSelfProfilePage extends StatefulWidget {
  final int? initialTab; // 0=Overview, 1=History, 2=Reviews
  
  const CleanerSelfProfilePage({super.key, this.initialTab});

  @override
  State<CleanerSelfProfilePage> createState() => _CleanerSelfProfilePageState();
}

class _CleanerSelfProfilePageState extends State<CleanerSelfProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;
  int? _cleanerId;
  Map<String, dynamic>? _cleanerProfile;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _innerTabController.addListener(_handleInnerTabChange);
    _loadCleanerProfile();
    
    // If initialTab is provided, ensure tab is set after first frame
    if (widget.initialTab != null && widget.initialTab! < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_innerTabController.indexIsChanging) {
          _innerTabController.animateTo(widget.initialTab!);
        }
      });
    }
  }

  void _handleInnerTabChange() {
    if (!_innerTabController.indexIsChanging && _cleanerId != null) {
      switch (_innerTabController.index) {
        case 1: 
          context.read<CleanerHistoryCubit>().loadHistory(_cleanerId!);
          break;
        case 2: 
          context.read<CleanerReviewsCubit>().loadReviews(_cleanerId!);
          break;
      }
    }
  }

  Future<void> _loadCleanerProfile() async {
    final cubit = context.read<ProfilesCubit>();
    await cubit.loadCurrentUser();
    if (!mounted) return;
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      final user = state.currentUser!;
      setState(() {
        _cleanerId = user['id'] as int?;
        _cleanerProfile = user;
      });
      if (_cleanerId != null && mounted) {
        
        context.read<CleanerHistoryCubit>().loadHistory(_cleanerId!);
        context.read<CleanerReviewsCubit>().loadReviews(_cleanerId!);
      }
    }
  }

  @override
  void dispose() {
    _innerTabController.removeListener(_handleInnerTabChange);
    _innerTabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cleanerProfile == null || _cleanerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    final cleanerName = _cleanerProfile!['full_name'] as String? ?? 'Cleaner';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          
          BlocBuilder<CleanerReviewsCubit, CleanerReviewsState>(
            builder: (context, reviewsState) {
              double rating = 0.0;
              int reviewCount = 0;
              
              if (reviewsState is CleanerReviewsLoaded) {
                rating = reviewsState.averageRating;
                reviewCount = reviewsState.reviewCount;
              }
              
              return _buildHeader(cleanerName, rating, reviewCount);
            },
          ),
          
          _buildInnerTabBar(),
          
          Expanded(
            child: TabBarView(
              controller: _innerTabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, double rating, int reviewCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Edit button at the top right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ).then((_) {
                    // Refresh profile after editing
                    if (mounted) {
                      _loadCleanerProfile();
                    }
                  });
                },
                icon: const Icon(Icons.edit, size: 18),
                label: Text(AppLocalizations.of(context)!.edit),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
          
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: _cleanerProfile!['picture'] != null && (_cleanerProfile!['picture'] as String).isNotEmpty
                ? ClipOval(
                    child: AppImage(
                      imageUrl: _cleanerProfile!['picture'] as String,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_cleanerProfile!['agency_name'] != null)
            GestureDetector(
              onTap: () {
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agency profile coming soon')),
                );
              },
              child: Text(
                  AppLocalizations.of(context)!.partOfAgency(_cleanerProfile!['agency_name'] as String),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '$rating ($reviewCount ${AppLocalizations.of(context)!.reviews})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.verified,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _innerTabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.green,
        indicatorWeight: 3,
        tabs: [
          Tab(text: AppLocalizations.of(context)!.overview),
          Tab(text: AppLocalizations.of(context)!.history),
          Tab(text: AppLocalizations.of(context)!.reviews),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final bio = _cleanerProfile!['bio'] as String? ?? 
        'With over 5 years of experience, I am a dedicated and meticulous cleaner passionate about creating spotless and healthy environments for my clients. My commitment is to provide excellent, reliable service every time.';
    final services = _cleanerProfile!['services'] as String? ?? 'Residential Cleaning, Office Cleaning';
    final experience = '5+ Years'; 
    final languages = 'Arabic, French';
    final location = _cleanerProfile!['address'] as String? ?? 'Algiers';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(
            AppLocalizations.of(context)!.aboutMe,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),

          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(Icons.work_outline, AppLocalizations.of(context)!.experience, experience),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.person_outline, AppLocalizations.of(context)!.age, '28'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(Icons.location_on_outlined, AppLocalizations.of(context)!.location, location.split(',').first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.language_outlined, AppLocalizations.of(context)!.languages, languages),
              ),
            ],
          ),
          const SizedBox(height: 24),

          
          Text(
            AppLocalizations.of(context)!.servicesOffered,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: services.split(',').map((service) {
              return _buildServiceCard(service.trim());
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String service) {
    IconData icon;
    if (service.toLowerCase().contains('residential') || service.toLowerCase().contains('home')) {
      icon = Icons.home_outlined;
    } else if (service.toLowerCase().contains('office')) {
      icon = Icons.business_outlined;
    } else if (service.toLowerCase().contains('deep')) {
      icon = Icons.cleaning_services_outlined;
    } else {
      icon = Icons.work_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            service,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_cleanerId == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    return BlocBuilder<CleanerHistoryCubit, CleanerHistoryState>(
      builder: (context, state) {
        if (state is CleanerHistoryLoading && state is! CleanerHistoryLoaded) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        } else if (state is CleanerHistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<CleanerHistoryCubit>().refresh(_cleanerId!);
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is CleanerHistoryLoaded) {
          if (state.items.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noCleaningHistoryYet,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(state.items[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryCard(CleaningHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.type.iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.type.icon,
              color: item.type.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_cleanerId == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    return BlocBuilder<CleanerReviewsCubit, CleanerReviewsState>(
      builder: (context, state) {
        if (state is CleanerReviewsLoading && state is! CleanerReviewsLoaded) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        } else if (state is CleanerReviewsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<CleanerReviewsCubit>().refresh(_cleanerId!);
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is CleanerReviewsLoaded) {
          if (state.allReviews.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noReviewsYet,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          
          // Sort by recency (most recent first)
          final sortedReviews = List<CleanerReview>.from(state.allReviews);
          sortedReviews.sort((a, b) => b.date.compareTo(a.date));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedReviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(sortedReviews[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }


  Widget _buildReviewCard(CleanerReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              
              FutureBuilder<Map<String, dynamic>?>(
                future: review.reviewerId != null
                    ? AbstractProfileRepo.getInstance().getProfileById(review.reviewerId!)
                    : Future.value(null),
                builder: (context, snapshot) {
                  final reviewerPicture = snapshot.data?['picture'] as String?;
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: reviewerPicture != null && reviewerPicture.isNotEmpty
                        ? ClipOval(
                            child: AppImage(
                              imageUrl: reviewerPicture,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: Text(
                                review.reviewerName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Text(
                            review.reviewerName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                  );
                },
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(review.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: List.generate(5, (index) {
              return Text(
                '☆',
                style: TextStyle(
                  fontSize: 16,
                  color: index < review.rating.floor()
                      ? Colors.amber
                      : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          
          Text(
            review.comment,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          
          if (review.hasPhotos && review.photoUrls != null && review.photoUrls!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: review.photoUrls!.take(3).map((url) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

}

