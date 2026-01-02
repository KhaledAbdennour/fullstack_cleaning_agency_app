import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/cleaner_model.dart';
import 'cleaners_repo.dart';

class CleanersDB extends AbstractCleanersRepo {
  static const String tableName = 'cleaners';

  // Keep SQL code for reference
  static const String sqlCode = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      avatar_url TEXT,
      rating REAL NOT NULL DEFAULT 0.0,
      jobs_completed INTEGER NOT NULL DEFAULT 0,
      agency_id INTEGER NOT NULL,
      is_active INTEGER DEFAULT 1,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (agency_id) REFERENCES profiles(id)
    )
  ''';

  @override
  Future<List<Cleaner>> getCleanersForAgency(int agencyId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('agency_id', agencyId)
          .eq('is_active', true)
          .order('jobs_completed', ascending: false);
      
      return (response as List)
          .map((map) => Cleaner.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e, stacktrace) {
      print('getCleanersForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Cleaner?> getCleanerById(int cleanerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('id', cleanerId)
          .maybeSingle();
      
      if (response == null) return null;
      return Cleaner.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('getCleanerById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Cleaner> addCleaner(Cleaner cleaner) async {
    try {
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toMap();
      cleanerMap.remove('id');
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(cleanerMap)
          .select()
          .single();
      
      return Cleaner.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stacktrace) {
      print('addCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Cleaner> updateCleaner(Cleaner cleaner) async {
    try {
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(updatedAt: now).toMap();
      cleanerMap.remove('id');
      
      await SupabaseConfig.client
          .from(tableName)
          .update(cleanerMap)
          .eq('id', cleaner.id!);
      
      return cleaner.copyWith(updatedAt: now);
    } catch (e, stacktrace) {
      print('updateCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> removeCleaner(int cleanerId) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cleanerId);
    } catch (e, stacktrace) {
      print('removeCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }
}
