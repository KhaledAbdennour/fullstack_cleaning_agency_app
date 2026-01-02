import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/cleaner_history_cubit.dart';
import '../logic/cubits/cleaner_reviews_cubit.dart';
import '../data/models/cleaning_history_item.dart';
import '../data/models/cleaner_review.dart';


class CleanerSelfProfilePage extends StatefulWidget {
  const CleanerSelfProfilePage({super.key});

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
    _innerTabController = TabController(length: 3, vsync: this);
    _innerTabController.addListener(_handleInnerTabChange);
    _loadCleanerProfile();
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
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      final user = state.currentUser!;
      setState(() {
        _cleanerId = user['id'] as int?;
        _cleanerProfile = user;
      });
      if (_cleanerId != null) {
        
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cleanerName = _cleanerProfile!['full_name'] as String? ?? 'Cleaner';
    final rating = 4.8; 
    final reviewCount = 23; 

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          
          _buildHeader(cleanerName, rating, reviewCount),
          
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
          
          _buildBottomActionBar(),
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
          
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: _cleanerProfile!['profile_picture'] != null
                ? NetworkImage(_cleanerProfile!['profile_picture'] as String)
                : null,
            child: _cleanerProfile!['profile_picture'] == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
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
                'Part of ${_cleanerProfile!['agency_name']}',
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
                '$rating ($reviewCount Reviews)',
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
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
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'History'),
          Tab(text: 'Reviews'),
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
          
          const Text(
            'About Me',
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
                child: _buildInfoCard(Icons.work_outline, 'Experience', experience),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.person_outline, 'Age', '28'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(Icons.location_on_outlined, 'Location', location.split(',').first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.language_outlined, 'Languages', languages),
              ),
            ],
          ),
          const SizedBox(height: 24),

          
          const Text(
            'Services Offered',
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
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<CleanerHistoryCubit, CleanerHistoryState>(
      builder: (context, state) {
        if (state is CleanerHistoryLoading && state is! CleanerHistoryLoaded) {
          return const Center(child: CircularProgressIndicator());
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is CleanerHistoryLoaded) {
          if (state.items.isEmpty) {
            return const Center(
              child: Text(
                'No cleaning history yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(state.items[index]);
                  },
                ),
              ),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CleanerHistoryCubit>().loadMore(_cleanerId!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Load More'),
                  ),
                ),
            ],
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
                  item.type.displayName,
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
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<CleanerReviewsCubit, CleanerReviewsState>(
      builder: (context, state) {
        if (state is CleanerReviewsLoading && state is! CleanerReviewsLoaded) {
          return const Center(child: CircularProgressIndicator());
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is CleanerReviewsLoaded) {
          return Column(
            children: [
              
              _buildReviewsFilters(state),
              
              Expanded(
                child: state.filteredReviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No reviews found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredReviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(state.filteredReviews[index]);
                        },
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReviewsFilters(CleanerReviewsLoaded state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSortDialog(state),
                  icon: const Icon(Icons.sort, size: 16),
                  label: Text('Sort by: ${state.sortBy == 'recency' ? 'Recency' : state.sortBy == 'highest' ? 'Highest Rating' : 'Lowest Rating'}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              ElevatedButton.icon(
                onPressed: () {
                  
                },
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: [
              _buildRatingChip(state, 5),
              _buildRatingChip(state, 4),
              _buildRatingChip(state, 3),
              _buildPhotosChip(state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(CleanerReviewsLoaded state, int rating) {
    final isSelected = state.ratingFilter == rating;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text('$rating'),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        context.read<CleanerReviewsCubit>().updateRatingFilter(
          selected ? rating : null,
          _cleanerId!,
        );
      },
      selectedColor: Colors.blue[50],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildPhotosChip(CleanerReviewsLoaded state) {
    return FilterChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt, size: 16),
          SizedBox(width: 4),
          Text('With Photos'),
        ],
      ),
      selected: state.withPhotosOnly,
      onSelected: (selected) {
        context.read<CleanerReviewsCubit>().togglePhotosFilter(selected, _cleanerId!);
      },
      selectedColor: Colors.blue[50],
      checkmarkColor: Colors.blue,
    );
  }

  void _showSortDialog(CleanerReviewsLoaded state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Recency'),
              trailing: state.sortBy == 'recency' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<CleanerReviewsCubit>().updateSort('recency', _cleanerId!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Highest Rating'),
              trailing: state.sortBy == 'highest' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<CleanerReviewsCubit>().updateSort('highest', _cleanerId!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Lowest Rating'),
              trailing: state.sortBy == 'lowest' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<CleanerReviewsCubit>().updateSort('lowest', _cleanerId!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
              
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Text(
                  review.reviewerName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.grey),
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
              return Icon(
                Icons.star,
                size: 16,
                color: index < review.rating.floor()
                    ? Colors.amber
                    : Colors.grey[300],
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat feature coming soon')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking feature coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

