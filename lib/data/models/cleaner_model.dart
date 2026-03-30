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
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Cleaner.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      if (v.runtimeType.toString() == 'Timestamp') {
        try {
          return v.toDate();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      return false;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return Cleaner(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown',
      avatarUrl: map['avatar_url'] as String?,
      rating: parseDouble(map['rating']),
      jobsCompleted: parseInt(map['jobs_completed']),
      agencyId: parseInt(map['agency_id']),
      isActive: parseBool(map['is_active'] ?? true),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
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
