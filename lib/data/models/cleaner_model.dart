class Cleaner {
  final int? id;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int jobsCompleted;
  final int agencyId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cleaner({
    this.id,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.jobsCompleted,
    required this.agencyId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'rating': rating,
      'jobs_completed': jobsCompleted,
      'agency_id': agencyId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Cleaner.fromMap(Map<String, dynamic> map) {
    return Cleaner(
      id: map['id'] as int?,
      name: map['name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      rating: (map['rating'] as num).toDouble(),
      jobsCompleted: map['jobs_completed'] as int,
      agencyId: map['agency_id'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Cleaner copyWith({
    int? id,
    String? name,
    String? avatarUrl,
    double? rating,
    int? jobsCompleted,
    int? agencyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cleaner(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      agencyId: agencyId ?? this.agencyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

