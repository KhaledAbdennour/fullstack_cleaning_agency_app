import '../../models/cleaner_model.dart';
import 'cleaners_repo_db.dart';

abstract class AbstractCleanersRepo {
  Future<List<Cleaner>> getCleanersForAgency(int agencyId);
  Future<Cleaner?> getCleanerById(int cleanerId);
  Future<Cleaner> addCleaner(Cleaner cleaner);
  Future<Cleaner> updateCleaner(Cleaner cleaner);
  Future<void> removeCleaner(int cleanerId);

  static AbstractCleanersRepo? _instance;
  static AbstractCleanersRepo getInstance() {
    _instance ??= CleanersDB();
    return _instance!;
  }
}
