import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/bookingdetails.dart';
import '../../screens/jobdetails.dart';
import '../../screens/booking_details_page.dart';
import '../../screens/client_profile_page.dart';
import '../../screens/cleaner_profile_page.dart';
import '../../screens/cleaner_self_profile_page.dart';
import '../../screens/notifications_inbox_page.dart';
import '../../screens/manage_job_page.dart';
import '../../screens/agency_dashboard_page.dart';
import '../../screens/review_page.dart';
import '../navigation/app_navigator.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../data/repositories/bookings/bookings_repo.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../data/models/notification_item.dart';
import '../../logic/cubits/profiles_cubit.dart';
import 'notification_nav_data.dart';
import '../../data/models/job_model.dart';

/// Tab indices for AgencyDashboardPage
class AgencyDashboardTabs {
  static const int activeListings = 0;
  static const int pastBookings = 1;
  static const int availableJobs = 2;
  static const int profile = 3; // For Individual Cleaner
  static const int cleanerTeam = 3; // For Agency
}

/// Tab indices for CleanerSelfProfilePage
class CleanerProfileTabs {
  static const int overview = 0;
  static const int history = 1;
  static const int reviews = 2;
}

/// Enhanced notification router with async data fetching
/// Uses global navigator key to avoid context issues
class NotificationRouter {
  static bool _isAppReady = false;
  static RemoteMessage? _pendingMessage;
  
  /// Mark app as ready (call after initialization)
  static void markAppReady() {
    _isAppReady = true;
    if (_pendingMessage != null) {
      handleMessage(_pendingMessage!);
      _pendingMessage = null;
    }
  }

  /// Handle notification message and navigate to appropriate screen
  static Future<void> handleMessage(RemoteMessage message) async {
    // If app not ready, queue the message
    if (!_isAppReady) {
      _pendingMessage = message;
      return;
    }

    final data = message.data;
    final route = data['route']?.toString();
    final id = data['id']?.toString() ?? data['jobId']?.toString() ?? data['bookingId']?.toString();

    final context = navigatorKey.currentContext;
    if (context == null) {
      print('NotificationRouter: Navigator context not available');
      return;
    }

    if (route == null) {
      // Default: go to notifications inbox
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsInboxPage()),
      );
      return;
    }

    // Navigate based on route
    switch (route) {
      case '/jobDetails':
      case '/job':
        await _handleJobDetails(context, id);
        break;

      case '/bookingDetails':
      case '/booking':
        await _handleBookingDetails(context, id);
        break;

      case '/profile':
      case '/clientProfile':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientProfilePage()),
        );
        break;

      case '/notifications':
      case '/inbox':
      default:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsInboxPage()),
        );
        break;
    }
  }

  static void _showInfoSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// Handle job details navigation with async data fetching
  static Future<void> _handleJobDetails(BuildContext context, String? id) async {
    if (id == null) {
      // No ID provided, navigate without data
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JobDetailsScreen()),
      );
      return;
    }

    try {
      final jobId = int.tryParse(id);
      if (jobId == null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JobDetailsScreen()),
        );
        return;
      }

      // Fetch job data
      final jobsRepo = AbstractJobsRepo.getInstance();
      final job = await jobsRepo.getJobById(jobId);

      if (!context.mounted) return;

      if (job != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(job: job),
          ),
        );
      } else {
        // Job not found, navigate without data
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JobDetailsScreen()),
        );
      }
    } catch (e) {
      print('Error fetching job for notification: $e');
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JobDetailsScreen()),
        );
      }
    }
  }

  /// Handle booking details navigation with async data fetching
  static Future<void> _handleBookingDetails(BuildContext context, String? id) async {
    if (id == null) {
      // No ID provided, navigate without data
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
      );
      return;
    }

    try {
      final bookingId = int.tryParse(id);
      if (bookingId == null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
        );
        return;
      }

      // Fetch booking data
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final booking = await bookingsRepo.getBookingById(bookingId);

      if (!context.mounted) return;

      if (booking != null) {
        // Fetch related job
        final jobsRepo = AbstractJobsRepo.getInstance();
        final job = await jobsRepo.getJobById(booking.jobId);

        if (!context.mounted) return;

        if (job != null) {
          // Use BookingDetailsPage which requires a job Map
          final jobMap = {
            'title': job.title,
            'client': 'Client Name', // Could fetch client profile if needed
            'date': job.jobDate.toString(),
            'price': '${job.budgetMin ?? 0} DZD',
            'location': '${job.city}, ${job.country}',
            'notes': job.description,
          };

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingDetailsPage(job: jobMap),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
          );
        }
      } else {
        // Booking not found, navigate without data
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
        );
      }
    } catch (e) {
      print('Error fetching booking for notification: $e');
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
        );
      }
    }
  }

  /// Handle initial message (app opened from terminated state)
  static Future<void> handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Wait a bit for app to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      await handleMessage(initialMessage);
    }
  }

  /// Handle cleaner profile navigation with async data fetching
  static Future<void> _handleCleanerProfile(BuildContext context, String id) async {
    try {
      final cleanerId = int.tryParse(id);
      if (cleanerId == null) {
        return;
      }

      // Fetch cleaner profile
      final profileRepo = AbstractProfileRepo.getInstance();
      final profile = await profileRepo.getProfileById(cleanerId);

      if (!context.mounted) return;

      if (profile != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CleanerProfilePage(cleaner: profile),
          ),
        );
      }
    } catch (e) {
      print('Error fetching cleaner profile for notification: $e');
    }
  }

  /// Navigate to route directly (for use from notification tap in UI)
  static Future<void> navigateToRoute(BuildContext context, String route, String? id) async {
    switch (route) {
      case '/jobDetails':
      case '/job':
        await _handleJobDetails(context, id);
        break;

      case '/bookingDetails':
      case '/booking':
        await _handleBookingDetails(context, id);
        break;

      case '/profile':
      case '/clientProfile':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientProfilePage()),
        );
        break;

      case '/cleanerProfile':
        // Navigate to cleaner profile if id is provided
        if (id != null) {
          await _handleCleanerProfile(context, id);
        }
        break;

      case '/notifications':
      case '/inbox':
      default:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsInboxPage()),
        );
        break;
    }
  }

  /// Get current user role from ProfilesCubit
  static String? _getCurrentUserRole(BuildContext context) {
    try {
      final state = context.read<ProfilesCubit>().state;
      if (state is ProfilesLoaded && state.currentUser != null) {
        return state.currentUser!['user_type']?.toString()?.trim();
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return null;
  }

  /// Navigate to AgencyDashboardPage (for workers/agencies)
  /// Opens specific tab and highlights job if provided
  /// If highlightJobId is provided, will also open job details after scrolling
  static Future<void> _navigateToAgencyDashboard(
    BuildContext context, {
    int? initialTab,
    int? highlightJobId,
    bool autoOpenJobDetails = true,
  }) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AgencyDashboardPage(
          initialTab: initialTab,
          highlightJobId: highlightJobId,
        ),
      ),
      (route) => route.isFirst,
    );
    
    // If highlightJobId is provided and autoOpenJobDetails is true, open job details after a delay
    if (highlightJobId != null && autoOpenJobDetails) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (context.mounted) {
        try {
          final job = await AbstractJobsRepo.getInstance().getJobById(highlightJobId);
          if (job != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobDetailsScreen(job: job),
              ),
            );
          }
        } catch (e) {
          print('Error opening highlighted job: $e');
        }
      }
    }
  }

  /// Navigate to CleanerSelfProfilePage and open specific tab
  static Future<void> _navigateToMyProfile(
    BuildContext context, {
    int? initialTab, // 0=Overview, 1=History, 2=Reviews
  }) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CleanerSelfProfilePage(initialTab: initialTab),
      ),
    );
  }

  /// Navigate from notification item (main entry point for UI taps)
  /// Role-aware routing: different pages based on user role + notification type
  static Future<void> navigateFromNotification(BuildContext context, NotificationItem notification) async {
    try {
      // Parse navigation data from notification
      final navData = NotificationNavData.fromNotification(notification);
      
      if (!navData.isValid) {
        _showErrorSnackBar(context, 'Cannot open this notification (missing target).');
        return;
      }
      
      // Get current user role
      final userRole = _getCurrentUserRole(context);
      final normalizedRole = _normalizeUserRole(userRole);
      
      // Strategy A: Use explicit route if provided (but still consider role for some routes)
      if (navData.route != null) {
        // For manage job route, check if user is client/agency
        if (navData.route == '/manageJob' || navData.route == '/jobDetails') {
          if (normalizedRole == 'Client' && navData.jobId != null) {
            // Client should go to ManageJobPage for their own jobs
            final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
            if (job != null && !context.mounted) return;
            if (job != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ManageJobPage(job: job)),
              );
              return;
            }
          }
        }
        await navigateToRoute(context, navData.route!, navData.routeId);
        return;
      }
      
      // Strategy B: Role-aware type-based routing
      final type = navData.notificationType;
      if (type == null) {
        _showErrorSnackBar(context, 'Cannot open this notification (missing type).');
        return;
      }
      
      // Route based on (type + role) combination
      switch (type) {
        case 'job_published':
          if (normalizedRole == 'Client') {
            // Client's own job post -> ManageJobPage
            if (navData.jobId != null) {
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManageJobPage(job: job)),
                );
              } else {
                _showErrorSnackBar(context, 'Job not found.');
              }
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          } else {
            // Worker/Agency -> JobDetails (apply page)
            if (navData.jobId != null) {
              await _handleJobDetails(context, navData.jobId.toString());
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          }
          break;
          
        case 'job_accepted':
          if (normalizedRole == 'Client') {
            // Client -> ManageJobPage (see applications + accept/reject)
            if (navData.jobId != null) {
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManageJobPage(job: job)),
                );
              } else {
                _showErrorSnackBar(context, 'Job not found.');
              }
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          } else if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
            // Worker -> AgencyDashboardPage (Active Listings tab - their active jobs)
            // Opens Active Listings tab, highlights job, and auto-opens job details
            await _navigateToAgencyDashboard(
              context,
              initialTab: 0, // Active Listings tab
              highlightJobId: navData.jobId,
              autoOpenJobDetails: true, // Auto-open job details for active job actions
            );
          } else if (normalizedRole == 'Agency') {
            // Agency -> AgencyDashboardPage or ManageJobPage
            if (navData.jobId != null) {
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job != null && job.agencyId != null) {
                // If agency owns the job, go to ManageJobPage
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManageJobPage(job: job)),
                );
              } else {
                // Otherwise go to dashboard (Active Listings tab)
                await _navigateToAgencyDashboard(
                  context,
                  initialTab: 0, // Active Listings tab
                  highlightJobId: navData.jobId,
                  autoOpenJobDetails: false, // Agency may want to see list first
                );
              }
            } else {
              await _navigateToAgencyDashboard(
                context,
                initialTab: 0, // Active Listings tab
              );
            }
          } else {
            // Fallback: JobDetails
            if (navData.jobId != null) {
              await _handleJobDetails(context, navData.jobId.toString());
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          }
          break;
          
        case 'job_rejected':
          if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
            // Worker -> JobDetails (can see the job they were rejected from)
            if (navData.jobId != null) {
              await _handleJobDetails(context, navData.jobId.toString());
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          } else if (normalizedRole == 'Client') {
            // Client -> ManageJobPage (see all applications)
            if (navData.jobId != null) {
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManageJobPage(job: job)),
                );
              } else {
                _showErrorSnackBar(context, 'Job not found.');
              }
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          } else {
            // Fallback: JobDetails
            if (navData.jobId != null) {
              await _handleJobDetails(context, navData.jobId.toString());
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          }
          break;
          
        case 'job_completed':
          if (normalizedRole == 'Client') {
            // Client -> Only open ReviewPage if job is fully completed
            if (navData.jobId != null && navData.workerId != null) {
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job == null) {
                _showErrorSnackBar(context, 'Job not found.');
                return;
              }
              if (job.status == JobStatus.completed && job.clientDone && job.workerDone) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewPage(
                      bookingTitle: job.title,
                      jobId: navData.jobId,
                      cleanerId: navData.workerId,
                    ),
                  ),
                );
              } else {
                _showInfoSnackBar(context, 'Waiting for both parties to confirm completion.');
              }
            } else if (navData.jobId != null) {
              // Fallback: JobDetails if cleanerId missing
              final job = await AbstractJobsRepo.getInstance().getJobById(navData.jobId!);
              if (!context.mounted) return;
              if (job != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
                );
                // Show snackbar prompting to leave review
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          job.status == JobStatus.completed && job.clientDone && job.workerDone
                            ? 'Job completed! You can leave a review from the job details.'
                            : 'Waiting for both parties to confirm completion.',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                });
              } else {
                _showErrorSnackBar(context, 'Job not found.');
              }
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          } else if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
            // Worker -> CleanerSelfProfilePage History tab (tab 1)
            await _navigateToMyProfile(context, initialTab: 1); // History tab
            // If jobId provided, could scroll to that job in history (future enhancement)
          } else if (normalizedRole == 'Agency') {
            // Agency -> AgencyDashboardPage Past Bookings tab (tab 1)
            await _navigateToAgencyDashboard(
              context,
              initialTab: 1, // Past Bookings tab
              highlightJobId: navData.jobId,
              autoOpenJobDetails: false, // Agency may want to see list first
            );
          } else {
            // Fallback: JobDetails
            if (navData.jobId != null) {
              await _handleJobDetails(context, navData.jobId.toString());
            } else {
              _showErrorSnackBar(context, 'Job details not available.');
            }
          }
          break;
          
        case 'review_added':
          if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
            // Worker -> My Profile Reviews tab (tab 2)
            await _navigateToMyProfile(context, initialTab: 2); // Reviews tab
          } else if (normalizedRole == 'Client') {
            // Client -> CleanerProfilePage of the cleaner who was reviewed
            if (navData.cleanerId != null) {
              await _handleCleanerProfile(context, navData.cleanerId.toString());
            } else if (navData.workerId != null) {
              await _handleCleanerProfile(context, navData.workerId.toString());
            } else if (navData.senderId != null) {
              await _handleCleanerProfile(context, navData.senderId.toString());
            } else {
              _showErrorSnackBar(context, 'Profile not available.');
            }
          } else if (normalizedRole == 'Agency') {
            // Agency -> CleanerProfilePage of their worker
            if (navData.cleanerId != null) {
              await _handleCleanerProfile(context, navData.cleanerId.toString());
            } else if (navData.workerId != null) {
              await _handleCleanerProfile(context, navData.workerId.toString());
            } else {
              _showErrorSnackBar(context, 'Profile not available.');
            }
          } else {
            // Fallback: CleanerProfilePage
            if (navData.cleanerId != null) {
              await _handleCleanerProfile(context, navData.cleanerId.toString());
            } else if (navData.senderId != null) {
              await _handleCleanerProfile(context, navData.senderId.toString());
            } else {
              _showErrorSnackBar(context, 'Profile not available.');
            }
          }
          break;
          
        default:
          // Unknown type - show error
          _showErrorSnackBar(context, 'Cannot open this notification (unknown type: $type).');
          break;
      }
    } catch (e) {
      print('Error navigating from notification: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error opening notification: ${e.toString()}');
      }
    }
  }

  /// Normalize user role string
  static String _normalizeUserRole(String? role) {
    if (role == null) return 'Client';
    final normalized = role.trim();
    if (normalized.toLowerCase() == 'agency') return 'Agency';
    if (normalized.toLowerCase() == 'individual cleaner' || 
        normalized.toLowerCase() == 'cleaner' ||
        normalized.toLowerCase() == 'individual_cleaner' ||
        normalized.toLowerCase() == 'worker') {
      return 'Individual Cleaner';
    }
    if (normalized.toLowerCase() == 'client') return 'Client';
    return normalized;
  }
  
  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Route Audit (Dev/Debug only)
  /// Takes a sample NotificationItem and prints detected role + resolved destination
  /// Useful for debugging and preventing regressions
  static Future<Map<String, dynamic>> auditRoute(
    BuildContext context,
    NotificationItem notification,
  ) async {
    try {
      final navData = NotificationNavData.fromNotification(notification);
      final userRole = _getCurrentUserRole(context);
      final normalizedRole = _normalizeUserRole(userRole);
      
      String destination = 'Unknown';
      String? tabInfo;
      
      if (!navData.isValid) {
        destination = 'Error: Missing target';
      } else if (navData.route != null) {
        destination = 'Explicit route: ${navData.route}';
      } else {
        final type = navData.notificationType;
        switch (type) {
          case 'job_published':
            destination = normalizedRole == 'Client' 
                ? 'ManageJobPage' 
                : 'JobDetailsScreen';
            break;
          case 'job_accepted':
            if (normalizedRole == 'Client') {
              destination = 'ManageJobPage';
            } else if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
              destination = 'AgencyDashboardPage';
              tabInfo = 'Tab: Active Listings (0)';
            } else if (normalizedRole == 'Agency') {
              destination = 'ManageJobPage or AgencyDashboardPage';
            }
            break;
          case 'job_rejected':
            destination = normalizedRole == 'Client' 
                ? 'ManageJobPage' 
                : 'JobDetailsScreen';
            break;
          case 'job_completed':
            if (normalizedRole == 'Client') {
              destination = 'ReviewPage';
            } else if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
              destination = 'CleanerSelfProfilePage';
              tabInfo = 'Tab: History (1)';
            } else if (normalizedRole == 'Agency') {
              destination = 'AgencyDashboardPage';
              tabInfo = 'Tab: Past Bookings (1)';
            }
            break;
          case 'review_added':
            if (normalizedRole == 'Individual Cleaner' || normalizedRole == 'Worker') {
              destination = 'CleanerSelfProfilePage';
              tabInfo = 'Tab: Reviews (2)';
            } else {
              destination = 'CleanerProfilePage';
            }
            break;
          default:
            destination = 'Error: Unknown type';
        }
      }
      
      return {
        'notificationId': notification.id,
        'notificationType': navData.notificationType,
        'detectedRole': normalizedRole,
        'resolvedDestination': destination,
        'tabInfo': tabInfo,
        'hasJobId': navData.jobId != null,
        'hasBookingId': navData.bookingId != null,
        'hasWorkerId': navData.workerId != null,
        'hasClientId': navData.clientId != null,
        'hasCleanerId': navData.cleanerId != null,
        'navData': navData.toString(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'notificationId': notification.id,
      };
    }
  }
}

