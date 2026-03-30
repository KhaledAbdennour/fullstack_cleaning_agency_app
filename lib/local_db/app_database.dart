import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static const int _schemaVersion = 1;
  static const String _databaseName = 'cleanspace_cache.db';

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications_cache (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        type TEXT,
        sender_id TEXT,
        job_id INTEGER,
        data_json TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_user ON notifications_cache(user_id, created_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE profiles_cache (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        rating REAL DEFAULT 0.0,
        user_type TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE jobs_cache (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        city TEXT,
        status TEXT,
        posted_date INTEGER,
        client_id INTEGER,
        agency_id INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_posted_date ON jobs_cache(posted_date DESC)
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }

  static Future<void> clearCache() async {
    final db = await database;
    await db.delete('notifications_cache');
    await db.delete('profiles_cache');
    await db.delete('jobs_cache');
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
