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
      if (!profile.containsKey('created_at') || profile['created_at'] == null) {
        profile['created_at'] = FieldValue.serverTimestamp();
      }

      if (!profile.containsKey('updated_at') || profile['updated_at'] == null) {
        profile['updated_at'] = FieldValue.serverTimestamp();
      }

      if (!profile.containsKey('picture')) {
        profile['picture'] = null;
      }

      final id = profile.remove('id');
      final profileData = Map<String, dynamic>.from(profile);

      String docId;
      if (id != null && id is int) {
        docId = id.toString();
      } else {
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
        profileData['id'] = newId;
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
      if (profile.isEmpty) {
        print('updateProfile: profile data is empty');
        return false;
      }

      profile['updated_at'] = FieldValue.serverTimestamp();

      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(id.toString());

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('updateProfile: Document with id $id does not exist');
        return false;
      }

      await docRef.update(profile);
      return true;
    } catch (e, stacktrace) {
      print('updateProfile error: $e --> $stacktrace');

      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Permission denied: Unable to update profile');
      } else if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        throw Exception('Profile not found');
      }
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
      print('updateAvatarUrl called: userId=$userId, url=$url');

      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(userId.toString());

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('updateAvatarUrl error: Document with id $userId does not exist');
        return false;
      }

      await docRef.update({
        'picture': url,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print(
        'updateAvatarUrl success: picture field updated with base64 data URL',
      );
      return true;
    } catch (e, stacktrace) {
      print('updateAvatarUrl error: $e --> $stacktrace');
      print('updateAvatarUrl error details: userId=$userId, url=$url');
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
