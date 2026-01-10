import '../../models/cleaning_history_item.dart';
import 'cleaning_history_repo_db.dart';

abstract class AbstractCleaningHistoryRepo {
  Future<List<CleaningHistoryItem>> getCleaningHistoryForCleaner(
    int cleanerId, {
    int page = 1,
    int limit = 10,
  });
  Future<CleaningHistoryItem> addHistoryItem(CleaningHistoryItem item);
  Future<void> deleteHistoryItem(int itemId);

  static AbstractCleaningHistoryRepo? _instance;
  static AbstractCleaningHistoryRepo getInstance() {
    _instance ??= CleaningHistoryDB();
    return _instance!;
  }
}
