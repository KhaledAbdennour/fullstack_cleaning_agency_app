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
  final int? clientId;
  final int? agencyId;
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
    this.clientId,
    this.agencyId,
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
      case JobStatus.active:
        return 'Active';
      case JobStatus.paused:
        return 'Paused';
      case JobStatus.booked:
        return 'Booked';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.inProgress:
        return 'In Progress';
    }
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
      'client_id': clientId,
      'agency_id': agencyId,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'estimated_hours': estimatedHours,
      'required_services': requiredServices != null ? requiredServices!.join(',') : null,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    JobStatus jobStatus = JobStatus.active;
    if (map['status'] != null) {
      final statusStr = map['status'].toString();
      try {
        jobStatus = JobStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => JobStatus.active,
        );
      } catch (e) {
        jobStatus = JobStatus.active;
      }
    }

    DateTime postedDate;
    try {
      postedDate = DateTime.parse(map['posted_date'] as String? ?? DateTime.now().toIso8601String());
    } catch (e) {
      postedDate = DateTime.now();
    }

    DateTime jobDate;
    try {
      jobDate = DateTime.parse(map['job_date'] as String? ?? DateTime.now().toIso8601String());
    } catch (e) {
      jobDate = DateTime.now();
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
      clientId: map['client_id'] as int?,
      agencyId: map['agency_id'] as int?,
      budgetMin: map['budget_min'] != null ? (map['budget_min'] as num).toDouble() : null,
      budgetMax: map['budget_max'] != null ? (map['budget_max'] as num).toDouble() : null,
      estimatedHours: map['estimated_hours'] as int?,
      requiredServices: map['required_services'] != null 
          ? (map['required_services'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
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
    int? clientId,
    int? agencyId,
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
      clientId: clientId ?? this.clientId,
      agencyId: agencyId ?? this.agencyId,
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
  active,
  paused,
  booked,
  completed,
  inProgress,
}

