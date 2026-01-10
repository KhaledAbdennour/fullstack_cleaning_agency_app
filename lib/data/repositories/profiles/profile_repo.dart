import 'profile_repo_db.dart';

abstract class AbstractProfileRepo {
  Future<List<Map<String, dynamic>>> getAllProfiles();
  Future<Map<String, dynamic>?> getProfileById(int id);
  Future<Map<String, dynamic>?> getProfileByUsername(String username);
  Future<Map<String, dynamic>?> getProfileByEmail(String email);
  Future<Map<String, dynamic>?> getProfileByPhone(String phone);
  Future<Map<String, dynamic>?> login(String username, String password);
  Future<bool> insertProfile(Map<String, dynamic> profile);
  Future<bool> updateProfile(int id, Map<String, dynamic> profile);
  Future<bool> deleteProfile(int id);
  Future<bool> updateAvatarUrl(int userId, String? url); // Update avatar URL
  Future<bool> removeAvatar(int userId); // Remove avatar (set to null)
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<bool> setCurrentUser(int userId);
  Future<bool> clearCurrentUser();

  static AbstractProfileRepo? _instance;
  static AbstractProfileRepo getInstance() {
    _instance ??= ProfileDB();
    return _instance!;
  }
}
