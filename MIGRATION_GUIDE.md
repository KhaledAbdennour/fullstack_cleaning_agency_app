# Repository Migration Guide: SQLite to Supabase

This guide shows the pattern for migrating remaining repositories from SQLite to Supabase.

## Migration Pattern

### 1. Replace Imports
```dart
// OLD (SQLite)
import 'package:sqflite/sqflite.dart';
import '../../databases/dbhelper.dart';

// NEW (Supabase)
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
```

### 2. Replace Database Calls

#### SELECT Queries
```dart
// OLD
final db = await DBHelper.getDatabase();
final maps = await db.query(
  tableName,
  where: 'id = ?',
  whereArgs: [id],
);

// NEW
final response = await SupabaseConfig.client
    .from(tableName)
    .select()
    .eq('id', id);
final maps = List<Map<String, dynamic>>.from(response);
```

#### INSERT
```dart
// OLD
final id = await db.insert(tableName, dataMap);

// NEW
final response = await SupabaseConfig.client
    .from(tableName)
    .insert(dataMap)
    .select()
    .single();
final id = response['id'];
```

#### UPDATE
```dart
// OLD
await db.update(
  tableName,
  dataMap,
  where: 'id = ?',
  whereArgs: [id],
);

// NEW
await SupabaseConfig.client
    .from(tableName)
    .update(dataMap)
    .eq('id', id);
```

#### DELETE
```dart
// OLD
await db.delete(
  tableName,
  where: 'id = ?',
  whereArgs: [id],
);

// NEW
await SupabaseConfig.client
    .from(tableName)
    .delete()
    .eq('id', id);
```

### 3. Common Query Patterns

#### Multiple Conditions
```dart
// OLD
where: 'agency_id = ? AND is_deleted = 0',
whereArgs: [agencyId],

// NEW
.eq('agency_id', agencyId)
.eq('is_deleted', false)
```

#### NULL Checks
```dart
// OLD
where: 'client_id IS NULL',

// NEW
.isFilter('client_id', null)  // IS NULL

// For IS NOT NULL, filter client-side after fetching:
final response = await SupabaseConfig.client
    .from(tableName)
    .select()
    .eq('other_field', value);
final filtered = (response as List).where((map) => map['client_id'] != null).toList();
```

#### IN Clause
```dart
// OLD
where: 'status IN (?, ?)',
whereArgs: ['active', 'pending'],

// NEW
.inFilter('status', ['active', 'pending'])
```

#### ORDER BY
```dart
// OLD
orderBy: 'created_at DESC',

// NEW
.order('created_at', ascending: false)
```

#### LIMIT
```dart
// OLD
limit: 10,

// NEW
.limit(10)
```

#### COUNT
```dart
// OLD
final result = await db.rawQuery('SELECT COUNT(*) as count FROM ...');
return Sqflite.firstIntValue(result) ?? 0;

// NEW
final response = await SupabaseConfig.client
    .from(tableName)
    .select('id', const FetchOptions(count: CountOption.exact))
    .eq('status', 'completed');
return response.count ?? 0;
```

### 4. Error Handling
Keep the same try-catch pattern, but Supabase errors are different:
```dart
try {
  final response = await SupabaseConfig.client.from(tableName).select();
  return processResponse(response);
} catch (e, stacktrace) {
  print('Operation error: $e --> $stacktrace');
  return defaultValue; // or rethrow
}
```

### 5. Date Handling
Supabase uses TIMESTAMPTZ, but models expect ISO8601 strings:
- When reading: Supabase returns ISO8601 strings automatically
- When writing: Use `DateTime.now().toIso8601String()`

### 6. Boolean Handling
```dart
// SQLite uses INTEGER (0/1)
is_deleted: 0 or 1

// Supabase uses BOOLEAN
is_deleted: false or true

// In toMap(), convert:
'is_deleted': isDeleted ? 1 : 0  // Keep for SQLite compatibility
// Supabase will handle boolean conversion automatically
```

## Remaining Repositories to Migrate

1. **bookings_repo_db.dart** - Follow bookings pattern
2. **cleaners_repo_db.dart** - Simple CRUD operations
3. **cleaner_reviews_repo_db.dart** - Reviews with ratings
4. **cleaning_history_repo_db.dart** - History with pagination

## Example: Bookings Repository

```dart
@override
Future<List<Booking>> getBookingsForClient(int clientId) async {
  try {
    final response = await SupabaseConfig.client
        .from('bookings')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((map) => Booking.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  } catch (e, stacktrace) {
    print('getBookingsForClient error: $e --> $stacktrace');
    return [];
  }
}

@override
Future<Booking> createBooking(Booking booking) async {
  try {
    final bookingMap = booking.toMap();
    bookingMap.remove('id');
    
    final response = await SupabaseConfig.client
        .from('bookings')
        .insert(bookingMap)
        .select()
        .single();
    
    return Booking.fromMap(Map<String, dynamic>.from(response));
  } catch (e, stacktrace) {
    print('createBooking error: $e --> $stacktrace');
    rethrow;
  }
}
```

## Testing After Migration

1. Test each CRUD operation
2. Verify data types (especially dates and booleans)
3. Check NULL handling
4. Test error cases (network failures, invalid data)
5. Verify foreign key relationships work correctly

