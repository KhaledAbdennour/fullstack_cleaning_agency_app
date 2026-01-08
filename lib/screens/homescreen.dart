import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'jobdetails.dart';
import 'client_profile_page.dart';
import 'find_cleaner_page.dart';
import 'cleaner_profile_page.dart';
import 'add-post.dart';
import 'manage_job_page.dart';
import '../logic/cubits/listings_cubit.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/models/job_model.dart';
import '../utils/image_helper.dart';
import '../widgets/notification_bell_widget.dart';
import 'data_doctor_page.dart';
import '../core/debug/debug_logger.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // #region agent log
    DebugLogger.log('HomeScreen', 'initState', data: {
      'hypothesisId': 'H1',
      'initialIndex': _currentIndex,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    context.read<ListingsCubit>().loadListings();
  }
  
  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // #region agent log
    DebugLogger.log('HomeScreen', 'didUpdateWidget', data: {
      'hypothesisId': 'H1',
      'currentIndex': _currentIndex,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // #region agent log
    DebugLogger.log('HomeScreen', 'didChangeDependencies', data: {
      'hypothesisId': 'H1',
      'currentIndex': _currentIndex,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
  }


  @override
  Widget build(BuildContext context) {
    // Hide AppBar when showing profile page (it has its own AppBar)
    final showAppBar = _currentIndex != 3;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: showAppBar ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DataDoctorPage()),
            );
          },
          child: Row(
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
        ),
      ) : null,
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          // #region agent log
          DebugLogger.log('HomeScreen', 'BOTTOM_NAV_TAP', data: {
            'hypothesisId': 'H1',
            'previousIndex': _currentIndex,
            'newIndex': index,
            'sessionId': 'debug-session',
            'runId': 'run1',
          });
          // #endregion
          
          setState(() {
            _currentIndex = index;
          });
          
          // #region agent log
          DebugLogger.log('HomeScreen', 'STATE_UPDATED', data: {
            'hypothesisId': 'H2',
            'currentIndex': _currentIndex,
            'sessionId': 'debug-session',
            'runId': 'run1',
          });
          // #endregion
          
          if (index == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ListingsCubit>().loadListings();
              }
            });
          } else if (index == 3) {
            // Refresh profile page jobs when navigating to profile tab
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final profilesCubit = context.read<ProfilesCubit>();
                final profileState = profilesCubit.state;
                if (profileState is ProfilesLoaded && profileState.currentUser != null) {
                  final userId = profileState.currentUser!['id'] as int?;
                  final userType = profileState.currentUser!['user_type'] as String?;
                  if (userId != null && userType == 'Client') {
                    context.read<ClientJobsCubit>().loadClientJobs(userId);
                  }
                }
              }
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(icon: const Icon(Icons.search), label: AppLocalizations.of(context)!.search),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            label: AppLocalizations.of(context)!.addPost,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // #region agent log
    DebugLogger.log('HomeScreen', '_buildBody_CALLED', data: {
      'hypothesisId': 'H1',
      'currentIndex': _currentIndex,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    Widget bodyWidget;
    switch (_currentIndex) {
      case 0:
        bodyWidget = _buildHomeContent();
        break;
      case 1:
        bodyWidget = _buildSearchContent();
        break;
      case 2:
        bodyWidget = _buildAddPostContent();
        break;
      case 3:
        bodyWidget = const ClientProfilePage();
        break;
      default:
        bodyWidget = _buildHomeContent();
    }
    
    // #region agent log
    DebugLogger.log('HomeScreen', '_buildBody_RETURN', data: {
      'hypothesisId': 'H1',
      'currentIndex': _currentIndex,
      'bodyWidgetType': bodyWidget.runtimeType.toString(),
      'isClientProfilePage': bodyWidget is ClientProfilePage,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    return bodyWidget;
  }

  Widget _buildHomeContent() {
    // Load listings when home content is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListingsCubit>().loadListings();
      }
    });
    
    return BlocBuilder<ListingsCubit, ListingsState>(
      builder: (context, state) {
        if (state is ListingsLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        } else if (state is ListingsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ListingsCubit>().refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is ListingsLoaded) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Listings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: state.recentListings.isEmpty
                        ? const Center(
                            child: Text(
                              'No recent listings available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.recentListings.length,
                            itemBuilder: (context, index) {
                              try {
                                if (index >= state.recentListings.length) {
                                  return const SizedBox.shrink();
                                }
                                final job = state.recentListings[index];
                                
                                if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return _buildRecentCardFromJob(context, job);
                              } catch (e, stackTrace) {
                                print('Error building recent card at index $index: $e');
                                print('Stack trace: $stackTrace');
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Agencies',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: state.topAgencies.isEmpty
                        ? const Center(
                            child: Text(
                              'No agencies available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.topAgencies.length,
                            itemBuilder: (context, index) {
                              try {
                                if (index >= state.topAgencies.length) {
                                  return const SizedBox.shrink();
                                }
                                final agency = state.topAgencies[index];
                                
                                
                                if (agency == null || 
                                    agency['name'] == null || 
                                    agency['rating'] == null) {
                                  print('Skipping invalid agency at index $index: missing required fields');
                                  return const SizedBox.shrink();
                                }
                                
                                
                                final name = agency['name'] as String?;
                                final rating = agency['rating'];
                                
                                if (name == null || name.isEmpty) {
                                  print('Skipping agency at index $index: invalid name');
                                  return const SizedBox.shrink();
                                }
                                
                                final ratingValue = (rating is num) 
                                    ? rating.toDouble() 
                                    : ((rating as num?)?.toDouble() ?? 0.0);
                                
                                return _buildAgencyCard(
                                  context,
                                  name,
                                  ratingValue,
                                  agency['image'] as String?,
                                  agencyData: agency,
                                );
                              } catch (e, stackTrace) {
                                print('Error building agency card at index $index: $e');
                                print('Stack trace: $stackTrace');
                                
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Individuals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: state.topCleaners.isEmpty
                        ? const Center(
                            child: Text(
                              'No cleaners available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.topCleaners.length,
                            itemBuilder: (context, index) {
                              try {
                                if (index >= state.topCleaners.length) {
                                  return const SizedBox.shrink();
                                }
                                final cleaner = state.topCleaners[index];
                                
                                
                                if (cleaner == null || 
                                    cleaner['name'] == null || 
                                    cleaner['rating'] == null) {
                                  print('Skipping invalid cleaner at index $index: missing required fields');
                                  return const SizedBox.shrink();
                                }
                                
                                
                                final name = cleaner['name'] as String?;
                                final rating = cleaner['rating'];
                                
                                if (name == null || name.isEmpty) {
                                  print('Skipping cleaner at index $index: invalid name');
                                  return const SizedBox.shrink();
                                }
                                
                                final ratingValue = (rating is num) 
                                    ? rating.toDouble() 
                                    : ((rating as num?)?.toDouble() ?? 0.0);
                                
                                return _buildIndividualCard(
                                  context,
                                  name,
                                  ratingValue,
                                  false, // Remove verified tick - always false 
                                  cleaner['image'] as String?,
                                  cleanerData: cleaner,
                                );
                              } catch (e, stackTrace) {
                                print('Error building cleaner card at index $index: $e');
                                print('Stack trace: $stackTrace');
                                
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentCardFromJob(BuildContext context, Job job) {
    try {
      
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageJobPage(job: job),
              ),
            );
          } catch (e) {
            print('Error navigating to job details: $e');
          }
        },
        child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: null, 
              ),
              child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AppImage(
                        imageUrl: job.coverImageUrl!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${job.city}, ${job.country}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building recent card from job: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }

  Widget _buildSearchContent() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: const FindCleanerPage(),
    );
  }

  Widget _buildAddPostContent() {
    return const PostJobScreen();
  }

  Widget _buildRecentCard(
    BuildContext context,
    String title,
    String location,
    Color color, {
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobDetailsScreen()),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          
                        },
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyCard(
    BuildContext context,
    String name,
    double rating,
    String? logoUrl, {
    Map<String, dynamic>? agencyData,
  }) {
    
    try {
      
      final safeName = name.isEmpty ? 'Unknown Agency' : name;
      final safeRating = rating.isNaN || rating < 0 ? 0.0 : (rating > 5.0 ? 5.0 : rating);
      final location = agencyData?['location'] as String? ?? 'Algiers';

      return GestureDetector(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CleanerProfilePage(cleaner: {
                  'name': safeName,
                  'rating': safeRating,
                  'reviews': agencyData?['jobsCompleted'] as int? ?? 0,
                  'isVerified': agencyData?['is_verified'] as bool? ?? false,
                  'description': agencyData?['bio'] as String? ?? 'Professional cleaning service provider.',
                  'image': logoUrl ?? agencyData?['image'],
                  'type': 'Agency',
                  'location': location,
                  'price': agencyData?['hourly_rate'] != null 
                      ? 'From ${agencyData?['hourly_rate']} DZD/hr'
                      : AppLocalizations.of(context)!.contactForPricing,
                  'profileData': agencyData,
                }),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening agency profile: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7, 
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 250,
        ),
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ClipOval(
                  child: logoUrl != null && logoUrl.isNotEmpty
                      ? AppImage(
                          imageUrl: logoUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.business, size: 25, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business, size: 25, color: Colors.grey),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < rating.floor() ? Colors.amber : Colors.grey[300],
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${rating.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final agencyProfileData = {
                    'name': safeName,
                    'rating': safeRating,
                    'reviews': agencyData?['jobsCompleted'] as int? ?? 0,
                    'isVerified': agencyData?['is_verified'] as bool? ?? false,
                    'description': agencyData?['bio'] as String? ?? 'Professional cleaning service provider.',
                    'image': logoUrl ?? agencyData?['image'],
                    'type': 'Agency',
                    'location': location,
                    'price': agencyData?['hourly_rate'] != null 
                        ? 'From ${agencyData?['hourly_rate']} DZD/hr'
                        : AppLocalizations.of(context)!.contactForPricing,
                    'profileData': agencyData,
                  };
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CleanerProfilePage(cleaner: agencyProfileData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building agency card: $e');
      print('Stack trace: $stackTrace');
      
      return const SizedBox.shrink();
    }
  }

  Widget _buildIndividualCard(
    BuildContext context,
    String name,
    double rating,
    bool isVerified,
    String? imageUrl, {
    Map<String, dynamic>? cleanerData,
  }) {
    try {
      
      final safeName = name.isEmpty ? 'Unknown Cleaner' : name;
      final safeRating = rating.isNaN || rating < 0 ? 0.0 : (rating > 5.0 ? 5.0 : rating);
      final location = cleanerData?['location'] as String? ?? 'Algiers';
      
      
      // Use real data from cleanerData if available, otherwise minimal fallback
      final data = cleanerData != null ? {
        ...cleanerData,
        'name': safeName,
        'rating': safeRating,
        'reviews': cleanerData['jobsCompleted'] as int? ?? 0,
        'isVerified': cleanerData['is_verified'] as bool? ?? false,
        'description': cleanerData['bio'] as String? ?? 'Professional cleaning service provider.',
        'location': location,
        'price': cleanerData['hourly_rate'] != null 
            ? 'From ${cleanerData['hourly_rate']} DZD/hr'
            : 'Contact for pricing',
        'image': imageUrl ?? cleanerData['image'],
        'type': 'Individual',
        'aboutMe': cleanerData['bio'] as String? ?? 'Professional cleaning service provider.',
        'experience': cleanerData['experience_years'] != null
            ? '${cleanerData['experience_years']}+ Years'
            : '5+ Years',
        'age': cleanerData['age']?.toString() ?? '28',
        'languages': cleanerData['languages'] as String? ?? 'Arabic, French',
        'profileData': cleanerData,
      } : {
        'name': safeName,
        'rating': safeRating,
        'reviews': 0,
        'isVerified': false,
        'description': 'Professional cleaning service provider.',
        'location': location,
        'price': AppLocalizations.of(context)!.contactForPricing,
        'image': imageUrl,
        'type': 'Individual',
        'aboutMe': 'Professional cleaning service provider.',
        'experience': '5+ Years',
        'age': '28',
        'languages': 'Arabic, French',
      };

      return GestureDetector(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CleanerProfilePage(cleaner: data),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening cleaner profile: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7, 
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 250,
        ),
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? AppImage(
                            imageUrl: imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(Icons.person, size: 35, color: Colors.grey),
                          )
                        : const Icon(Icons.person, size: 35, color: Colors.grey),
                  ),
                ),
                // Removed verified tick - user requirement
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < rating.floor() ? Colors.amber : Colors.grey[300],
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${rating.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CleanerProfilePage(cleaner: data),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building individual card: $e');
      print('Stack trace: $stackTrace');
      
      return const SizedBox.shrink();
    }
  }
}
