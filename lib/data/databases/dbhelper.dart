import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../repositories/profiles/profile_repo_db.dart';
import '../repositories/jobs/jobs_repo_db.dart';
import '../repositories/bookings/bookings_repo_db.dart';
import '../repositories/cleaners/cleaners_repo_db.dart';
import '../repositories/cleaning_history/cleaning_history_repo_db.dart';
import '../repositories/cleaner_reviews/cleaner_reviews_repo_db.dart';

class DBHelper {
  static const _databaseName = 'CLEANSPACE_DB.db';
  static const _databaseVersion = 5; 

  static Database? _database;
  static bool _initialized = false;

  static Future<void> _initializeDatabaseFactory() async {
    if (!_initialized) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
    }
  }

  static Future<String> _getDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      
      final directory = await getApplicationDocumentsDirectory();
      return join(directory.path, _databaseName);
    } else {
      
      return join(await getDatabasesPath(), _databaseName);
    }
  }

  
  static Future<void> initialize() async {
    await _initializeDatabaseFactory();
  }

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    await _initializeDatabaseFactory();
    final dbPath = await _getDatabasePath();

    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        
        await db.execute(ProfileDB.sqlCode);
        
        // ProfileDB.currentUserSqlCode removed - using Supabase now
        
        await db.execute(JobsDB.sqlCode);
        
        await db.execute(BookingsDB.sqlCode);
        
        await db.execute(CleanersDB.sqlCode);
        
        await db.execute(CleaningHistoryDB.sqlCode);
        
        await db.execute(CleanerReviewsDB.sqlCode);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        
        if (oldVersion < newVersion) {
          if (oldVersion < 2) {
            
            await db.execute(JobsDB.sqlCode);
            await db.execute(BookingsDB.sqlCode);
            await db.execute(CleanersDB.sqlCode);
          }
          if (oldVersion < 3) {
            
            try {
              
              final tableInfo = await db.rawQuery('PRAGMA table_info(${JobsDB.tableName})');
              final columnNames = tableInfo.map((row) => row['name'] as String).toList();
              
              if (!columnNames.contains('client_id')) {
                await db.execute('ALTER TABLE ${JobsDB.tableName} ADD COLUMN client_id INTEGER');
              }
              if (!columnNames.contains('budget_min')) {
                await db.execute('ALTER TABLE ${JobsDB.tableName} ADD COLUMN budget_min REAL');
              }
              if (!columnNames.contains('budget_max')) {
                await db.execute('ALTER TABLE ${JobsDB.tableName} ADD COLUMN budget_max REAL');
              }
              if (!columnNames.contains('estimated_hours')) {
                await db.execute('ALTER TABLE ${JobsDB.tableName} ADD COLUMN estimated_hours INTEGER');
              }
              if (!columnNames.contains('required_services')) {
                await db.execute('ALTER TABLE ${JobsDB.tableName} ADD COLUMN required_services TEXT');
              }
              
              
              
              
              
            } catch (e) {
              print('Migration error (might already be migrated): $e');
            }
            
            try {
              await db.execute('ALTER TABLE ${BookingsDB.tableName} ADD COLUMN provider_id INTEGER');
              await db.execute('ALTER TABLE ${BookingsDB.tableName} ADD COLUMN bid_price REAL');
              await db.execute('ALTER TABLE ${BookingsDB.tableName} ADD COLUMN message TEXT');
            } catch (e) {
              print('Migration error (might already be migrated): $e');
            }
          }
          if (oldVersion < 4) {
            
            try {
              await db.execute(CleaningHistoryDB.sqlCode);
              await db.execute(CleanerReviewsDB.sqlCode);
            } catch (e) {
              print('Migration error (might already be migrated): $e');
            }
          }
          if (oldVersion < 5) {
            
            try {
              
              final tableInfo = await db.rawQuery('PRAGMA table_info(${JobsDB.tableName})');
              final hasAgencyId = tableInfo.any((row) => row['name'] == 'agency_id');
              
              if (hasAgencyId) {
                
                
                await db.execute('PRAGMA foreign_keys=OFF');
                
                
                await db.execute('ALTER TABLE ${JobsDB.tableName} RENAME TO ${JobsDB.tableName}_old');
                
                
                await db.execute(JobsDB.sqlCode);
                
                
                await db.execute('''
                  INSERT INTO ${JobsDB.tableName} 
                  (id, title, city, country, description, status, posted_date, job_date, 
                   cover_image_url, client_id, agency_id, budget_min, budget_max, 
                   estimated_hours, required_services, is_deleted, created_at, updated_at)
                  SELECT id, title, city, country, description, status, posted_date, job_date,
                         cover_image_url, 
                         CASE WHEN client_id IS NOT NULL THEN client_id ELSE NULL END,
                         CASE WHEN agency_id IS NOT NULL THEN agency_id ELSE NULL END,
                         budget_min, budget_max,
                         estimated_hours, required_services, is_deleted, created_at, updated_at
                  FROM ${JobsDB.tableName}_old
                ''');
                
                
                await db.execute('DROP TABLE ${JobsDB.tableName}_old');
                
                
                await db.execute('PRAGMA foreign_keys=ON');
              }
            } catch (e) {
              print('Migration error (might already be migrated): $e');
              
              try {
                await db.execute('PRAGMA foreign_keys=OFF');
                await db.execute('ALTER TABLE ${JobsDB.tableName}_old RENAME TO ${JobsDB.tableName}');
                await db.execute('PRAGMA foreign_keys=ON');
              } catch (e2) {
                print('Failed to restore old table: $e2');
              }
            }
          }
        }
      },
    );

    return _database!;
  }
}

