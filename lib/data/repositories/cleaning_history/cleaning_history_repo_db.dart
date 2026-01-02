import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/cleaning_history_item.dart';
import 'cleaning_history_repo.dart';

class CleaningHistoryDB extends AbstractCleaningHistoryRepo {
  static const String tableName = 'cleaning_history';

  // Keep SQL code for reference
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
      final offset = (page - 1) * limit;
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('cleaner_id', cleanerId)
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((map) => CleaningHistoryItem.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getCleaningHistoryForCleaner error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<CleaningHistoryItem> addHistoryItem(CleaningHistoryItem item) async {
    try {
      final itemMap = item.toMap();
      itemMap.remove('id');
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(itemMap)
          .select()
          .single();
      
      return CleaningHistoryItem.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('addHistoryItem error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteHistoryItem(int itemId) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .delete()
          .eq('id', itemId);
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
