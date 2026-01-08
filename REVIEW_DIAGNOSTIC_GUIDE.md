# Review Not Appearing - Diagnostic Guide

## Quick Checks

### 1. Check Debug Logs
Open `.cursor/debug.log` and look for these log entries after submitting a review:

**Review Creation:**
- `[ReviewsDB] addReview_OLD_COLLECTION_SAVED` - Confirms review was written to `cleaner_reviews`
- Check the `cleanerId` value in this log

**Review Loading:**
- `[CleanerReviewsDB] getReviewsForCleaner_START` - Shows the cleanerId being queried
- `[CleanerReviewsDB] getReviewsForCleaner_RESULT` - Shows reviews found
- `[CleanerReviewsDB] getReviewsForCleaner_EMPTY` - Shows if no reviews found

### 2. Verify Cleaner ID Match
The issue might be a **cleaner ID mismatch**:

1. When you submit the review, check the log:
   ```
   [ReviewsDB] addReview_OLD_COLLECTION_SAVED | {"cleanerId": 123, ...}
   ```

2. When the profile page loads, check:
   ```
   [CleanerReviewsDB] getReviewsForCleaner_START | {"cleanerId": 456, ...}
   ```

3. **If the IDs don't match**, that's the problem!

### 3. Check Firestore Console
1. Open Firebase Console → Firestore Database
2. Check `cleaner_reviews` collection
3. Look for a document with ID like `job_XXX_reviewer_YYY`
4. Verify:
   - `cleaner_id` field matches the worker's profile ID (int)
   - `date` field exists (ISO string)
   - `rating` field exists (double)

### 4. Check Profile Page Cleaner ID
The profile page gets the cleaner ID from `widget.cleaner['id']`. Verify:
- The cleaner ID in the profile data matches the `cleaner_id` in the review document
- The ID is an **int**, not a string

## Common Issues & Fixes

### Issue 1: Query Failing Silently (Index Missing)
**Symptom:** Logs show `getReviewsForCleaner_INDEX_ERROR` then `getReviewsForCleaner_FALLBACK_SUCCESS`

**Fix:** Deploy the index:
```bash
firebase deploy --only firestore:indexes
```

The index is already in `firestore.indexes.json`:
```json
{
  "collectionGroup": "cleaner_reviews",
  "fields": [
    {"fieldPath": "cleaner_id", "order": "ASCENDING"},
    {"fieldPath": "date", "order": "DESCENDING"}
  ]
}
```

### Issue 2: Cleaner ID Mismatch
**Symptom:** Review written with one ID, but profile queries with different ID

**Fix:** Check how `widget.cleaner['id']` is set when navigating to the profile page. Ensure it matches the `revieweeId` passed to `addReview()`.

### Issue 3: Review Not Written to Old Collection
**Symptom:** Logs show `addReview_OLD_COLLECTION_FAILED`

**Fix:** Check the error in logs. Common causes:
- Firestore rules blocking write
- Network error
- Invalid data format

### Issue 4: Profile Page Not Refreshing
**Symptom:** Review exists in Firestore but UI shows "No reviews available"

**Fix:** 
1. Pull down to refresh on the profile page
2. Or navigate away and back to the profile page
3. The `CleanerReviewsCubit` should reload when the Reviews tab is selected

## Step-by-Step Debugging

1. **Submit a new review** and immediately check logs:
   ```
   grep "addReview_OLD_COLLECTION_SAVED" .cursor/debug.log
   ```
   Note the `cleanerId` value.

2. **Open the worker profile page** and check logs:
   ```
   grep "getReviewsForCleaner" .cursor/debug.log
   ```
   Note the `cleanerId` being queried.

3. **Compare the IDs** - they must match exactly (same int value).

4. **Check Firestore Console**:
   - Collection: `cleaner_reviews`
   - Filter: `cleaner_id == [the cleaner ID from step 1]`
   - Verify document exists with correct fields

5. **If document exists but not showing**:
   - Check if query is using fallback (index missing)
   - Verify `date` field format (should be ISO string)
   - Check for any errors in `getReviewsForCleaner_ERROR` logs

## Expected Log Flow

### Successful Review Creation:
```
[ReviewsDB] addReview_START | {"jobId":123,"revieweeId":"456","rating":5}
[ReviewsDB] addReview_REVIEW_SAVED | {"reviewDocId":"job_123_reviewer_789",...}
[ReviewsDB] addReview_OLD_COLLECTION_SAVED | {"cleanerId":456,...}  ← MUST SEE THIS
[ReviewsDB] addReview_AGGREGATES_UPDATED | {"oldRatingAvg":0.0,"newRatingAvg":5.0,...}
```

### Successful Review Loading:
```
[CleanerReviewsDB] getReviewsForCleaner_START | {"cleanerId":456,...}
[CleanerReviewsDB] getReviewsForCleaner_QUERY_SUCCESS | {"resultCount":1,...}
[CleanerReviewsDB] getReviewsForCleaner_RESULT | {"totalCount":1,"firstThree":[...]}
```

## Next Steps

1. **Run the app and submit a review**
2. **Check `.cursor/debug.log`** for the log entries above
3. **Share the relevant log lines** if the review still doesn't appear
4. **Check Firestore Console** to verify the document was created

The debug logs will tell us exactly where the issue is!
