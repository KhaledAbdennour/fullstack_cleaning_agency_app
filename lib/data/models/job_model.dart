import '../../core/utils/firestore_type.dart';

class Job {
  final int? id;
  final String title;
  final String city;
  final String country;
  final String description;
  final JobStatus status;
  final DateTime postedDate;
  final DateTime jobDate;
  final String? coverImageUrl;
  final List<String>? jobImages; // All job images (up to 5), stored as base64 data URLs
  final int? clientId;
  final int? agencyId;
  final int? assignedWorkerId; // Worker/cleaner assigned to this job
  final bool clientDone; // Client confirmed completion
  final bool workerDone; // Worker confirmed completion
  final double? budgetMin;
  final double? budgetMax;
  final int? estimatedHours;
  final List<String>? requiredServices;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Job({
    this.id,
    required this.title,
    required this.city,
    required this.country,
    required this.description,
    required this.status,
    required this.postedDate,
    required this.jobDate,
    this.coverImageUrl,
    this.jobImages,
    this.clientId,
    this.agencyId,
    this.assignedWorkerId,
    this.clientDone = false,
    this.workerDone = false,
    this.budgetMin,
    this.budgetMax,
    this.estimatedHours,
    this.requiredServices,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullLocation => '$city, $country';

  String get statusLabel {
    switch (status) {
      case JobStatus.open:
        return 'Open';
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completedPendingConfirmation:
        return 'Pending Confirmation';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
      // Legacy mappings
      case JobStatus.active:
        return 'Active';
      case JobStatus.paused:
        return 'Paused';
      case JobStatus.booked:
        return 'Assigned';
    }
  }
  
  /// Check if job is available for workers to apply
  bool get isAvailableForApplication {
    return (status == JobStatus.open || status == JobStatus.pending || status == JobStatus.active) &&
           assignedWorkerId == null &&
           !isDeleted;
  }
  
  /// Check if job is completed (both parties confirmed)
  bool get isCompleted {
    return status == JobStatus.completed || (clientDone && workerDone);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'city': city,
      'country': country,
      'description': description,
      'status': status.name,
      'posted_date': postedDate.toIso8601String(),
      'job_date': jobDate.toIso8601String(),
      'cover_image_url': coverImageUrl,
      'job_images': jobImages ?? <String>[], // List of base64 data URLs (up to 5 images), empty array if null
      'client_id': clientId,
      'agency_id': agencyId,
      'assigned_worker_id': assignedWorkerId,
      'client_done': clientDone, // Write as bool (Firestore supports bool)
      'worker_done': workerDone,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'estimated_hours': estimatedHours,
      'required_services': requiredServices != null ? requiredServices!.join(',') : null,
      // store as bool for Firestore; legacy data may still have int
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    JobStatus jobStatus = JobStatus.open;
    if (map['status'] != null) {
      final statusStr = map['status'].toString();
      try {
        // Try to find exact match first
        jobStatus = JobStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () {
            // Map legacy statuses to new ones
            switch (statusStr) {
              case 'active':
                return JobStatus.open;
              case 'booked':
                return JobStatus.assigned;
              case 'paused':
                return JobStatus.cancelled;
              default:
                return JobStatus.open;
            }
          },
        );
      } catch (e) {
        jobStatus = JobStatus.open;
      }
    }

    DateTime postedDate;
    final postedDateValue = readDate(map['posted_date']);
    if (postedDateValue != null) {
      postedDate = postedDateValue;
    } else {
      // Fallback: try parsing as string
      try {
        postedDate = DateTime.parse(map['posted_date'] as String? ?? DateTime.now().toIso8601String());
      } catch (e) {
        postedDate = DateTime.now();
      }
    }

    DateTime jobDate;
    final jobDateValue = readDate(map['job_date']);
    if (jobDateValue != null) {
      jobDate = jobDateValue;
    } else {
      // Fallback: try parsing as string
      try {
        jobDate = DateTime.parse(map['job_date'] as String? ?? DateTime.now().toIso8601String());
      } catch (e) {
        jobDate = DateTime.now();
      }
    }

    return Job(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled Job',
      city: map['city'] as String? ?? 'Unknown',
      country: map['country'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? 'No description available',
      status: jobStatus,
      postedDate: postedDate,
      jobDate: jobDate,
      coverImageUrl: map['cover_image_url'] as String?,
      jobImages: map['job_images'] != null 
          ? (map['job_images'] as List<dynamic>).map((e) => e.toString()).toList()
          : null, // Backward compatible: defaults to null if not present
      clientId: readInt(map['client_id']),
      agencyId: readInt(map['agency_id']),
      assignedWorkerId: readInt(map['assigned_worker_id']),
      clientDone: readBool(map['client_done']),
      workerDone: readBool(map['worker_done']),
      budgetMin: map['budget_min'] != null ? (map['budget_min'] as num).toDouble() : null,
      budgetMax: map['budget_max'] != null ? (map['budget_max'] as num).toDouble() : null,
      estimatedHours: map['estimated_hours'] as int?,
      requiredServices: map['required_services'] != null 
          ? (map['required_services'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      isDeleted: readBool(map['is_deleted']),
      createdAt: map['created_at'] != null
          ? (() {
              try {
                return DateTime.parse(map['created_at'] as String);
              } catch (e) {
                return null;
              }
            })()
          : null,
      updatedAt: map['updated_at'] != null
          ? (() {
              try {
                return DateTime.parse(map['updated_at'] as String);
              } catch (e) {
                return null;
              }
            })()
          : null,
    );
  }

  Job copyWith({
    int? id,
    String? title,
    String? city,
    String? country,
    String? description,
    JobStatus? status,
    DateTime? postedDate,
    DateTime? jobDate,
    String? coverImageUrl,
    List<String>? jobImages,
    int? clientId,
    int? agencyId,
    int? assignedWorkerId,
    bool? clientDone,
    bool? workerDone,
    double? budgetMin,
    double? budgetMax,
    int? estimatedHours,
    List<String>? requiredServices,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      country: country ?? this.country,
      description: description ?? this.description,
      status: status ?? this.status,
      postedDate: postedDate ?? this.postedDate,
      jobDate: jobDate ?? this.jobDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      jobImages: jobImages ?? this.jobImages,
      clientId: clientId ?? this.clientId,
      agencyId: agencyId ?? this.agencyId,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      clientDone: clientDone ?? this.clientDone,
      workerDone: workerDone ?? this.workerDone,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      requiredServices: requiredServices ?? this.requiredServices,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum JobStatus {
  // Job lifecycle states
  open,        // Job is open and visible to workers (can apply)
  pending,     // Workers can apply, client reviewing applicants
  assigned,    // ONE worker accepted (job disappears from others)
  inProgress,  // Job is in progress
  completedPendingConfirmation, // One party marked finished, waiting for other
  completed,   // Both confirmed completion
  cancelled,   // Job cancelled
  
  // Legacy states (mapped for backward compatibility)
  active,      // Maps to 'open'
  paused,      // Maps to 'cancelled' or 'pending'
  booked,      // Maps to 'assigned'
}

