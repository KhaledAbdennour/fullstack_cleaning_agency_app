# Firebase Migration Status

## ✅ Completed
1. Removed `supabase_flutter` dependency
2. Added `cloud_firestore` dependency  
3. Created `lib/core/config/firebase_config.dart`
4. Updated `lib/main.dart` - removed Supabase init, added Firestore init
5. Updated `lib/core/services/notification_service.dart` - uses Firestore
6. Updated `lib/core/services/notification_repo_db.dart` - uses Firestore + FCM HTTP API
7. Updated `lib/core/env/env_helper.dart` - removed Supabase references
8. Migrated `lib/data/repositories/profiles/profile_repo_db.dart` to Firestore
9. Deleted `lib/core/config/supabase_config.dart`

## ✅ All Repositories Migrated
1. ✅ `lib/data/repositories/jobs/jobs_repo_db.dart` - **COMPLETE**
2. ✅ `lib/data/repositories/bookings/bookings_repo_db.dart` - **COMPLETE**
3. ✅ `lib/data/repositories/cleaners/cleaners_repo_db.dart` - **COMPLETE**
4. ✅ `lib/data/repositories/cleaner_reviews/cleaner_reviews_repo_db.dart` - **COMPLETE**
5. ✅ `lib/data/repositories/cleaning_history/cleaning_history_repo_db.dart` - **COMPLETE**

## Migration Pattern
- Replace `SupabaseConfig.client.from(tableName)` with `FirebaseConfig.firestore.collection(collectionName)`
- Replace `.select()` with `.get()`
- Replace `.eq('field', value)` with `.where('field', isEqualTo: value)`
- Replace `.order('field', ascending: false)` with `.orderBy('field', descending: true)`
- Replace `.isFilter('field', null)` with `.where('field', isNull: true)`
- Replace `.inFilter('field', [values])` with `.where('field', whereIn: [values])`
- Replace `.insert(data)` with `.add(data)` or `.doc(id.toString()).set(data)`
- Replace `.update(data)` with `.doc(id.toString()).update(data)`
- Replace `.delete()` with `.doc(id.toString()).delete()`
- Convert int IDs to strings: `id.toString()` for doc IDs
- Add `data['id'] = int.tryParse(doc.id) ?? 0` when reading documents

## FCM Server Key
The FCM server key is stored in `lib/core/services/notification_repo_db.dart`:
- Key: `6B6_LDeZoDxT14kvBMKuHuGkYhGDmNMbhFPUFmScS0`
- Sender ID: `636141062102` (from Firebase Console)

## Files to Delete (Supabase)
- `supabase/functions/send_push/index.ts` (no longer needed - using direct FCM HTTP API)
- `supabase/migrations/001_initial_schema.sql` (no longer needed - using Firestore)

