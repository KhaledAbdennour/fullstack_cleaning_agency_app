import '../../models/complaint_model.dart';
import 'complaints_repo_db.dart';

abstract class AbstractComplaintsRepo {
  Future<Complaint> createComplaint(Complaint complaint);
  Future<List<Complaint>> getComplaintsByUser(int userId);
  Future<Complaint?> getComplaintById(int complaintId);
  Future<List<Complaint>> getAllComplaints();
  Future<Complaint> updateComplaintStatus(
    int complaintId,
    ComplaintStatus status,
  );
  Future<void> deleteComplaint(int complaintId);

  static AbstractComplaintsRepo? _instance;
  static AbstractComplaintsRepo getInstance() {
    _instance ??= ComplaintsDB();
    return _instance!;
  }
}
