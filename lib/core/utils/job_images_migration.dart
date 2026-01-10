import '../config/firebase_config.dart';

/// Migration utility to add job_images field to all existing jobs in Firestore
class JobImagesMigration {
  /// Add job_images field to all jobs that don't have it
  /// Returns the number of jobs updated
  static Future<int> migrateAllJobs() async {
    try {
      print('Starting job_images migration...');

      final jobsSnapshot = await FirebaseConfig.firestore
          .collection('jobs')
          .get();

      if (jobsSnapshot.docs.isEmpty) {
        print('No jobs found in Firestore');
        return 0;
      }

      print('Found ${jobsSnapshot.docs.length} jobs to check');

      var batch = FirebaseConfig.firestore.batch();
      int batchCount = 0;
      int updatedCount = 0;

      for (final doc in jobsSnapshot.docs) {
        final data = doc.data();

        // Check if job_images field is missing or null
        if (!data.containsKey('job_images') || data['job_images'] == null) {
          // Add job_images field with empty array
          batch.update(doc.reference, {'job_images': <String>[]});
          batchCount++;
          updatedCount++;

          // Commit batch when it reaches 500 (Firestore limit)
          if (batchCount >= 500) {
            await batch.commit();
            print('Committed batch: $updatedCount jobs updated so far...');
            batch = FirebaseConfig.firestore.batch();
            batchCount = 0;
          }
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        print('Committed final batch');
      }

      print('Migration complete! Updated $updatedCount jobs');
      return updatedCount;
    } catch (e, stackTrace) {
      print('Migration error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Force update ALL jobs to have job_images field (even if they already have it)
  /// This ensures the field is present in all documents
  static Future<int> forceMigrateAllJobs() async {
    try {
      print('Starting FORCE job_images migration (updating all jobs)...');

      final jobsSnapshot = await FirebaseConfig.firestore
          .collection('jobs')
          .get();

      if (jobsSnapshot.docs.isEmpty) {
        print('No jobs found in Firestore');
        return 0;
      }

      print('Found ${jobsSnapshot.docs.length} jobs to update');

      var batch = FirebaseConfig.firestore.batch();
      int batchCount = 0;
      int updatedCount = 0;

      for (final doc in jobsSnapshot.docs) {
        final data = doc.data();

        // Always update job_images field
        // If it exists and has data, keep it; otherwise set to empty array
        final currentImages = data['job_images'];
        final jobImages = (currentImages is List && currentImages.isNotEmpty)
            ? currentImages
            : <String>[];

        batch.update(doc.reference, {'job_images': jobImages});
        batchCount++;
        updatedCount++;

        // Commit batch when it reaches 500 (Firestore limit)
        if (batchCount >= 500) {
          await batch.commit();
          print('Committed batch: $updatedCount jobs updated so far...');
          batch = FirebaseConfig.firestore.batch();
          batchCount = 0;
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        print('Committed final batch');
      }

      print('Force migration complete! Updated $updatedCount jobs');
      return updatedCount;
    } catch (e, stackTrace) {
      print('Migration error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
