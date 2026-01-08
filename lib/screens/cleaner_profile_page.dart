import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'jobdetails.dart';
import '../utils/age_helper.dart';
import '../core/utils/firestore_type.dart';
import '../logic/cubits/cleaner_history_cubit.dart';
import '../logic/cubits/cleaner_reviews_cubit.dart';
import '../data/models/cleaning_history_item.dart';
import '../data/models/cleaner_review.dart';
import '../data/repositories/cleaner_reviews/cleaner_reviews_repo.dart';

class CleanerProfilePage extends StatefulWidget {
  final Map<String, dynamic> cleaner;
  final bool isOwnProfile; 

  CleanerProfilePage({
    super.key, 
    required this.cleaner,
    this.isOwnProfile = false,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isOwnProfile, 
        leading: widget.isOwnProfile 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF111827)),
            onPressed: () {},
          ),
        ],
      ),
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
                  if (widget.cleaner['agency'] != null)
                    Text(
                      'Part of ${widget.cleaner['agency']}.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (widget.cleaner['agency'] != null) const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_rating.toStringAsFixed(1)} ($_reviewCount Reviews)',
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
                  _buildTab('Overview', 0),
                  _buildTab('History', 1),
                  _buildTab('Reviews', 2),
                ],
              ),
            ),
            _buildTabContent(),
          ],
        ),
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
          const Text(
            'About Me',
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
                  label: 'Experience',
                  value: widget.cleaner['experience'] ?? '5+ Years',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: (widget.cleaner['age'] as String?) ?? AgeHelper.formatAge((widget.cleaner['profileData'] as Map<String, dynamic>?)?['birthdate'] as String?),
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
                  label: 'Location',
                  value: widget.cleaner['location'] ?? 'Algiers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.language,
                  label: 'Languages',
                  value: widget.cleaner['languages'] ?? 'Arabic, French',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.cleaner['agency'] != null)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                children: [
                  const TextSpan(text: 'Part of '),
                  TextSpan(
                    text: widget.cleaner['agency'],
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          if (widget.cleaner['agency'] != null) const SizedBox(height: 24),
          const Text(
            'Services Offered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _buildServiceItem(
            icon: Icons.home_outlined,
            service: 'Residential Cleaning',
          ),
          const SizedBox(height: 8),
          _buildServiceItem(
            icon: Icons.business_outlined,
            service: 'Office Cleaning',
          ),
          const SizedBox(height: 8),
          _buildServiceItem(
            icon: Icons.cleaning_services_outlined,
            service: 'Deep Cleaning',
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_cleanerId == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Cleaner ID not found')),
      );
    }

    return BlocBuilder<CleanerHistoryCubit, CleanerHistoryState>(
      builder: (context, state) {
        if (state is CleanerHistoryLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
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
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No cleaning history available',
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
                const Text(
                  'Cleaning History',
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
                  item.title ?? 'Cleaning Job',
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
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Cleaner ID not found')),
      );
    }

    return BlocBuilder<CleanerReviewsCubit, CleanerReviewsState>(
      builder: (context, state) {
        if (state is CleanerReviewsLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
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
                const Text(
                  'All Reviews',
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
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF));
        },
      );
    }
    return const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF));
  }
}
