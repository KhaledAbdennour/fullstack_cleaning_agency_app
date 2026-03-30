import 'storage_repo_db.dart';

abstract class AbstractStorageRepo {
  Future<String> uploadProfileImage(int userId, String filePath);

  Future<void> deleteProfileImage(String imageUrl);

  static AbstractStorageRepo? _instance;
  static AbstractStorageRepo getInstance() {
    _instance ??= StorageRepoDB();
    return _instance!;
  }
}
