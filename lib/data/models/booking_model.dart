class Booking {
  final int? id;
  final int jobId;
  final int clientId;
  final int? providerId; 
  final BookingStatus status;
  final double? bidPrice; 
  final String? message; 
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    this.id,
    required this.jobId,
    required this.clientId,
    this.providerId,
    required this.status,
    this.bidPrice,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'client_id': clientId,
      'provider_id': providerId,
      'status': status.name,
      'bid_price': bidPrice,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      jobId: map['job_id'] as int,
      clientId: map['client_id'] as int,
      providerId: map['provider_id'] as int?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      bidPrice: map['bid_price'] != null ? (map['bid_price'] as num).toDouble() : null,
      message: map['message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Booking copyWith({
    int? id,
    int? jobId,
    int? clientId,
    int? providerId,
    BookingStatus? status,
    double? bidPrice,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      bidPrice: bidPrice ?? this.bidPrice,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BookingStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

