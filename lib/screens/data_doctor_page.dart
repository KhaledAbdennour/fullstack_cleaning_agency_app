import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../core/config/firebase_config.dart';
import '../core/debug/debug_logger.dart';
import '../core/utils/job_images_migration.dart';

class DataDoctorPage extends StatefulWidget {
  const DataDoctorPage({super.key});

  @override
  State<DataDoctorPage> createState() => _DataDoctorPageState();
}

class _DataDoctorPageState extends State<DataDoctorPage> {
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsUserId = prefs.getInt('current_user_id');
      final prefsKeyName = 'current_user_id';

      final cubit = context.read<ProfilesCubit>();
      await cubit.loadCurrentUser();
      final state = cubit.state;

      int? cubitUserId;
      String? userType;
      String? userIdSource = 'Not found';
      if (state is ProfilesLoaded && state.currentUser != null) {
        cubitUserId = state.currentUser!['id'] as int?;
        userType = state.currentUser!['user_type'] as String?;
        userIdSource =
            'ProfilesCubit (from SharedPreferences key: $prefsKeyName)';
      }

      final currentUserId = prefsUserId ?? cubitUserId;
      if (currentUserId == null) {
        userIdSource = 'Not found in SharedPreferences or Cubit';
      } else if (prefsUserId != null) {
        userIdSource = 'SharedPreferences (key: $prefsKeyName)';
      }

      final jobsSnapshot =
          await FirebaseConfig.firestore.collection('jobs').get();
      final jobsCount = jobsSnapshot.docs.length;

      final bookingsSnapshot =
          await FirebaseConfig.firestore.collection('bookings').get();
      final bookingsCount = bookingsSnapshot.docs.length;

      final profilesSnapshot =
          await FirebaseConfig.firestore.collection('profiles').get();
      final profilesCount = profilesSnapshot.docs.length;

      final lastJobsSnapshot = await FirebaseConfig.firestore
          .collection('jobs')
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      final lastJobs = lastJobsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'docId': doc.id,
          'id': int.tryParse(doc.id) ?? 0,
          'client_id': data['client_id'],
          'client_id_value': data['client_id'],
          'client_id_type': data['client_id']?.runtimeType.toString() ?? 'null',
          'status': data['status'] ?? 'missing',
          'is_deleted': data['is_deleted'],
          'is_deleted_value': data['is_deleted'],
          'is_deleted_type':
              data['is_deleted']?.runtimeType.toString() ?? 'null',
          'assigned_worker_id': data['assigned_worker_id'],
          'assigned_worker_id_value': data['assigned_worker_id'],
          'assigned_worker_id_type':
              data['assigned_worker_id']?.runtimeType.toString() ?? 'null',
          'posted_date': data['posted_date']?.toString() ?? 'missing',
          'posted_date_type':
              data['posted_date']?.runtimeType.toString() ?? 'null',
          'agency_id': data['agency_id'],
          'agency_id_value': data['agency_id'],
          'agency_id_type': data['agency_id']?.runtimeType.toString() ?? 'null',
          'title': data['title'] ?? 'N/A',
        };
      }).toList();

      final lastBookingsSnapshot = await FirebaseConfig.firestore
          .collection('bookings')
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      final lastBookings = lastBookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'docId': doc.id,
          'id': int.tryParse(doc.id) ?? 0,
          'job_id': data['job_id'],
          'job_id_value': data['job_id'],
          'job_id_type': data['job_id']?.runtimeType.toString() ?? 'null',
          'client_id': data['client_id'],
          'client_id_value': data['client_id'],
          'client_id_type': data['client_id']?.runtimeType.toString() ?? 'null',
          'provider_id': data['provider_id'],
          'provider_id_value': data['provider_id'],
          'provider_id_type':
              data['provider_id']?.runtimeType.toString() ?? 'null',
          'status': data['status'] ?? 'missing',
          'created_at': data['created_at']?.toString() ?? 'missing',
          'created_at_type':
              data['created_at']?.runtimeType.toString() ?? 'null',
        };
      }).toList();

      setState(() {
        _diagnostics = {
          'currentUserId': currentUserId,
          'currentUserIdFromPrefs': prefsUserId,
          'currentUserIdFromCubit': cubitUserId,
          'userIdSource': userIdSource,
          'userType': userType,
          'jobsCount': jobsCount,
          'bookingsCount': bookingsCount,
          'profilesCount': profilesCount,
          'lastJobs': lastJobs,
          'lastBookings': lastBookings,
        };
        _isLoading = false;
      });

      DebugLogger.log('DataDoctor', 'DIAGNOSTICS_LOADED', data: _diagnostics!);
    } catch (e, stack) {
      DebugLogger.error('DataDoctor', 'LOAD_ERROR', e, stack);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _migrateJobImages() async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add job_images Field'),
        content: const Text(
          'This will add the job_images field to ALL jobs in Firestore. This ensures the field appears in Firebase console. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding job_images field to all jobs...')),
    );

    try {
      final updatedCount = await JobImagesMigration.forceMigrateAllJobs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Success! Updated $updatedCount jobs with job_images field',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
        _loadDiagnostics();
      }
    } catch (e, stack) {
      DebugLogger.error('DataDoctor', 'JOB_IMAGES_MIGRATION_ERROR', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _repairLegacyData() async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Legacy Data'),
        content: const Text(
          'This will scan and fix missing fields/types in jobs and bookings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Repairing legacy data...')));

    try {
      int jobsRepaired = 0;
      int bookingsRepaired = 0;

      final jobsSnapshot =
          await FirebaseConfig.firestore.collection('jobs').get();
      var batch = FirebaseConfig.firestore.batch();
      int batchCount = 0;

      Map<String, dynamic>? sampleBefore;
      Map<String, dynamic>? sampleAfter;
      bool sampleLogged = false;

      for (final doc in jobsSnapshot.docs) {
        final data = doc.data();
        bool needsRepair = false;
        final updates = <String, dynamic>{};

        if (!sampleLogged && jobsRepaired == 0) {
          sampleBefore = Map<String, dynamic>.from(data);
        }

        if (data['client_id'] is String) {
          final parsed = int.tryParse(data['client_id'] as String);
          if (parsed != null) {
            updates['client_id'] = parsed;
            needsRepair = true;
          }
        }

        if (!data.containsKey('is_deleted')) {
          updates['is_deleted'] = false;
          needsRepair = true;
        } else if (data['is_deleted'] is int) {
          final intValue = data['is_deleted'] as int;
          updates['is_deleted'] = intValue == 1;
          needsRepair = true;
        }

        if (!data.containsKey('assigned_worker_id')) {
          updates['assigned_worker_id'] = null;
          needsRepair = true;
        }

        if (!data.containsKey('agency_id')) {
          updates['agency_id'] = null;
          needsRepair = true;
        }

        if (!data.containsKey('posted_date')) {
          updates['posted_date'] = FieldValue.serverTimestamp();
          needsRepair = true;
        }

        if (!data.containsKey('status') || data['status'] == null) {
          updates['status'] = 'open';
          needsRepair = true;
        }

        if (!data.containsKey('created_at')) {
          updates['created_at'] = FieldValue.serverTimestamp();
          needsRepair = true;
        }
        if (!data.containsKey('updated_at')) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          needsRepair = true;
        }

        if (!data.containsKey('job_images') || data['job_images'] == null) {
          updates['job_images'] = <String>[];
          needsRepair = true;
        }

        if (needsRepair) {
          if (!sampleLogged && sampleBefore != null) {
            sampleAfter = Map<String, dynamic>.from(data);
            sampleAfter.addAll(updates);
            DebugLogger.log(
              'DataDoctor',
              'REPAIR_SAMPLE',
              data: {
                'docId': doc.id,
                'before': sampleBefore,
                'after': sampleAfter,
              },
            );
            sampleLogged = true;
          }

          batch.update(doc.reference, updates);
          batchCount++;
          jobsRepaired++;

          if (batchCount >= 400) {
            await batch.commit();
            batch = FirebaseConfig.firestore.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      final bookingsSnapshot =
          await FirebaseConfig.firestore.collection('bookings').get();
      var bookingsBatch = FirebaseConfig.firestore.batch();
      int bookingsBatchCount = 0;

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        bool needsRepair = false;
        final updates = <String, dynamic>{};

        if (data['job_id'] is String) {
          final parsed = int.tryParse(data['job_id'] as String);
          if (parsed != null) {
            updates['job_id'] = parsed;
            needsRepair = true;
          }
        }

        if (data['client_id'] is String) {
          final parsed = int.tryParse(data['client_id'] as String);
          if (parsed != null) {
            updates['client_id'] = parsed;
            needsRepair = true;
          }
        }

        if (data['provider_id'] is String) {
          final parsed = int.tryParse(data['provider_id'] as String);
          if (parsed != null) {
            updates['provider_id'] = parsed;
            needsRepair = true;
          }
        }

        if (!data.containsKey('created_at')) {
          updates['created_at'] = FieldValue.serverTimestamp();
          needsRepair = true;
        }

        if (!data.containsKey('updated_at')) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          needsRepair = true;
        }

        if (needsRepair) {
          bookingsBatch.update(doc.reference, updates);
          bookingsBatchCount++;
          bookingsRepaired++;

          if (bookingsBatchCount >= 400) {
            await bookingsBatch.commit();
            bookingsBatch = FirebaseConfig.firestore.batch();
            bookingsBatchCount = 0;
          }
        }
      }

      if (bookingsBatchCount > 0) {
        await bookingsBatch.commit();
      }

      DebugLogger.log(
        'DataDoctor',
        'REPAIR_COMPLETE',
        data: {
          'jobsRepaired': jobsRepaired,
          'bookingsRepaired': bookingsRepaired,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Repaired: $jobsRepaired jobs, $bookingsRepaired bookings',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _loadDiagnostics();
      }
    } catch (e, stack) {
      DebugLogger.error('DataDoctor', 'REPAIR_ERROR', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Doctor (Debug)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy Diagnostics',
            onPressed: () async {
              final logs = DebugLogger.dump();
              await Clipboard.setData(ClipboardData(text: logs));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Diagnostics copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _migrateJobImages,
            icon: const Icon(Icons.image),
            label: const Text('Add job_images Field'),
            backgroundColor: Colors.blue,
            heroTag: 'migrate_images',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _repairLegacyData,
            icon: const Icon(Icons.build),
            label: const Text('Repair Legacy Data'),
            heroTag: 'repair_legacy',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : _diagnostics == null
              ? const Center(child: Text('Failed to load diagnostics'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Current User', [
                        _buildRow(
                          'User ID',
                          '${_diagnostics!['currentUserId'] ?? 'null'}',
                        ),
                        _buildRow(
                          'User ID (from SharedPreferences)',
                          '${_diagnostics!['currentUserIdFromPrefs'] ?? 'null'}',
                        ),
                        _buildRow(
                          'User ID (from Cubit)',
                          '${_diagnostics!['currentUserIdFromCubit'] ?? 'null'}',
                        ),
                        _buildRow(
                          'User ID Source',
                          '${_diagnostics!['userIdSource']}',
                        ),
                        _buildRow(
                          'User Type',
                          '${_diagnostics!['userType'] ?? 'null'}',
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Counts', [
                        _buildRow('Jobs', '${_diagnostics!['jobsCount']}'),
                        _buildRow(
                            'Bookings', '${_diagnostics!['bookingsCount']}'),
                        _buildRow(
                            'Profiles', '${_diagnostics!['profilesCount']}'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Last 5 Jobs', [
                        for (final job in _diagnostics!['lastJobs'] as List)
                          _buildJobCard(job),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Last 5 Bookings', [
                        for (final booking
                            in _diagnostics!['lastBookings'] as List)
                          _buildBookingCard(booking),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('docId', '${job['docId']}'),
          _buildRow('ID', '${job['id']}'),
          _buildRow('Title', '${job['title']}'),
          _buildRow(
            'client_id',
            '${job['client_id_value']} (${job['client_id_type']})',
          ),
          _buildRow('status', '${job['status']}'),
          _buildRow(
            'is_deleted',
            '${job['is_deleted_value']} (${job['is_deleted_type']})',
          ),
          _buildRow(
            'assigned_worker_id',
            '${job['assigned_worker_id_value']} (${job['assigned_worker_id_type']})',
          ),
          _buildRow(
            'agency_id',
            '${job['agency_id_value']} (${job['agency_id_type']})',
          ),
          _buildRow(
            'posted_date',
            '${job['posted_date']} (${job['posted_date_type']})',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('docId', '${booking['docId']}'),
          _buildRow('ID', '${booking['id']}'),
          _buildRow(
            'job_id',
            '${booking['job_id_value']} (${booking['job_id_type']})',
          ),
          _buildRow(
            'client_id',
            '${booking['client_id_value']} (${booking['client_id_type']})',
          ),
          _buildRow(
            'provider_id',
            '${booking['provider_id_value']} (${booking['provider_id_type']})',
          ),
          _buildRow('status', '${booking['status']}'),
          _buildRow(
            'created_at',
            '${booking['created_at']} (${booking['created_at_type']})',
          ),
        ],
      ),
    );
  }
}
