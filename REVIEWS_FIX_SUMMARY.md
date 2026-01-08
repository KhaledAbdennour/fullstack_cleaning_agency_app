# Reviews System Fix - Summary

## Problem
Reviews were being created but not appearing on worker profiles because:
1. New reviews were written to "reviews" collection, but profile pages read from "cleaner_reviews" collection
2. Profile aggregate updates might have been failing silently
3. Missing debug logs made it hard to diagnose issues

## Files Changed

### 1. `lib/data/repositories/reviews/reviews_repo_db.dart`
- **Added**: Writes to BOTH "reviews" (new) AND "cleaner_reviews" (old) collections for backward compatibility
- **Fixed**: `revieweeId` format validation to ensure it's a valid int
- **Fixed**: Profile aggregate update to read from BOTH collections and deduplicate
- **Added**: Comprehensive debug logs at every step

### 2. `lib/data/repositories/jobs/jobs_repo_db.dart`
- **Added**: Debug logs for `getRecentClientJobs()` showing:
  - Query filters used
  - Result count
  - First 3 jobs with their status, assignedWorkerId, isDeleted, and types

### 3. `lib/logic/cubits/listings_cubit.dart`
- **Added**: Debug logs for sorting showing:
  - Top 5 agencies with ratings and created_at_ms
  - Top 5 cleaners with ratings and created_at_ms

## Key Fixes

### Review Creation Flow
1. **Writes to both collections**: 
   - New "reviews" collection (for future use)
   - Old "cleaner_reviews" collection (for backward compatibility with existing profile pages)

2. **Profile aggregate update**:
   - Reads from BOTH collections
   - Deduplicates by `job_id + reviewer_id`
   - Calculates new `rating_avg` (double) and `rating_count` (int)
   - Updates profile document using transaction
   - Logs old → new values with types

3. **Debug logging**:
   - `addReview_START`: jobId, revieweeId, rating
   - `addReview_BEFORE_WRITE`: review data before write
   - `addReview_REVIEW_SAVED`: new collection write success
   - `addReview_OLD_COLLECTION_SAVED`: old collection write success
   - `addReview_AGGREGATES_BEFORE`: old rating/count values
   - `addReview_AGGREGATES_CALCULATED`: calculated new values
   - `addReview_AGGREGATES_UPDATED`: transaction success with old → new values
   - `addReview_SUCCESS`: final review document ID

### Homepage Listings
- **getRecentClientJobs()**: Only returns jobs where:
  - `status == 'open'`
  - `assigned_worker_id == null`
  - `is_deleted == false`
- **Sorting**: Agencies and cleaners sorted by:
  - Rating descending (highest first)
  - Recency descending as tie-breaker (most recent first)

## Firestore Indexes

Already added to `firestore.indexes.json`:
```json
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "reviewee_id", "order": "ASCENDING"},
    {"fieldPath": "created_at", "order": "DESCENDING"}
  ]
},
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "job_id", "order": "ASCENDING"}
  ]
},
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "reviewer_id", "order": "ASCENDING"},
    {"fieldPath": "created_at", "order": "DESCENDING"}
  ]
}
```

## Firestore Rules

**Note**: If you have custom Firestore rules, ensure they allow:
- Creating documents in "reviews" collection for authenticated users
- Creating documents in "cleaner_reviews" collection for authenticated users
- Updating "profiles" collection for aggregate fields

Example minimal rules:
```javascript
match /reviews/{reviewId} {
  allow create: if request.auth != null;
  allow read: if request.auth != null;
}

match /cleaner_reviews/{reviewId} {
  allow create: if request.auth != null;
  allow read: if request.auth != null;
}

match /profiles/{profileId} {
  allow update: if request.auth != null 
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['rating', 'rating_avg', 'rating_count', 'updated_at']);
}
```

## Test Checklist

### 1. Review Creation Test
- [ ] Complete a job (both parties confirm completion)
- [ ] Open review page → submit review with rating and comment
- [ ] Check logs for:
  - `addReview_START` with jobId, revieweeId, rating
  - `addReview_REVIEW_SAVED` with reviewDocId
  - `addReview_OLD_COLLECTION_SAVED` with cleanerId
  - `addReview_AGGREGATES_BEFORE` with old rating/count
  - `addReview_AGGREGATES_UPDATED` with old → new values
  - `addReview_SUCCESS` with reviewId

### 2. Profile Display Test
- [ ] Navigate to worker/cleaner profile page
- [ ] Check "Reviews" tab shows the new review
- [ ] Verify rating displayed matches the submitted rating
- [ ] Verify review count increased by 1
- [ ] Verify average rating updated correctly

### 3. Homepage Listings Test
- [ ] Open homepage
- [ ] Check logs for:
  - `getRecentClientJobs_START` with filters
  - `getRecentClientJobs_RESULT` with count and first 3 jobs
  - Verify all jobs have `status: 'open'`, `assignedWorkerId: null`, `isDeleted: false`
- [ ] Check "Top Individuals" section:
  - Logs show `loadListings_TOP_CLEANERS` with top 5 ratings
  - Verify highest-rated cleaners appear first
- [ ] Check "Top Agencies" section:
  - Logs show `loadListings_TOP_AGENCIES` with top 5 ratings
  - Verify highest-rated agencies appear first

### 4. Firestore Verification
- [ ] Check "reviews" collection has new document with:
  - `job_id` (int)
  - `reviewee_id` (string, matches profile doc ID)
  - `rating` (int 1-5)
  - `created_at` (Timestamp)
  - `created_at_ms` (int)
- [ ] Check "cleaner_reviews" collection has corresponding document with:
  - `cleaner_id` (int)
  - `rating` (double)
  - `job_id` (int)
- [ ] Check "profiles" collection for reviewee:
  - `rating` (double) updated
  - `rating_avg` (double) updated
  - `rating_count` (int) increased by 1

## Expected Log Lines

### Review Submission
```
[ReviewsDB] addReview_START | {"jobId":123,"revieweeId":"456","rating":5}
[ReviewsDB] addReview_BEFORE_WRITE | {"reviewDocId":"job_123_reviewer_789",...}
[ReviewsDB] addReview_REVIEW_SAVED | {"reviewDocId":"job_123_reviewer_789","jobId":123}
[ReviewsDB] addReview_OLD_COLLECTION_SAVED | {"oldReviewDocId":"job_123_reviewer_789","cleanerId":456}
[ReviewsDB] addReview_AGGREGATES_BEFORE | {"oldRatingAvg":4.2,"oldRatingCount":5}
[ReviewsDB] addReview_AGGREGATES_CALCULATED | {"newRatingAvg":4.33,"newRatingCount":6}
[ReviewsDB] addReview_AGGREGATES_UPDATED | {"oldRatingAvg":4.2,"newRatingAvg":4.33,"oldRatingCount":5,"newRatingCount":6}
[ReviewsDB] addReview_SUCCESS | {"reviewId":"job_123_reviewer_789","jobId":123}
```

### Homepage Listings
```
[JobsDB] getRecentClientJobs_START | {"limit":50,"filters":"status == open..."}
[JobsDB] getRecentClientJobs_RESULT | {"totalCount":10,"firstThreeJobs":[...]}
[ListingsCubit] loadListings_TOP_AGENCIES | {"totalAgencies":15,"topFive":[...]}
[ListingsCubit] loadListings_TOP_CLEANERS | {"totalCleaners":20,"topFive":[...]}
```

## Deployment Steps

1. **Deploy Firestore indexes** (if not already deployed):
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. **Update Firestore rules** (if needed):
   - Add rules for "reviews" collection
   - Ensure "profiles" can be updated for aggregate fields

3. **Test end-to-end**:
   - Create a test job
   - Complete it (both parties)
   - Submit review
   - Verify it appears on profile
   - Check logs for all expected entries

## Troubleshooting

### Review not appearing on profile
1. Check logs for `addReview_OLD_COLLECTION_SAVED` - if missing, old collection write failed
2. Check logs for `addReview_AGGREGATES_UPDATED` - if missing, aggregate update failed
3. Verify `revieweeId` matches profile document ID format (int as string)
4. Check Firestore console for documents in both collections

### Aggregate update failing
1. Check logs for `addReview_AGGREGATE_UPDATE_FAILED` with error details
2. Verify profile document exists with correct ID
3. Check Firestore rules allow profile updates
4. Verify transaction isn't hitting retry limits

### Homepage showing wrong jobs
1. Check logs for `getRecentClientJobs_RESULT` - verify job statuses
2. Ensure jobs have `status: 'open'` in Firestore (not 'assigned', 'completed', etc.)
3. Verify `assigned_worker_id` is `null` (not missing field)
