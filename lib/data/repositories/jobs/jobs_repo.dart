import '../../models/job_model.dart';
import 'jobs_repo_db.dart';


abstract class AbstractJobsRepo {
  Future<List<Job>> getActiveJobsForAgency(int agencyId);
  Future<List<Job>> getPastJobsForAgency(int agencyId);
  Future<List<Job>> getAllJobsForAgency(int agencyId);
  Future<List<Job>> getAvailableJobsForAgency(int agencyId); 
  Future<List<Job>> getJobsForClient(int clientId); 
  Future<List<Job>> getRecentClientJobs({int limit = 10}); 
  Future<Job?> getJobById(int jobId);
  Future<Job> createJob(Job job);
  Future<Job> updateJob(Job job);
  Future<void> deleteJob(int jobId);
  Future<void> changeJobStatus(int jobId, JobStatus status);
  Future<int> getTotalJobsCompletedForAgency(int agencyId);
  
  // Completion confirmation methods
  Future<Job> markClientDone(int jobId);
  Future<Job> markWorkerDone(int jobId);
  Future<void> markJobStarted(int jobId); // Mark job as in progress
  Future<void> cancelJob(int jobId); // Client cancels job
  
  // Active and completed jobs for workers and clients
  Future<List<Job>> getActiveJobsForWorker(int workerId);
  Future<List<Job>> getCompletedJobsForWorker(int workerId);
  Future<List<Job>> getActiveJobsForClient(int clientId);
  Future<List<Job>> getCompletedJobsForClient(int clientId);
  Future<void> markAllClientJobsAsDeleted(int clientId); // Mark all client's jobs as deleted

  static AbstractJobsRepo? _instance;
  static AbstractJobsRepo getInstance() {
    _instance ??= JobsDB();
    return _instance!;
  }
}

