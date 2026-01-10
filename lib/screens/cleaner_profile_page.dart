import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/age_helper.dart';
import '../core/utils/firestore_type.dart';
import '../logic/cubits/cleaner_history_cubit.dart';
import '../logic/cubits/cleaner_reviews_cubit.dart';
import '../data/models/cleaning_history_item.dart';
import '../data/models/cleaner_review.dart';
import '../data/repositories/cleaner_reviews/cleaner_reviews_repo.dart';
import '../widgets/notification_bell_widget.dart';
import '../l10n/app_localizations.dart';
import '../utils/image_helper.dart';
import 'homescreen.dart';
import 'settings_page.dart';

class CleanerProfilePage extends StatefulWidget {
  final Map<String, dynamic> cleaner;
  final bool isOwnProfile;
  final bool hideBars;

  CleanerProfilePage({
    super.key, 
    required this.cleaner,
    this.isOwnProfile = false,
    this.hideBars = false,
  });

  @override
  State<CleanerProfilePage> createState() => _CleanerProfilePageState();
}

class _CleanerProfilePageState extends State<CleanerProfilePage> {
  int _selectedTab = 0; 
  int? _cleanerId;
  double _rating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    // Use safe type helper to get cleaner ID
    _cleanerId = readInt(widget.cleaner['id']);
    
    _loadRating();
    if (_cleanerId != null) {
      // Load history and reviews when tab is selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _cleanerId != null) {
          context.read<CleanerHistoryCubit>().loadHistory(_cleanerId!);
          context.read<CleanerReviewsCubit>().loadReviews(_cleanerId!);
        }
      });
    }
  }

  Future<void> _loadRating() async {
    if (_cleanerId == null) {
      // Fallback to profile rating or default to 0.0
      final profileRating = widget.cleaner['rating'] as num?;
      setState(() {
        _rating = profileRating?.toDouble() ?? 0.0;
        _reviewCount = widget.cleaner['reviews'] as int? ?? 0;
      });
      return;
    }

    try {
      final reviewsRepo = AbstractCleanerReviewsRepo.getInstance();
      final averageRating = await reviewsRepo.getAverageRatingForCleaner(_cleanerId!);
      final reviewCount = await reviewsRepo.getReviewCountForCleaner(_cleanerId!);
      
      if (mounted) {
        setState(() {
          _rating = averageRating;
          _reviewCount = reviewCount;
        });
      }
    } catch (e) {
      // Fallback to profile rating or default to 0.0
      final profileRating = widget.cleaner['rating'] as num?;
      if (mounted) {
        setState(() {
          _rating = profileRating?.toDouble() ?? 0.0;
          _reviewCount = widget.cleaner['reviews'] as int? ?? 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: widget.isOwnProfile ? null : (widget.hideBars ? _buildAgencyAppBar() : _buildClientAppBar()),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: _buildProfileImage(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.cleaner['name'] as String? ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_rating.toStringAsFixed(1)} ($_reviewCount ${AppLocalizations.of(context)!.reviews})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.cleaner['isVerified'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
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
            ),
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTab(AppLocalizations.of(context)!.overview, 0),
                  _buildTab(AppLocalizations.of(context)!.history, 1),
                  _buildTab(AppLocalizations.of(context)!.reviews, 2),
                ],
              ),
            ),
            _buildTabContent(),
          ],
        ),
      ),
      bottomNavigationBar: (widget.isOwnProfile || widget.hideBars) ? null : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF3B82F6),
            unselectedItemColor: Colors.grey,
            currentIndex: 1, // Search tab is highlighted since we're viewing a cleaner profile
            onTap: (index) {
              // Pop back to HomeScreen and navigate to the correct tab
              if (Navigator.of(context).canPop()) {
                // Pop back to HomeScreen
                Navigator.of(context).pop();
                
                // Wait a moment for navigation to complete, then replace with HomeScreen at correct tab
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    // Replace current route with HomeScreen at the correct tab
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(initialTabIndex: index),
                      ),
                    );
                  }
                });
              } else {
                // No route to pop, push HomeScreen with correct tab
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(initialTabIndex: index),
                  ),
                  (route) => false,
                );
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: AppLocalizations.of(context)!.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search),
                label: AppLocalizations.of(context)!.search,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                label: 'My Posts',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: AppLocalizations.of(context)!.profile,
              ),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildAgencyAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.eco,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'CleanSpace',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        NotificationBellWidget(),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF6B7280)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
          tooltip: AppLocalizations.of(context)!.settings,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildClientAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.eco,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CleanSpace',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          NotificationBellWidget(),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          // Load data when tab is selected
          if (_cleanerId != null) {
            if (index == 1) {
              context.read<CleanerHistoryCubit>().loadHistory(_cleanerId!);
            } else if (index == 2) {
              context.read<CleanerReviewsCubit>().loadReviews(_cleanerId!);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildReviewsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.aboutMe,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.cleaner['aboutMe'] ?? 
            'With over 5 years of experience, I am a dedicated and meticulous cleaner passionate about creating spotless and healthy environments for my clients. My commitment is to provide excellent, reliable service every time.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.work_history,
                  label: AppLocalizations.of(context)!.experience,
                  value: _getExperienceDisplay(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.cake_outlined,
                  label: AppLocalizations.of(context)!.age,
                  value: _getAgeDisplay(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  label: AppLocalizations.of(context)!.location,
                  value: widget.cleaner['location'] ?? 'Algiers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.phone,
                  label: AppLocalizations.of(context)!.phone,
                  value: _getPhoneDisplay(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.attach_money_outlined,
                  label: AppLocalizations.of(context)!.hourlyRate,
                  value: _getHourlyRateDisplay(),
                ),
              ),
              if (_hasAgency()) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.business_outlined,
                    label: AppLocalizations.of(context)!.agency,
                    value: _getAgencyDisplay(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.servicesOffered,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _buildServicesList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_cleanerId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(AppLocalizations.of(context)!.cleanerIdNotFound)),
      );
    }

    return BlocBuilder<CleanerHistoryCubit, CleanerHistoryState>(
      builder: (context, state) {
        if (state is CleanerHistoryLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          );
        }

        if (state is CleanerHistoryError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is CleanerHistoryLoaded) {
          final historyItems = state.items;

          if (historyItems.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noCleaningHistoryYet,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.cleaningHistory,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                ...historyItems.map((item) => _buildHistoryCard(item)),
                const SizedBox(height: 80),
              ],
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                  item.title ?? AppLocalizations.of(context)!.cleaningJob,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_cleanerId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(AppLocalizations.of(context)!.cleanerIdNotFound)),
      );
    }

    return BlocBuilder<CleanerReviewsCubit, CleanerReviewsState>(
      builder: (context, state) {
        if (state is CleanerReviewsLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          );
        }

        if (state is CleanerReviewsError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is CleanerReviewsLoaded) {
          final reviews = state.filteredReviews;

          if (reviews.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No reviews available',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.allReviews,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                ...reviews.map((review) => _buildReviewCard(review)),
                const SizedBox(height: 80),
              ],
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(review.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${'⭐' * review.rating.floor()}${'☆' * (5 - review.rating.floor())}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          if (review.hasPhotos && review.photoUrls != null && review.photoUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.photoUrls!.take(4).map((photoUrl) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Color(0xFF9CA3AF));
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String service,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            service,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = widget.cleaner['image'] as String? ?? widget.cleaner['picture'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return AppImage(
        imageUrl: imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorWidget: const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF)),
      );
    }
    return const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF));
  }

  String _getAgeDisplay() {
    // Try to get birthdate from profileData first, then fallback to direct cleaner data
    final profileData = widget.cleaner['profileData'] as Map<String, dynamic>?;
    final birthdate = profileData?['birthdate'] as String? ?? widget.cleaner['birthdate'] as String?;
    
    if (birthdate != null && birthdate.isNotEmpty) {
      final age = AgeHelper.calculateAge(birthdate);
      if (age != null) {
        return '$age years';
      }
    }
    
    // Fallback to age field if birthdate calculation fails
    final ageString = widget.cleaner['age'] as String?;
    if (ageString != null && ageString.isNotEmpty) {
      return '$ageString years';
    }
    
    return 'N/A';
  }

  String _getPhoneDisplay() {
    // Try to get phone from profileData first, then fallback to direct cleaner data
    final profileData = widget.cleaner['profileData'] as Map<String, dynamic>?;
    final phone = profileData?['phone'] as String? ?? widget.cleaner['phone'] as String?;
    
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    
    return 'N/A';
  }

  String _getExperienceDisplay() {
    // Try to get experience_level from profileData first, then fallback to direct cleaner data
    final profileData = widget.cleaner['profileData'] as Map<String, dynamic>?;
    final experienceLevel = profileData?['experience_level'] as String? ?? widget.cleaner['experience_level'] as String?;
    
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      // Capitalize first letter
      return experienceLevel[0].toUpperCase() + experienceLevel.substring(1).toLowerCase();
    }
    
    // Fallback to experience years if available
    final experienceYears = widget.cleaner['experience'] as String?;
    if (experienceYears != null && experienceYears.isNotEmpty) {
      return experienceYears;
    }
    
    return 'N/A';
  }

  String _getHourlyRateDisplay() {
    // Try to get hourly_rate from profileData first, then fallback to direct cleaner data
    final profileData = widget.cleaner['profileData'] as Map<String, dynamic>?;
    final hourlyRate = profileData?['hourly_rate'] as String? ?? 
                      widget.cleaner['hourly_rate'] as String? ??
                      profileData?['hourlyRate'] as String? ??
                      widget.cleaner['hourlyRate'] as String?;
    
    if (hourlyRate != null && hourlyRate.isNotEmpty) {
      // Format as "XXX DZD/hr" if it's a number
      final rateValue = double.tryParse(hourlyRate);
      if (rateValue != null) {
        return '${rateValue.toStringAsFixed(0)} DZD/hr';
      }
      return hourlyRate;
    }
    
    return AppLocalizations.of(context)!.contactForPricing;
  }

  bool _hasAgency() {
    // Check if cleaner has an agency
    final agency = widget.cleaner['agency'] as String?;
    return agency != null && agency.isNotEmpty;
  }

  String _getAgencyDisplay() {
    // Try to get agency from cleaner data
    final agency = widget.cleaner['agency'] as String?;
    
    if (agency != null && agency.isNotEmpty) {
      return agency;
    }
    
    return '';
  }

  Widget _buildServicesList() {
    // Try to get services from profileData first, then fallback to direct cleaner data
    final profileData = widget.cleaner['profileData'] as Map<String, dynamic>?;
    final servicesString = profileData?['services'] as String? ?? widget.cleaner['services'] as String?;
    
    if (servicesString == null || servicesString.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No services listed',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    // Split comma-separated services
    final services = servicesString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No services listed',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    // Map service names to icons
    IconData getServiceIcon(String service) {
      final lowerService = service.toLowerCase();
      if (lowerService.contains('home') || lowerService.contains('residential')) {
        return Icons.home_outlined;
      } else if (lowerService.contains('office')) {
        return Icons.business_outlined;
      } else if (lowerService.contains('industrial')) {
        return Icons.factory_outlined;
      } else if (lowerService.contains('specialty') || lowerService.contains('special')) {
        return Icons.cleaning_services_outlined;
      }
      return Icons.cleaning_services_outlined;
    }
    
    return Column(
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildServiceItem(
            icon: getServiceIcon(service),
            service: service,
          ),
        );
      }).toList(),
    );
  }
}
