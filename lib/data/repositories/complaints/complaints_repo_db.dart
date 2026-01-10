import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/complaint_model.dart';
import 'complaints_repo.dart';

class ComplaintsDB extends AbstractComplaintsRepo {
  static const String collectionName = 'complaints';

  @override
  Future<Complaint> createComplaint(Complaint complaint) async {
    try {
      // Generate ID if not provided
      int complaintId = complaint.id ?? 0;
      if (complaintId == 0) {
        // Get the highest ID and increment
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .orderBy('id', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final maxId = snapshot.docs.first.data()['id'] as int? ?? 0;
          complaintId = maxId + 1;
        } else {
          complaintId = 1;
        }
      }

      final data = complaint.copyWith(id: complaintId).toMap();
      data.remove('id'); // Remove id from data, use as document ID

      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(complaintId.toString())
          .set(data);

      return complaint.copyWith(id: complaintId);
    } catch (e, stackTrace) {
      print('createComplaint error: $e --> $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Complaint>> getComplaintsByUser(int userId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Complaint.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      print('getComplaintsByUser error: $e --> $stackTrace');
      return [];
    }
  }

  @override
  Future<Complaint?> getComplaintById(int complaintId) async {
    try {
      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(complaintId.toString())
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = complaintId;
      return Complaint.fromMap(data);
    } catch (e, stackTrace) {
      print('getComplaintById error: $e --> $stackTrace');
      return null;
    }
  }

  @override
  Future<List<Complaint>> getAllComplaints() async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Complaint.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      print('getAllComplaints error: $e --> $stackTrace');
      return [];
    }
  }

  @override
  Future<Complaint> updateComplaintStatus(
    int complaintId,
    ComplaintStatus status,
  ) async {
    try {
      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(complaintId.toString());

      await docRef.update({
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await docRef.get();
      final data = updatedDoc.data()!;
      data['id'] = complaintId;
      return Complaint.fromMap(data);
    } catch (e, stackTrace) {
      print('updateComplaintStatus error: $e --> $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteComplaint(int complaintId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(complaintId.toString())
          .delete();
    } catch (e, stackTrace) {
      print('deleteComplaint error: $e --> $stackTrace');
      rethrow;
    }
  }
}
