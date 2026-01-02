import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../../models/cleaner_model.dart';
import 'cleaners_repo.dart';

class CleanersDB extends AbstractCleanersRepo {
  static const String collectionName = 'cleaners';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $collectionName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      avatar_url TEXT,
      rating REAL NOT NULL DEFAULT 0.0,
      jobs_completed INTEGER NOT NULL DEFAULT 0,
      agency_id INTEGER NOT NULL,
      is_active INTEGER DEFAULT 1,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (agency_id) REFERENCES profiles(id)
    )
  ''';

  @override
  Future<List<Cleaner>> getCleanersForAgency(int agencyId) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('agency_id', isEqualTo: agencyId)
          .where('is_active', isEqualTo: true)
          .orderBy('jobs_completed', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Cleaner.fromMap(data);
      }).toList();
    } catch (e, stacktrace) {
      print('getCleanersForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Cleaner?> getCleanerById(int cleanerId) async {
    try {
      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(cleanerId.toString())
          .get();
      
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = cleanerId;
      return Cleaner.fromMap(data);
    } catch (e, stacktrace) {
      print('getCleanerById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Cleaner> addCleaner(Cleaner cleaner) async {
    try {
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toMap();
      final id = cleanerMap.remove('id');
      cleanerMap['created_at'] = Timestamp.fromDate(now);
      cleanerMap['updated_at'] = Timestamp.fromDate(now);
      
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
        cleanerMap['id'] = newId;
      }
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(cleanerMap);
      
      final data = cleanerMap;
      data['id'] = int.parse(docId);
      return Cleaner.fromMap(data);
    } catch (e, stacktrace) {
      print('addCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Cleaner> updateCleaner(Cleaner cleaner) async {
    try {
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(updatedAt: now).toMap();
      cleanerMap.remove('id');
      cleanerMap['updated_at'] = Timestamp.fromDate(now);
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(cleaner.id.toString())
          .update(cleanerMap);
      
      return cleaner.copyWith(updatedAt: now);
    } catch (e, stacktrace) {
      print('updateCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> removeCleaner(int cleanerId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(cleanerId.toString())
          .update({
            'is_active': false,
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e, stacktrace) {
      print('removeCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }
}
