import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'jobdetails.dart';
import 'client_profile_page.dart';
import 'find_cleaner_page.dart';
import 'cleaner_profile_page.dart';
import 'add-post.dart';
import 'manage_job_page.dart';
import 'active_posts_page.dart';
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
  final int? initialTabIndex;
  
  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  bool _showAgenciesList = false;
  bool _showIndividualsList = false;
  bool _showAddPost = false;
  bool _showAddPostInHome = false;
  bool _showActivePosts = false; // Flag to show active posts content

  @override
  void initState() {
    super.initState();
    // Set initial tab index if provided
    if (widget.initialTabIndex != null) {
      _currentIndex = widget.initialTabIndex!;
    }
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
        currentIndex: _showActivePosts ? 0 : _currentIndex, // Highlight home when showing active posts
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
            // Reset active posts flag when navigating away from home (unless staying on home)
            if (index != 0) {
              _showActivePosts = false;
            }
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
            // Reset agencies, individuals list view, add post, and active posts when going back to home
            setState(() {
              _showAgenciesList = false;
              _showIndividualsList = false;
              _showAddPostInHome = false;
              _showActivePosts = false; // Reset active posts flag
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ListingsCubit>().loadListings();
              }
            });
          } else if (index == 2) {
            // Reset add post flag and active posts flag when navigating to My Posts tab via bottom nav
            setState(() {
              _showAddPost = false;
              _showActivePosts = false; // Reset active posts flag to show all posts
            });
            // Refresh My Posts when navigating to My Posts tab
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
            icon: const Icon(Icons.article_outlined),
            label: AppLocalizations.of(context)!.myPosts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: AppLocalizations.of(context)!.profile,
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
    // If showing active posts, display it but keep home tab highlighted
    if (_showActivePosts) {
      bodyWidget = _buildActivePostsContent();
    } else {
    switch (_currentIndex) {
      case 0:
        bodyWidget = _buildHomeContent();
        break;
      case 1:
        bodyWidget = _buildSearchContent();
        break;
      case 2:
          bodyWidget = _showAddPost ? _buildAddPostContent() : _buildMyPostsContent();
        break;
      case 3:
        bodyWidget = const ClientProfilePage();
        break;
      default:
        bodyWidget = _buildHomeContent();
      }
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
    
    // Show add post form if flag is set
    if (_showAddPostInHome) {
      return _buildAddPostContent();
    }
    
    // Show agencies list if flag is set
    if (_showAgenciesList) {
      return _buildAgenciesListContent();
    }
    
    // Show individuals list if flag is set
    if (_showIndividualsList) {
      return _buildIndividualsListContent();
    }
    
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is ListingsLoaded) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Use constraints.maxHeight which already accounts for app bar and bottom nav bar
              final availableHeight = constraints.maxHeight;
              final topPadding = 16.0;
              final bottomPadding = 16.0;
              final spacing = 16.0 * 2; // spacing between 3 cards (2 gaps)
              final totalPaddingAndSpacing = topPadding + bottomPadding + spacing;
              final cardHeight = (availableHeight - totalPaddingAndSpacing) / 3; // Divide equally among 3 cards
              
              return Padding(
                padding: EdgeInsets.fromLTRB(16.0, topPadding, 16.0, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildAddPostCard(context, cardHeight),
                    const SizedBox(height: 16),
                    _buildViewAllAgenciesCard(context, cardHeight),
                    const SizedBox(height: 16),
                    _buildViewAllIndividualsCard(context, cardHeight),
                  ],
                ),
              );
            },
          );
        }
                                  return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddPostCard(BuildContext context, double cardHeight) {
    final coverHeight = cardHeight * 0.75; // 75% for cover, 25% for text
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAddPostInHome = true;
        });
      },
      child: Container(
        width: double.infinity,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AppImage(
                imageUrl: 'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800&auto=format&fit=crop',
                height: coverHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: Container(
                  height: coverHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_circle_outline,
                      size: coverHeight * 0.4,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
            // "Add Post" text at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.addPost,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllAgenciesCard(BuildContext context, double cardHeight) {
    final coverHeight = cardHeight * 0.75; // 75% for cover, 25% for text
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is! ProfilesLoaded || profileState.currentUser == null) {
          return _buildMyPostsCard(context, cardHeight, coverHeight);
        }

        final userId = profileState.currentUser!['id'] as int?;
        final userType = profileState.currentUser!['user_type'] as String?;

        if (userId == null || userType != 'Client') {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivePostsPage(),
                ),
              );
            },
            child: _buildMyPostsCard(context, cardHeight, coverHeight),
          );
        }

        return GestureDetector(
          onTap: () {
            // Show active posts content within HomeScreen
            setState(() {
              _showActivePosts = true;
              _currentIndex = 0; // Keep home tab highlighted
            });
            // Load jobs if needed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ClientJobsCubit>().loadClientJobs(userId);
              }
            });
          },
          child: _buildMyPostsCard(context, cardHeight, coverHeight),
        );
      },
    );
  }

  Widget _buildMyPostsCard(BuildContext context, double cardHeight, double coverHeight) {
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cover image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: AppImage(
              imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&auto=format&fit=crop',
              height: coverHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: Container(
                height: coverHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.work_outline,
                    size: coverHeight * 0.4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
          // "Active Posts" text at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.activePosts,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgenciesListContent() {
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is ListingsLoaded) {
          // Filter to only agencies and sort by rating descending
          final allAgencies = List<Map<String, dynamic>>.from(state.topAgencies)
              .where((agency) {
                // Double-check: ensure it's an agency (should already be filtered in cubit)
                return agency['name'] != null;
              })
              .toList();
          
          // Sort by rating descending (highest rating first)
          allAgencies.sort((a, b) {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingB.compareTo(ratingA); // Higher rating first
          });

          if (allAgencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                              'No agencies available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAgenciesList = false;
                      });
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allAgencies.length,
                            itemBuilder: (context, index) {
              final agency = allAgencies[index];
              return _buildAgencyListCard(context, agency);
            },
          );
        }
                                  return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAgencyListCard(BuildContext context, Map<String, dynamic> agency) {
    final name = agency['name'] as String? ?? 'Unknown Agency';
    final description = agency['bio'] as String? ?? 'Professional cleaning service provider.';
    final location = agency['location'] as String? ?? 'Unknown';
    final priceValue = agency['hourly_rate'];
    final price = priceValue != null && priceValue.toString().isNotEmpty
        ? 'From $priceValue DZD/hr'
        : AppLocalizations.of(context)!.contactForPricing;
    final rating = (agency['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = agency['jobsCompleted'] as int? ?? 0;
    final imageUrl = agency['image'] as String?;
    
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
              // Agency logo/image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5E7EB),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? AppImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.business, size: 30, color: Color(0xFF9CA3AF)),
                        )
                      : const Icon(Icons.business, size: 30, color: Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            price,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          '${rating.toStringAsFixed(1)} (${AppLocalizations.of(context)!.reviewsCount(reviews)})',
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
              onPressed: () {
                Navigator.push(
                                  context,
                  MaterialPageRoute(
                    builder: (context) => CleanerProfilePage(cleaner: {
                      'name': name,
                      'rating': rating,
                      'reviews': reviews,
                      'isVerified': agency['is_verified'] as bool? ?? false,
                      'description': description,
                      'image': imageUrl,
                      'type': 'Agency',
                      'location': location,
                      'price': price,
                      'profileData': agency,
                    }),
                  ),
                );
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
        ],
      ),
    );
  }

  Widget _buildViewAllIndividualsCard(BuildContext context, double cardHeight) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is! ProfilesLoaded || profileState.currentUser == null) {
          // Show placeholder while loading
          return _buildPlaceholderCard(cardHeight);
        }

        final userId = profileState.currentUser!['id'] as int?;
        final userType = profileState.currentUser!['user_type'] as String?;

        if (userId == null || userType != 'Client') {
          // Show placeholder for non-clients
          return _buildPlaceholderCard(cardHeight);
        }

        // Load client jobs when card is first built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ClientJobsCubit>().loadClientJobs(userId);
          }
        });

        return BlocBuilder<ClientJobsCubit, ClientJobsState>(
          builder: (context, state) {
            if (state is ClientJobsLoading || state is! ClientJobsLoaded || state.jobs.isEmpty) {
              // Show placeholder while loading or if no jobs
              return _buildPlaceholderCard(cardHeight);
            }

            // Find the latest edited post (sort by updatedAt descending, fallback to postedDate)
            final sortedJobs = List<Job>.from(state.jobs);
            sortedJobs.sort((a, b) {
              final aDate = a.updatedAt ?? a.postedDate;
              final bDate = b.updatedAt ?? b.postedDate;
              return bDate.compareTo(aDate);
            });

            final latestJob = sortedJobs.first;
            
            // Build the job card constrained to cardHeight
            return _buildLatestJobCard(latestJob, cardHeight);
          },
        );
      },
    );
  }

  Widget _buildPlaceholderCard(double cardHeight) {
    final coverHeight = cardHeight * 0.75;
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            height: coverHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: coverHeight * 0.4,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.noPostsYet,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestJobCard(Job job, double cardHeight) {
    try {
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return _buildPlaceholderCard(cardHeight);
      }

      // Calculate time ago
      final now = DateTime.now();
      final difference = now.difference(job.postedDate);
      String timeAgoText;
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            timeAgoText = AppLocalizations.of(context)!.justNow;
          } else {
            timeAgoText = AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
          }
        } else {
          timeAgoText = AppLocalizations.of(context)!.hoursAgo(difference.inHours);
        }
      } else if (difference.inDays == 1) {
        timeAgoText = AppLocalizations.of(context)!.yesterday;
      } else if (difference.inDays < 7) {
        timeAgoText = AppLocalizations.of(context)!.daysAgo(difference.inDays);
      } else {
        timeAgoText = '${job.postedDate.day}/${job.postedDate.month}/${job.postedDate.year}';
      }

      // Get status color
      Color statusColor;
      switch (job.status) {
        case JobStatus.open:
          statusColor = Colors.green;
          break;
        case JobStatus.pending:
          statusColor = Colors.orange;
          break;
        case JobStatus.assigned:
          statusColor = Colors.blue;
          break;
        case JobStatus.inProgress:
          statusColor = const Color(0xFF3B82F6);
          break;
        case JobStatus.completedPendingConfirmation:
          statusColor = Colors.purple;
          break;
        case JobStatus.completed:
          statusColor = Colors.green;
          break;
        case JobStatus.cancelled:
          statusColor = Colors.red;
          break;
        default:
          statusColor = Colors.grey;
      }

      // Calculate image height and content height to fit within cardHeight
      final imageHeight = cardHeight * 0.6; // 60% for image
      final contentHeight = cardHeight * 0.4; // 40% for content

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageJobPage(job: job),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                    ? AppImage(
                        imageUrl: job.coverImageUrl!,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: imageHeight,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 32, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 32, color: Colors.grey),
                      ),
              ),
              // Content - constrained to fit remaining height
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Time posted
                      Text(
                        timeAgoText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${job.city}, ${job.country}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building latest job card: $e');
      return _buildPlaceholderCard(cardHeight);
    }
  }

  Widget _buildIndividualsListContent() {
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is ListingsLoaded) {
          // Filter to only individuals/cleaners and sort by rating descending
          final allIndividuals = List<Map<String, dynamic>>.from(state.topCleaners)
              .where((individual) {
                // Double-check: ensure it's an individual (should already be filtered in cubit)
                return individual['name'] != null;
              })
              .toList();
          
          // Sort by rating descending (highest rating first)
          allIndividuals.sort((a, b) {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingB.compareTo(ratingA); // Higher rating first
          });

          if (allIndividuals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No individuals available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showIndividualsList = false;
                      });
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allIndividuals.length,
            itemBuilder: (context, index) {
              final individual = allIndividuals[index];
              return _buildIndividualListCard(context, individual);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildIndividualListCard(BuildContext context, Map<String, dynamic> individual) {
    final name = individual['name'] as String? ?? 'Unknown Individual';
    final description = individual['bio'] as String? ?? 'Professional cleaning service provider.';
    final location = individual['location'] as String? ?? 'Unknown';
    final priceValue = individual['hourly_rate'];
    final price = priceValue != null && priceValue.toString().isNotEmpty
        ? 'From $priceValue DZD/hr'
        : AppLocalizations.of(context)!.contactForPricing;
    final rating = (individual['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = individual['jobsCompleted'] as int? ?? 0;
    final imageUrl = individual['image'] as String?;
    
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
              // Individual profile image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5E7EB),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? AppImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.person, size: 30, color: Color(0xFF9CA3AF)),
                        )
                      : const Icon(Icons.person, size: 30, color: Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            price,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          '${rating.toStringAsFixed(1)} (${AppLocalizations.of(context)!.reviewsCount(reviews)})',
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CleanerProfilePage(cleaner: {
                      'name': name,
                      'rating': rating,
                      'reviews': reviews,
                      'isVerified': individual['is_verified'] as bool? ?? false,
                      'description': description,
                      'image': imageUrl,
                      'type': 'Individual',
                      'location': location,
                      'price': price,
                      'profileData': individual,
                    }),
                  ),
                );
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
        ],
      ),
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
                        color: Color(0xFF3B82F6),
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
    return const PostJobScreen(showInScaffold: false);
  }

  Widget _buildMyPostsContent() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is! ProfilesLoaded || profileState.currentUser == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }

        final userId = profileState.currentUser!['id'] as int?;
        final userType = profileState.currentUser!['user_type'] as String?;

        if (userId == null || userType != 'Client') {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context)!.myPostsOnlyForClients,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }

        // Load client jobs when My Posts content is first built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ClientJobsCubit>().loadClientJobs(userId);
          }
        });

        return BlocBuilder<ClientJobsCubit, ClientJobsState>(
          builder: (context, state) {
            if (state is ClientJobsLoading && state is! ClientJobsLoaded) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
            } else if (state is ClientJobsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClientJobsCubit>().refresh(userId);
                      },
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            } else if (state is ClientJobsLoaded) {
              // Show all non-deleted jobs (including completed)
              final allJobs = state.jobs.where((job) => !job.isDeleted).toList();

              if (allJobs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noPostsYet,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort jobs by most recent first (postedDate descending)
              final sortedJobs = List<Job>.from(allJobs);
              sortedJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: sortedJobs.map((job) {
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
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildActivePostsContent() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is! ProfilesLoaded || profileState.currentUser == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }

        final userId = profileState.currentUser!['id'] as int?;
        final userType = profileState.currentUser!['user_type'] as String?;

        if (userId == null || userType != 'Client') {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context)!.activePostsOnlyForClients,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }

        // Load client jobs when Active Posts content is first built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ClientJobsCubit>().loadClientJobs(userId);
          }
        });

        return BlocBuilder<ClientJobsCubit, ClientJobsState>(
          builder: (context, state) {
            if (state is ClientJobsLoading && state is! ClientJobsLoaded) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
            } else if (state is ClientJobsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClientJobsCubit>().refresh(userId);
                      },
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            } else if (state is ClientJobsLoaded) {
              // Filter out completed jobs and deleted jobs - ONLY show active posts
              final activeJobs = state.jobs.where((job) => 
                job.status != JobStatus.completed && 
                !job.isDeleted
              ).toList();

              if (activeJobs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noActivePosts,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort jobs by most recent first (postedDate descending)
              final sortedJobs = List<Job>.from(activeJobs);
              sortedJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: sortedJobs.map((job) {
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
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildJobPostCardFromJob(Job job) {
    try {
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }

      // Calculate time ago with better precision
      final now = DateTime.now();
      final difference = now.difference(job.postedDate);
      String timeAgoText;
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            timeAgoText = AppLocalizations.of(context)!.justNow;
          } else {
            timeAgoText = AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
          }
        } else {
          timeAgoText = AppLocalizations.of(context)!.hoursAgo(difference.inHours);
        }
      } else if (difference.inDays == 1) {
        timeAgoText = AppLocalizations.of(context)!.yesterday;
      } else if (difference.inDays < 7) {
        timeAgoText = AppLocalizations.of(context)!.daysAgo(difference.inDays);
      } else {
        timeAgoText = '${job.postedDate.day}/${job.postedDate.month}/${job.postedDate.year}';
      }

      // Get status color
      Color statusColor;
      switch (job.status) {
        case JobStatus.open:
          statusColor = Colors.green;
          break;
        case JobStatus.pending:
          statusColor = Colors.orange;
          break;
        case JobStatus.assigned:
          statusColor = Colors.blue;
          break;
        case JobStatus.inProgress:
          statusColor = const Color(0xFF3B82F6);
          break;
        case JobStatus.completedPendingConfirmation:
          statusColor = Colors.purple;
          break;
        case JobStatus.completed:
          statusColor = Colors.green;
          break;
        case JobStatus.cancelled:
          statusColor = Colors.red;
          break;
        default:
          statusColor = Colors.grey;
      }

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                    ? AppImage(
                        imageUrl: job.coverImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            job.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Budget (Min - Max) with blue icon - under description, above location
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.budgetMin != null && job.budgetMax != null
                                  ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
                                  : job.budgetMin != null
                                      ? 'DA ${job.budgetMin!.toStringAsFixed(0)}'
                                      : job.budgetMax != null
                                          ? 'DA ${job.budgetMax!.toStringAsFixed(0)}'
                                          : AppLocalizations.of(context)!.budgetNegotiable,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location with blue icon
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${job.city}, ${job.country}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Date with blue icon and time ago in parentheses - under location
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${job.postedDate.day}/${job.postedDate.month}/${job.postedDate.year} ($timeAgoText)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
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
      print('Error building job post card: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
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
            ClipOval(
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? AppImage(
                      imageUrl: logoUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business, size: 35, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business, size: 35, color: Colors.grey),
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
            : AppLocalizations.of(context)!.contactForPricing,
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
            ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? AppImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 35, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 35, color: Colors.grey),
                    ),
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
