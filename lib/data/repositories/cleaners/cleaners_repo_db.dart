import 'package:sqflite/sqflite.dart';
import '../../databases/dbhelper.dart';
import '../../models/cleaner_model.dart';
import 'cleaners_repo.dart';

class CleanersDB extends AbstractCleanersRepo {
  static const String tableName = 'cleaners';

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
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'agency_id = ? AND is_active = 1',
        whereArgs: [agencyId],
        orderBy: 'jobs_completed DESC',
      );
      return maps.map((map) => Cleaner.fromMap(map)).toList();
    } catch (e, stacktrace) {
      print('getCleanersForAgency error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Cleaner?> getCleanerById(int cleanerId) async {
    try {
      final db = await DBHelper.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [cleanerId],
      );
      if (maps.isEmpty) return null;
      return Cleaner.fromMap(maps.first);
    } catch (e, stacktrace) {
      print('getCleanerById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Cleaner> addCleaner(Cleaner cleaner) async {
    try {
      final db = await DBHelper.getDatabase();
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toMap();
      cleanerMap.remove('id');
      final id = await db.insert(tableName, cleanerMap);
      return cleaner.copyWith(id: id, createdAt: now, updatedAt: now);
    } catch (e, stacktrace) {
      print('addCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<Cleaner> updateCleaner(Cleaner cleaner) async {
    try {
      final db = await DBHelper.getDatabase();
      final now = DateTime.now();
      final cleanerMap = cleaner.copyWith(updatedAt: now).toMap();
      cleanerMap.remove('id');
      await db.update(
        tableName,
        cleanerMap,
        where: 'id = ?',
        whereArgs: [cleaner.id],
      );
      return cleaner.copyWith(updatedAt: now);
    } catch (e, stacktrace) {
      print('updateCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }

  @override
  Future<void> removeCleaner(int cleanerId) async {
    try {
      final db = await DBHelper.getDatabase();
      await db.update(
        tableName,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [cleanerId],
      );
    } catch (e, stacktrace) {
      print('removeCleaner error: $e --> $stacktrace');
      rethrow;
    }
  }
}

