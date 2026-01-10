import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/cubits/notifications/notifications_cubit.dart';
import '../logic/cubits/notifications/notifications_state.dart';
import '../data/models/notification_item.dart';
import '../l10n/app_localizations.dart';
import '../core/services/notification_router.dart';
import '../core/debug/debug_flags.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  Map<String, dynamic>? _diagnostics;
  bool _showDiagnostics = false;

  @override
  void initState() {
    super.initState();
    // Refresh inbox when screen opens
    context.read<NotificationsCubit>().refreshInbox();
    _loadDiagnostics();

    // Handle notification opened app (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationRouter.handleMessage(message);
    });
  }

  Future<void> _loadDiagnostics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      if (userId != null) {
        final repo = context.read<NotificationsCubit>().repo;
        final diagnostics = await repo.getDiagnostics(userId.toString());
        if (mounted) {
          setState(() {
            _diagnostics = diagnostics;
          });
        }
      }
    } catch (e) {
      print('Error loading diagnostics: $e');
    }
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          localizations?.notifications ?? 'Notifications',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6B7280)),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsReady && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationsCubit>().markAllAsRead();
                  },
                  child: Text(
                    localizations?.markAllRead ?? 'Mark all read',
                    style: const TextStyle(color: Color(0xFF3B82F6)),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationsCubit>().refreshInbox();
                    },
                    child: Text(localizations?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsReady) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations?.noNotifications ?? 'No notifications',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Diagnostics (dev mode only)
                      if (DebugFlags.enableUIDiagnostics)
                        Card(
                          color: Colors.blue[50],
                          child: ExpansionTile(
                            title: const Text(
                              '🔍 Diagnostics (Dev Mode)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            initiallyExpanded: _showDiagnostics,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _showDiagnostics = expanded;
                              });
                              if (expanded && _diagnostics == null) {
                                _loadDiagnostics();
                              }
                            },
                            children: [
                              if (_diagnostics != null)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDiagnosticRow(
                                        'Current User ID (Prefs)',
                                        _diagnostics!['currentUserId_fromPrefs']
                                                ?.toString() ??
                                            'null',
                                      ),
                                      _buildDiagnosticRow(
                                        'Current User ID (Query)',
                                        _diagnostics!['currentUserId_fromQuery']
                                                ?.toString() ??
                                            'null',
                                      ),
                                      _buildDiagnosticRow(
                                        'User Role',
                                        _diagnostics!['userType']?.toString() ??
                                            'Unknown',
                                      ),
                                      _buildDiagnosticRow(
                                        'Total Notifications (all)',
                                        _diagnostics!['totalNotifications']
                                                ?.toString() ??
                                            '0',
                                      ),
                                      _buildDiagnosticRow(
                                        'Unread Count (all)',
                                        _diagnostics!['unreadCount_all']
                                                ?.toString() ??
                                            '0',
                                      ),
                                      _buildDiagnosticRow(
                                        'Filtered Notifications',
                                        _diagnostics!['filteredNotifications']
                                                ?.toString() ??
                                            '0',
                                      ),
                                      _buildDiagnosticRow(
                                        'Unread Count (filtered)',
                                        _diagnostics!['unreadCount_filtered']
                                                ?.toString() ??
                                            '0',
                                      ),
                                      _buildDiagnosticRow(
                                        'Collection Name',
                                        _diagnostics!['collectionName']
                                                ?.toString() ??
                                            'notifications',
                                      ),
                                      if (_diagnostics!['sampleNotification'] !=
                                          null) ...[
                                        const Divider(),
                                        const Text(
                                          'Sample Notification:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        _buildDiagnosticRow(
                                          '  user_id',
                                          _diagnostics!['sampleNotification']['user_id']
                                                  ?.toString() ??
                                              'null',
                                        ),
                                        _buildDiagnosticRow(
                                          '  user_id type',
                                          _diagnostics!['sampleNotification']['user_id_type']
                                                  ?.toString() ??
                                              'null',
                                        ),
                                        _buildDiagnosticRow(
                                          '  type',
                                          _diagnostics!['sampleNotification']['type']
                                                  ?.toString() ??
                                              'null',
                                        ),
                                        _buildDiagnosticRow(
                                          '  read',
                                          _diagnostics!['sampleNotification']['read']
                                                  ?.toString() ??
                                              'null',
                                        ),
                                      ],
                                      if (_diagnostics!['error'] != null) ...[
                                        const Divider(),
                                        Text(
                                          'Error: ${_diagnostics!['error']}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            // Group notifications by type
            final groupedNotifications = _groupNotificationsByType(
              notifications,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsCubit>().refreshInbox();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedNotifications.length,
                itemBuilder: (context, index) {
                  final group = groupedNotifications[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index > 0) const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          group['type'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      ...(group['notifications'] as List<NotificationItem>).map(
                        (notification) {
                          return _NotificationTile(
                            notification: notification,
                            onTap: () async {
                              // Mark as read BEFORE navigation
                              if (!notification.read) {
                                await context
                                    .read<NotificationsCubit>()
                                    .markAsRead(notification.id);
                              }

                              // Navigate using the enhanced router
                              await NotificationRouter.navigateFromNotification(
                                context,
                                notification,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Group notifications by type
  List<Map<String, dynamic>> _groupNotificationsByType(
    List<NotificationItem> notifications,
  ) {
    final Map<String, List<NotificationItem>> grouped = {};

    for (final notification in notifications) {
      final type = notification.type ?? 'Other';
      grouped.putIfAbsent(type, () => []).add(notification);
    }

    // Sort groups by type priority and return as list
    final typeOrder = {
      'job_published': 1,
      'job_accepted': 2,
      'job_rejected': 3,
      'job_completed': 4,
      'review_added': 5,
    };

    return grouped.entries.map((entry) {
      final typeName = _getTypeDisplayName(entry.key);
      return {'type': typeName, 'notifications': entry.value};
    }).toList()..sort((a, b) {
      final aPriority = typeOrder[a['type']] ?? 99;
      final bPriority = typeOrder[b['type']] ?? 99;
      return aPriority.compareTo(bPriority);
    });
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'job_published':
        return 'New Jobs';
      case 'job_accepted':
        return 'Accepted Applications';
      case 'job_rejected':
        return 'Rejected Applications';
      case 'job_completed':
        return 'Completed Jobs';
      case 'review_added':
        return 'Reviews';
      default:
        return 'Other';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notification.type),
          child: Icon(
            _getTypeIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : const Icon(Icons.circle, size: 8, color: Color(0xFF3B82F6)),
        onTap: onTap,
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'job_published':
        return const Color(0xFF3B82F6); // Blue
      case 'job_accepted':
        return const Color(0xFF10B981); // Green
      case 'job_rejected':
        return const Color(0xFFEF4444); // Red
      case 'job_completed':
        return const Color(0xFF8B5CF6); // Purple
      case 'review_added':
        return const Color(0xFFF59E0B); // Orange
      default:
        return notification.read
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF3B82F6);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'job_published':
        return Icons.work_outline;
      case 'job_accepted':
        return Icons.check_circle_outline;
      case 'job_rejected':
        return Icons.cancel_outlined;
      case 'job_completed':
        return Icons.done_all;
      case 'review_added':
        return Icons.star_outline;
      default:
        return notification.read
            ? Icons.notifications
            : Icons.notifications_active;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
