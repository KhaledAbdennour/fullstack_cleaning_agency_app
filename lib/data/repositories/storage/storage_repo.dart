import 'storage_repo_db.dart';

/// Abstract storage repository interface
/// Follows teacher's pattern: Abstract interface + Implementation
abstract class AbstractStorageRepo {
  /// Upload profile picture and return download URL
  Future<String> uploadProfileImage(int userId, String filePath);

  /// Delete profile picture from storage
  Future<void> deleteProfileImage(String imageUrl);

  static AbstractStorageRepo? _instance;
  static AbstractStorageRepo getInstance() {
    _instance ??= StorageRepoDB();
    return _instance!;
  }
}
