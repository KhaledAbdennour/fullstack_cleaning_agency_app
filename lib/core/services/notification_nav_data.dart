import '../../data/models/notification_item.dart';

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

  factory NotificationNavData.fromNotification(NotificationItem notification) {
    int? jobId = notification.jobId;
    String? notificationType = notification.type;
    int? senderId = notification.senderId != null
        ? int.tryParse(notification.senderId!)
        : null;

    String? route;
    String? routeId;
    int? bookingId;
    int? cleanerId;
    int? workerId;
    int? clientId;
    int? agencyId;

    if (notification.data != null) {
      final data = notification.data!;

      route = data['route']?.toString();

      routeId = data['id']?.toString() ??
          data['routeId']?.toString() ??
          data['jobId']?.toString() ??
          data['bookingId']?.toString();

      final bookingIdStr =
          data['bookingId']?.toString() ?? data['booking_id']?.toString();
      if (bookingIdStr != null) {
        bookingId = int.tryParse(bookingIdStr);
      }

      final workerIdStr =
          data['workerId']?.toString() ?? data['worker_id']?.toString();
      if (workerIdStr != null) {
        workerId = int.tryParse(workerIdStr);
      }

      final clientIdStr =
          data['clientId']?.toString() ?? data['client_id']?.toString();
      if (clientIdStr != null) {
        clientId = int.tryParse(clientIdStr);
      }

      final agencyIdStr =
          data['agencyId']?.toString() ?? data['agency_id']?.toString();
      if (agencyIdStr != null) {
        agencyId = int.tryParse(agencyIdStr);
      }

      final cleanerIdStr = data['cleanerId']?.toString() ??
          data['cleaner_id']?.toString() ??
          data['senderId']?.toString() ??
          data['sender_id']?.toString();
      if (cleanerIdStr != null) {
        cleanerId = int.tryParse(cleanerIdStr);
      }

      if (jobId == null) {
        final jobIdStr =
            data['jobId']?.toString() ?? data['job_id']?.toString();
        if (jobIdStr != null) {
          jobId = int.tryParse(jobIdStr);
        }
      }
    }

    if (jobId == null && routeId != null) {
      final parsed = int.tryParse(routeId);
      if (parsed != null && notificationType != null) {
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

  bool get isValid => route != null || notificationType != null;

  @override
  String toString() {
    return 'NotificationNavData(route: $route, routeId: $routeId, jobId: $jobId, bookingId: $bookingId, type: $notificationType)';
  }
}
