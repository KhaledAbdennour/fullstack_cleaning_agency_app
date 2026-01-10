import '../../core/utils/firestore_type.dart';

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
    // Use unified type helpers for safe parsing
    final jobId = readInt(map['job_id']);
    if (jobId == null) {
      throw Exception(
        'Invalid job_id in booking: ${map['job_id']} (type: ${map['job_id']?.runtimeType})',
      );
    }

    final clientId = readInt(map['client_id']);
    if (clientId == null) {
      throw Exception(
        'Invalid client_id in booking: ${map['client_id']} (type: ${map['client_id']?.runtimeType})',
      );
    }

    final providerId = readInt(map['provider_id']);

    // Parse dates using unified helper
    final createdAt = readDate(map['created_at']) ?? DateTime.now();
    final updatedAt = readDate(map['updated_at']) ?? DateTime.now();

    return Booking(
      id: readInt(map['id']),
      jobId: jobId,
      clientId: clientId,
      providerId: providerId,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status']?.toString(),
        orElse: () => BookingStatus.pending,
      ),
      bidPrice: readDouble(map['bid_price']),
      message: readString(map['message']),
      createdAt: createdAt,
      updatedAt: updatedAt,
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

enum BookingStatus { pending, inProgress, completed, cancelled }
