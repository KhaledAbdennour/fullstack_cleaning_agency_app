import 'dart:async';

class JobUpdateNotifier {
  static final JobUpdateNotifier _instance = JobUpdateNotifier._internal();
  factory JobUpdateNotifier() => _instance;
  JobUpdateNotifier._internal();

  final _jobUpdateController = StreamController<int>.broadcast();

  Stream<int> get workerJobsUpdateStream => _jobUpdateController.stream;

  void notifyWorkerJobsUpdate(int workerId) {
    _jobUpdateController.add(workerId);
  }

  void dispose() {
    _jobUpdateController.close();
  }
}
