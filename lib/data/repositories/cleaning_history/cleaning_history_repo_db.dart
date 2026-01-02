import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/cleaning_history_item.dart';
import 'cleaning_history_repo.dart';

// Import Query type
import 'package:cloud_firestore/cloud_firestore.dart' show Query;

class CleaningHistoryDB extends AbstractCleaningHistoryRepo {
  static const String collectionName = 'cleaning_history';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $collectionName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cleaner_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      job_id INTEGER,
      FOREIGN KEY (cleaner_id) REFERENCES profiles(id),
      FOREIGN KEY (job_id) REFERENCES jobs(id)
    )
  ''';

  @override
  Future<List<CleaningHistoryItem>> getCleaningHistoryForCleaner(int cleanerId, {int page = 1, int limit = 10}) async {
    try {
      // Firestore doesn't support offset, so we use limit with startAfter for pagination
      // For simplicity, we'll just use limit for now (page 1 only)
      // TODO: Implement proper cursor-based pagination if needed
      Query query = FirebaseConfig.firestore
          .collection(collectionName)
          .where('cleaner_id', isEqualTo: cleanerId)
          .orderBy('date', descending: true)
          .limit(limit);
      
      // For pages > 1, we would need to store the last document and use startAfter
      // For now, just return first page
      if (page > 1) {
        // TODO: Implement cursor-based pagination
        return [];
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final docData = doc.data();
        final data = docData != null ? Map<String, dynamic>.from(docData) : <String, dynamic>{};
        data['id'] = int.tryParse(doc.id) ?? 0;
        return CleaningHistoryItem.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getCleaningHistoryForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleaningHistoryItem> addHistoryItem(CleaningHistoryItem item) async {
    try {
      final itemMap = item.toMap();
      final id = itemMap.remove('id');
      
      String docId;
      if (id != null && id is int) {
        docId = id.toString();
      } else {
        // Generate new ID
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .orderBy('id', descending: true)
            .limit(1)
            .get();
        
        int newId = 1;
        if (snapshot.docs.isNotEmpty) {
          final maxId = snapshot.docs.first.data()['id'] as int? ?? 0;
          newId = maxId + 1;
        }
        docId = newId.toString();
        itemMap['id'] = newId;
      }
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(itemMap);
      
      final data = Map<String, dynamic>.from(itemMap);
      data['id'] = int.parse(docId);
      return CleaningHistoryItem.fromMap(data);
    } catch (e, stacktrace) {
      print('addHistoryItem error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteHistoryItem(int itemId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(itemId.toString())
          .delete();
    } catch (e, stacktrace) {
      print('deleteHistoryItem error: $e --> $stacktrace');
      rethrow;
    }
  }
}

extension CleaningHistoryItemCopyWith on CleaningHistoryItem {
  CleaningHistoryItem copyWith({
    int? id,
    int? cleanerId,
    String? title,
    DateTime? date,
    String? description,
    CleaningHistoryType? type,
    int? jobId,
  }) {
    return CleaningHistoryItem(
      id: id ?? this.id,
      cleanerId: cleanerId ?? this.cleanerId,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      jobId: jobId ?? this.jobId,
    );
  }
}
