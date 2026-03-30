import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  static FirebaseFirestore? _firestore;

  static Future<void> initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;

      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> doc(
    String collectionPath,
    String docId,
  ) {
    return firestore.collection(collectionPath).doc(docId);
  }
}
