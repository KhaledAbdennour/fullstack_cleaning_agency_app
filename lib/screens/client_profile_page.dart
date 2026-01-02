import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'EditProfilePage.dart';
import 'settings_page.dart';
import 'manage_job_page.dart';
import 'add-post.dart';
import 'jobdetails.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/models/job_model.dart';
import '../utils/image_helper.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({Key? key}) : super(key: key);

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  int _selectedTabIndex = 0;
  int? _clientId;

  @override
  void initState() {
    super.initState();
    _loadClientId();
  }


  Future<void> _loadClientId() async {
    final cubit = context.read<ProfilesCubit>();
    await cubit.loadCurrentUser();
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      final userId = state.currentUser!['id'] as int?;
      final userType = state.currentUser!['user_type'] as String?;
      if (userId != null && userType == 'Client') {
        setState(() {
          _clientId = userId;
        });
        
        context.read<ClientJobsCubit>().loadClientJobs(userId);
      }
    }
  }

  
  final List<Map<String, dynamic>> jobPosts = [
    {
      'title': 'Apartment Cleaning',
      'description': 'Looking for a cleaner for a 2-bedroom apartment.',
      'postedDaysAgo': 2,
      'price': '5000 DZD',
      'date': 'October 26, 2024, 10:00 AM',
      'location': '123 Rue Didouche Mourad, Algiers, Algeria',
      'notes': 'Please focus on the kitchen and bathroom.',
      'client': 'Fatima Zohra',
      'status': 'InProgress',
      'image':
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400',
      'hasApplications': true,
      'applications': [
        {
          'name': "Fatima's Cleaning",
          'price': '5000 DZD',
          'description': 'I have 5 years of experience and can bring my own supplies...',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=fatima',
        },
        {
          'name': 'Ahmed Belkacem',
          'price': '4500 DZD',
          'description': 'Available immediately. I have excellent references.',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=ahmed',
        },
      ],
    },
    {
      'title': 'Office Cleaning',
      'description': 'Weekly cleaning for a small office space.',
      'postedDaysAgo': 5,
      'price': '6500 DZD',
      'date': 'November 2, 2024, 2:00 PM',
      'location': 'Boulevard Amirouche, Algiers, Algeria',
      'notes': 'Focus on meeting rooms and pantry.',
      'client': 'TechHub SARL',
      'status': 'Pending',
      'image':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400',
      'hasApplications': false,
      'applications': [],
    },
  ];

  void _handleEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    
    if (mounted) {
      context.read<ProfilesCubit>().loadCurrentUser();
    }
  }

  void _handleSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _handleViewDetails(Map<String, dynamic> job) {
    
    
  }

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(ClientProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_clientId != null) {
      context.read<ClientJobsCubit>().loadClientJobs(_clientId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF6B7280)),
            onPressed: _handleSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildProfileInfo(),
                const SizedBox(height: 24),
                _buildTabBar(),
                const SizedBox(height: 16),
                _buildTabContent(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), 
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          TextButton(
            onPressed: _handleEditProfile,
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        String displayName = 'New User';
        if (state is ProfilesLoaded && state.currentUser != null) {
          displayName = state.currentUser!['full_name'] as String? ?? 
                       state.currentUser!['username'] as String? ?? 
                       'New User';
        }

        return Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE68A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        bool isIndividualCleaner = false;
        if (state is ProfilesLoaded && state.currentUser != null) {
          final userType = state.currentUser!['user_type'] as String?;
          isIndividualCleaner = userType == 'Individual Cleaner';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              _buildTab('My Posts', 0),
              if (isIndividualCleaner) ...[
                const SizedBox(width: 24),
                _buildTab('History', 1),
                const SizedBox(width: 24),
                _buildTab('Reviews', 2),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        
        if (index == 0 && _clientId != null) {
          context.read<ClientJobsCubit>().refresh(_clientId!);
        }
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildJobPostsList();
    } else if (_selectedTabIndex == 1) {
      return _buildHistoryList();
    } else if (_selectedTabIndex == 2) {
      return _buildReviewsList();
    }
    return _buildJobPostsList();
  }

  Widget _buildJobPostsList() {
    if (_clientId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<ClientJobsCubit, ClientJobsState>(
      builder: (context, state) {
        if (state is ClientJobsLoading && state is! ClientJobsLoaded) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ClientJobsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ClientJobsCubit>().refresh(_clientId!);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is ClientJobsLoaded) {
          if (state.jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No posts yet. Create your first job posting!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: state.jobs.map((job) {
              try {
                
                if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildJobPostCardFromJob(job);
              } catch (e, stackTrace) {
                print('Error building job post card: $e');
                print('Stack trace: $stackTrace');
                return const SizedBox.shrink();
              }
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  
  final List<Map<String, dynamic>> cleaningHistory = [
    {
      'title': 'Office Building',
      'date': 'June 5, 2024',
      'description': 'Standard office cleaning, completed successfully.',
      'icon': Icons.business,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Apartment',
      'date': 'May 20, 2024',
      'description': 'Deep cleaning service for a 3-bedroom apartment.',
      'icon': Icons.apartment,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Villa',
      'date': 'May 10, 2024',
      'description': 'Full-day cleaning for a large villa, including windows.',
      'icon': Icons.villa,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
  ];

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cleaning History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...cleaningHistory.map(_buildHistoryCard).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                
              },
              child: const Text(
                'Load More',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: history['bgColor'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              history['icon'] as IconData,
              color: history['iconColor'] as Color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  history['date'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  history['description'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Amina K.',
      'date': 'June 10, 2024',
      'rating': 5,
      'text': 'Fatima was amazing! She left my apartment sparkling clean. Very professional and friendly.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=amina',
    },
    {
      'name': 'Karim B.',
      'date': 'May 28, 2024',
      'rating': 4,
      'text': 'Great service, very thorough. Would hire again.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=karim',
    },
    {
      'name': 'Yasmine L.',
      'date': 'May 15, 2024',
      'rating': 5,
      'text': 'Excellent work! My house has never been cleaner. Fatima paid attention to every detail.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=yasmine',
      'hasPhotos': true,
    },
  ];

  Widget _buildReviewsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...reviews.map(_buildReviewCard).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                
              },
              child: const Text(
                'Load More',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: NetworkImage(review['avatar'] as String),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['date'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
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
                index < (review['rating'] as int)
                    ? Icons.star
                    : Icons.star_border,
                size: 16,
                color: index < (review['rating'] as int)
                    ? Colors.amber
                    : const Color(0xFFD1D5DB),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            review['text'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
          if (review['hasPhotos'] == true) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobPostCardFromJob(Job job) {
    try {
      
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }

      final daysAgo = DateTime.now().difference(job.postedDate).inDays;
      final daysAgoText = daysAgo == 0 
          ? 'Today' 
          : daysAgo == 1 
              ? 'Yesterday' 
              : '$daysAgo days ago';

      return InkWell(
      onTap: () {
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageJobPage(job: job),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted $daysAgoText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${job.city}, ${job.country}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                  ? AppImage(
                      imageUrl: job.coverImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building job post card from job: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }

  Widget _buildJobPostCard(Map<String, dynamic> job) {
    
    
    return InkWell(
      onTap: () {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please use the new job card format')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted ${job['postedDaysAgo']} days ago',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                job['image'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF9CA3AF),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


