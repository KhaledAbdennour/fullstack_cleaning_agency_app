import 'package:sqflite/sqflite.dart';
import '../../databases/dbhelper.dart';
import '../../models/cleaning_history_item.dart';
import 'cleaning_history_repo.dart';

class CleaningHistoryDB extends AbstractCleaningHistoryRepo {
  static const String tableName = 'cleaning_history';

  static const String sqlCode = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cleaner_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      job_id INTEGER,
      FOREIGN KEY (cleaner_id) REFERENCES profiles(id),
      FOREIGN KEY (job_id) REFERENCES jobs(id)
    )
  ''';

  @override
  Future<List<CleaningHistoryItem>> getCleaningHistoryForCleaner(int cleanerId, {int page = 1, int limit = 10}) async {
    try {
      final db = await DBHelper.getDatabase();
      final offset = (page - 1) * limit;
      final maps = await db.query(
        tableName,
        where: 'cleaner_id = ?',
        whereArgs: [cleanerId],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => CleaningHistoryItem.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getCleaningHistoryForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleaningHistoryItem> addHistoryItem(CleaningHistoryItem item) async {
    try {
      final db = await DBHelper.getDatabase();
      final itemMap = item.toMap();
      itemMap.remove('id');
      final id = await db.insert(tableName, itemMap);
      return item.copyWith(id: id);
    } catch (e, stacktrace) {
      print('addHistoryItem error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteHistoryItem(int itemId) async {
    try {
      final db = await DBHelper.getDatabase();
      await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [itemId],
      );
    } catch (e, stacktrace) {
      print('deleteHistoryItem error: $e --> $stacktrace');
      rethrow;
    }
  }
}

extension CleaningHistoryItemCopyWith on CleaningHistoryItem {
  CleaningHistoryItem copyWith({
    int? id,
    int? cleanerId,
    String? title,
    DateTime? date,
    String? description,
    CleaningHistoryType? type,
    int? jobId,
  }) {
    return CleaningHistoryItem(
      id: id ?? this.id,
      cleanerId: cleanerId ?? this.cleanerId,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      jobId: jobId ?? this.jobId,
    );
  }
}




