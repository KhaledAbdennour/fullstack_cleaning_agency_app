import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Firestore client singleton
class FirebaseConfig {
  static FirebaseFirestore? _firestore;

  /// Initialize Firebase (should be called after Firebase.initializeApp())
  static Future<void> initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;
      // Enable offline persistence
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  /// Get the Firestore instance
  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Get a collection reference
  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  /// Get a document reference
  static DocumentReference<Map<String, dynamic>> doc(
    String collectionPath,
    String docId,
  ) {
    return firestore.collection(collectionPath).doc(docId);
  }
}
