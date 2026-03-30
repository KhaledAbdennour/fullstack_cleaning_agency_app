import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

class JobsDao {
  static const String _tableName = 'jobs_cache';

  static Future<void> insertJobs(List<Map<String, dynamic>> jobs) async {
    if (jobs.isEmpty) return;

    final db = await AppDatabase.database;
    final batch = db.batch();

    for (final job in jobs) {
      final id = job['id'];
      if (id == null) continue;

      batch.insert(
        _tableName,
        {
          'id': id,
          'title': job['title'] ?? 'Untitled',
          'city': job['city'],
          'status': job['status'],
          'posted_date': job['posted_date'] is DateTime
              ? (job['posted_date'] as DateTime).millisecondsSinceEpoch
              : job['posted_date'],
          'client_id': job['client_id'],
          'agency_id': job['agency_id'],
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedJobs(
      {int limit = 50}) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'posted_date DESC',
      limit: limit,
    );

    return maps.map((map) {
      return {
        'id': map['id'] as int,
        'title': map['title'] as String,
        'city': map['city'] as String?,
        'status': map['status'] as String?,
        'posted_date': DateTime.fromMillisecondsSinceEpoch(
            map['posted_date'] as int? ?? 0),
        'client_id': map['client_id'] as int?,
        'agency_id': map['agency_id'] as int?,
      };
    }).toList();
  }

  static Future<void> clearAll() async {
    final db = await AppDatabase.database;
    await db.delete(_tableName);
  }
}
