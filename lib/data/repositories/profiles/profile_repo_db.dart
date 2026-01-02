import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import 'profile_repo.dart';

class ProfileDB extends AbstractProfileRepo {
  static const String tableName = 'profiles';
  static const String _currentUserIdKey = 'current_user_id';

  // Keep SQL code for reference (used by DBHelper for SQLite fallback)
  static const String sqlCode = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      full_name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      birthdate TEXT,
      address TEXT,
      bio TEXT,
      gender TEXT,
      user_type TEXT NOT NULL,
      agency_name TEXT,
      business_id TEXT,
      services TEXT,
      experience_level TEXT,
      hourly_rate TEXT,
      profile_picture_path TEXT,
      id_verification_path TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  @override
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stacktrace) {
      print('getAllProfiles error: $e --> $stacktrace');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileById(int id) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e, stacktrace) {
      print('getProfileById error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('username', username)
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e, stacktrace) {
      print('getProfileByUsername error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('email', email.toLowerCase())
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e, stacktrace) {
      print('getProfileByEmail error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByPhone(String phone) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('phone', phone)
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e, stacktrace) {
      print('getProfileByPhone error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await SupabaseConfig.client
          .from(tableName)
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();
      
      if (response == null) return null;
      final user = Map<String, dynamic>.from(response);
      
      await setCurrentUser(user['id'] as int);
      return user;
    } catch (e, stacktrace) {
      print('login error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<bool> insertProfile(Map<String, dynamic> profile) async {
    try {
      // Ensure created_at is set
      if (!profile.containsKey('created_at') || profile['created_at'] == null) {
        profile['created_at'] = DateTime.now().toIso8601String();
      }
      
      final response = await SupabaseConfig.client
          .from(tableName)
          .insert(profile)
          .select()
          .single();
      
      final username = profile['username'] as String;
      final user = await getProfileByUsername(username);
      if (user != null) {
        await setCurrentUser(user['id'] as int);
      }
      return true;
    } catch (e, stacktrace) {
      print('insertProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> updateProfile(int id, Map<String, dynamic> profile) async {
    try {
      profile['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseConfig.client
          .from(tableName)
          .update(profile)
          .eq('id', id);
      return true;
    } catch (e, stacktrace) {
      print('updateProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> deleteProfile(int id) async {
    try {
      await SupabaseConfig.client
          .from(tableName)
          .delete()
          .eq('id', id);
      return true;
    } catch (e, stacktrace) {
      print('deleteProfile error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_currentUserIdKey);
      if (userId == null) return null;
      return await getProfileById(userId);
    } catch (e, stacktrace) {
      print('getCurrentUser error: $e --> $stacktrace');
      return null;
    }
  }

  @override
  Future<bool> setCurrentUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentUserIdKey, userId);
      return true;
    } catch (e, stacktrace) {
      print('setCurrentUser error: $e --> $stacktrace');
      return false;
    }
  }

  @override
  Future<bool> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserIdKey);
      return true;
    } catch (e, stacktrace) {
      print('clearCurrentUser error: $e --> $stacktrace');
      return false;
    }
  }
}
