import '../../data/models/notification_item.dart';

/// Helper class to parse and normalize notification navigation data
/// Extracts route, IDs, and other navigation parameters from notification payload
class NotificationNavData {
  final String? route;
  final String? routeId;
  final int? jobId;
  final int? bookingId;
  final int? senderId;
  final int? cleanerId;
  final int? workerId;
  final int? clientId;
  final int? agencyId;
  final String? notificationType;
  
  NotificationNavData({
    this.route,
    this.routeId,
    this.jobId,
    this.bookingId,
    this.senderId,
    this.cleanerId,
    this.workerId,
    this.clientId,
    this.agencyId,
    this.notificationType,
  });
  
  /// Parse navigation data from a NotificationItem
  /// Safely extracts all relevant fields from data map, type, and direct fields
  factory NotificationNavData.fromNotification(NotificationItem notification) {
    // Start with direct fields from notification
    int? jobId = notification.jobId;
    String? notificationType = notification.type;
    int? senderId = notification.senderId != null 
        ? int.tryParse(notification.senderId!) 
        : null;
    
    // Extract from data map if present
    String? route;
    String? routeId;
    int? bookingId;
    int? cleanerId;
    int? workerId;
    int? clientId;
    int? agencyId;
    
    if (notification.data != null) {
      final data = notification.data!;
      
      // Route can be in 'route' field
      route = data['route']?.toString();
      
      // ID can be in 'id', 'routeId', 'jobId', 'bookingId'
      routeId = data['id']?.toString() ?? 
                data['routeId']?.toString() ?? 
                data['jobId']?.toString() ?? 
                data['bookingId']?.toString();
      
      // Try to parse booking ID
      final bookingIdStr = data['bookingId']?.toString() ?? data['booking_id']?.toString();
      if (bookingIdStr != null) {
        bookingId = int.tryParse(bookingIdStr);
      }
      
      // Try to parse worker ID
      final workerIdStr = data['workerId']?.toString() ?? data['worker_id']?.toString();
      if (workerIdStr != null) {
        workerId = int.tryParse(workerIdStr);
      }
      
      // Try to parse client ID
      final clientIdStr = data['clientId']?.toString() ?? data['client_id']?.toString();
      if (clientIdStr != null) {
        clientId = int.tryParse(clientIdStr);
      }
      
      // Try to parse agency ID
      final agencyIdStr = data['agencyId']?.toString() ?? data['agency_id']?.toString();
      if (agencyIdStr != null) {
        agencyId = int.tryParse(agencyIdStr);
      }
      
      // Try to parse cleaner ID (for review notifications)
      final cleanerIdStr = data['cleanerId']?.toString() ?? 
                          data['cleaner_id']?.toString() ?? 
                          data['senderId']?.toString() ?? 
                          data['sender_id']?.toString();
      if (cleanerIdStr != null) {
        cleanerId = int.tryParse(cleanerIdStr);
      }
      
      // If jobId not set from direct field, try from data
      if (jobId == null) {
        final jobIdStr = data['jobId']?.toString() ?? data['job_id']?.toString();
        if (jobIdStr != null) {
          jobId = int.tryParse(jobIdStr);
        }
      }
    }
    
    // If routeId is set but jobId is not, try to parse routeId as jobId
    if (jobId == null && routeId != null) {
      final parsed = int.tryParse(routeId);
      if (parsed != null && notificationType != null) {
        // If type suggests it's a job-related notification, assume routeId is jobId
        if (notificationType.contains('job')) {
          jobId = parsed;
        }
      }
    }
    
    return NotificationNavData(
      route: route,
      routeId: routeId,
      jobId: jobId,
      bookingId: bookingId,
      senderId: senderId,
      cleanerId: cleanerId,
      workerId: workerId,
      clientId: clientId,
      agencyId: agencyId,
      notificationType: notificationType,
    );
  }
  
  /// Check if navigation data is valid (has at least route or type-based target)
  bool get isValid => route != null || notificationType != null;
  
  @override
  String toString() {
    return 'NotificationNavData(route: $route, routeId: $routeId, jobId: $jobId, bookingId: $bookingId, type: $notificationType)';
  }
}

