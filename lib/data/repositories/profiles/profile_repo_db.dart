import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import 'profile_repo.dart';

class ProfileDB extends AbstractProfileRepo {
  static const String collectionName = 'profiles';
  static const String _currentUserIdKey = 'current_user_id';

  @override
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? 0;
        // Ensure picture field exists (null if not present) for consistency
        if (!data.containsKey('picture')) {
          data['picture'] = null;
        }
        return data;
      }).toList();
    } catch (e, stacktrace) {
      print('getAllProfiles error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileById(int id) async {
    try {
      final doc = await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(id.toString())
          .get();
      
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = id;
      // Ensure picture field exists (null if not present) for consistency
      if (!data.containsKey('picture')) {
        data['picture'] = null;
      }
      return data;
    } catch (e, stacktrace) {
      print('getProfileById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = int.tryParse(doc.id) ?? 0;
      // Ensure picture field exists (null if not present) for consistency
      if (!data.containsKey('picture')) {
        data['picture'] = null;
      }
      return data;
    } catch (e, stacktrace) {
      print('getProfileByUsername error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = int.tryParse(doc.id) ?? 0;
      // Ensure picture field exists (null if not present) for consistency
      if (!data.containsKey('picture')) {
        data['picture'] = null;
      }
      return data;
    } catch (e, stacktrace) {
      print('getProfileByEmail error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByPhone(String phone) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = int.tryParse(doc.id) ?? 0;
      // Ensure picture field exists (null if not present) for consistency
      if (!data.containsKey('picture')) {
        data['picture'] = null;
      }
      return data;
    } catch (e, stacktrace) {
      print('getProfileByPhone error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final snapshot = await FirebaseConfig.firestore
          .collection(collectionName)
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      final userId = int.tryParse(doc.id) ?? 0;
      data['id'] = userId;
      // Ensure picture field exists (null if not present) for consistency
      if (!data.containsKey('picture')) {
        data['picture'] = null;
      }
      
      await setCurrentUser(userId);
      return data;
    } catch (e, stacktrace) {
      print('login error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<bool> insertProfile(Map<String, dynamic> profile) async {
    try {
      // Ensure created_at is set
      if (!profile.containsKey('created_at') || profile['created_at'] == null) {
        profile['created_at'] = FieldValue.serverTimestamp();
      }
      
      // Ensure updated_at is set (same as created_at for new profiles)
      if (!profile.containsKey('updated_at') || profile['updated_at'] == null) {
        profile['updated_at'] = FieldValue.serverTimestamp();
      }
      
      // Initialize picture field - always include it in profile (null if not provided)
      // This ensures the field exists in Firestore even if no avatar is uploaded initially
      if (!profile.containsKey('picture')) {
        profile['picture'] = null;
      }
      
      // Profile fields that can be included:
      // - picture: String? (URL to profile picture in Firebase Storage) - now always initialized
      // - Other fields are handled by the profile data map
      
      // Remove id if present (Firestore will generate or use provided doc ID)
      final id = profile.remove('id');
      final profileData = Map<String, dynamic>.from(profile);
      
      // Use provided ID or generate new one
      String docId;
      if (id != null && id is int) {
        docId = id.toString();
      } else {
        // Generate new ID - get max ID and increment
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
        profileData['id'] = newId; // Store numeric ID in document
      }
      
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(docId)
          .set(profileData);
      
      final userId = int.parse(docId);
      await setCurrentUser(userId);
      return true;
    } catch (e, stacktrace) {
      print('insertProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> updateProfile(int id, Map<String, dynamic> profile) async {
    try {
      profile['updated_at'] = FieldValue.serverTimestamp();
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(id.toString())
          .update(profile);
      return true;
    } catch (e, stacktrace) {
      print('updateProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> deleteProfile(int id) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(id.toString())
          .delete();
      return true;
    } catch (e, stacktrace) {
      print('deleteProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> updateAvatarUrl(int userId, String? url) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(userId.toString())
          .update({
        'picture': url,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e, stacktrace) {
      print('updateAvatarUrl error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> removeAvatar(int userId) async {
    try {
      await FirebaseConfig.firestore
          .collection(collectionName)
          .doc(userId.toString())
          .update({
        'picture': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e, stacktrace) {
      print('removeAvatar error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_currentUserIdKey);
      if (userId == null) return null;
      // getProfileById already normalizes picture, so we can just return it
      return await getProfileById(userId);
    } catch (e, stacktrace) {
      print('getCurrentUser error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<bool> setCurrentUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentUserIdKey, userId);
      return true;
    } catch (e, stacktrace) {
      print('setCurrentUser error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserIdKey);
      return true;
    } catch (e, stacktrace) {
      print('clearCurrentUser error: $e --> $stacktrace');
      return false;
    }
  }
}
