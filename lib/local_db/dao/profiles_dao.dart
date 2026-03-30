import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

class ProfilesDao {
  static const String _tableName = 'profiles_cache';

  static Future<void> insertProfiles(
      List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) return;

    final db = await AppDatabase.database;
    final batch = db.batch();

    for (final profile in profiles) {
      final id = profile['id'];
      if (id == null) continue;

      final name = profile['agency_name'] ?? profile['full_name'] ?? 'Unknown';
      final rating = (profile['rating'] as num?)?.toDouble() ?? 0.0;
      final userType = profile['user_type'] as String?;

      batch.insert(
        _tableName,
        {
          'id': id,
          'name': name,
          'rating': rating,
          'user_type': userType,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedProfiles(
      {String? userType}) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      _tableName,
      where: userType != null ? 'user_type = ?' : null,
      whereArgs: userType != null ? [userType] : null,
      orderBy: 'rating DESC, cached_at DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'] as int,
        'name': map['name'] as String,
        'rating': map['rating'] as double,
        'user_type': map['user_type'] as String?,
      };
    }).toList();
  }

  static Future<void> clearAll() async {
    final db = await AppDatabase.database;
    await db.delete(_tableName);
  }
}
