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
      // If picture is provided, it should be a base64 data URL (e.g., "data:image/jpeg;base64,...")
      if (!profile.containsKey('picture')) {
        profile['picture'] = null;
      }

      // Profile fields that can be included:
      // - picture: String? (Base64 data URL for profile picture, e.g., "data:image/jpeg;base64,...")
      // - services: String? (Comma-separated list of services, e.g., "Home, Office, Industrial")
      // - experience_level: String? (For Agency/Individual Cleaner: "Entry", "Mid", or "Senior")
      // - hourly_rate: String? (Hourly rate as string, e.g., "3000")
      // - agency_name: String? (For Agency role)
      // - business_id: String? (For Agency role)
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
      // Ensure profile is not empty
      if (profile.isEmpty) {
        print('updateProfile: profile data is empty');
        return false;
      }

      // Add updated_at timestamp
      profile['updated_at'] = FieldValue.serverTimestamp();

      // Check if document exists before updating
      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(id.toString());

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('updateProfile: Document with id $id does not exist');
        return false;
      }

      // Perform the update
      await docRef.update(profile);
      return true;
    } catch (e, stacktrace) {
      print('updateProfile error: $e --> $stacktrace');
      // Re-throw specific errors that should be handled upstream
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

      // Verify document exists
      final docRef = FirebaseConfig.firestore
          .collection(collectionName)
          .doc(userId.toString());

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('updateAvatarUrl error: Document with id $userId does not exist');
        return false;
      }

      // Update the picture field with the base64 data URL
      // Note: url can be null to remove the picture, or a String (base64 data URL like "data:image/jpeg;base64,...") to set it
      await docRef.update({
        'picture': url, // Store the base64 data URL string in the picture field
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
