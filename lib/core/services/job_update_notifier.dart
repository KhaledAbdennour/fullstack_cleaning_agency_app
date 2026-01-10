import 'dart:async';

/// Global notifier for job updates
/// Used to notify UI when jobs change (e.g., after acceptance)
class JobUpdateNotifier {
  static final JobUpdateNotifier _instance = JobUpdateNotifier._internal();
  factory JobUpdateNotifier() => _instance;
  JobUpdateNotifier._internal();

  final _jobUpdateController = StreamController<int>.broadcast();

  /// Stream of worker IDs whose active jobs should be refreshed
  Stream<int> get workerJobsUpdateStream => _jobUpdateController.stream;

  /// Notify that a worker's active jobs should be refreshed
  void notifyWorkerJobsUpdate(int workerId) {
    _jobUpdateController.add(workerId);
  }

  void dispose() {
    _jobUpdateController.close();
  }
}
