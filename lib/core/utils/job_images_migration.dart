import '../config/firebase_config.dart';

class JobImagesMigration {
  static Future<int> migrateAllJobs() async {
    try {
      print('Starting job_images migration...');

      final jobsSnapshot =
          await FirebaseConfig.firestore.collection('jobs').get();

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

        if (!data.containsKey('job_images') || data['job_images'] == null) {
          batch.update(doc.reference, {'job_images': <String>[]});
          batchCount++;
          updatedCount++;

          if (batchCount >= 500) {
            await batch.commit();
            print('Committed batch: $updatedCount jobs updated so far...');
            batch = FirebaseConfig.firestore.batch();
            batchCount = 0;
          }
        }
      }

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

  static Future<int> forceMigrateAllJobs() async {
    try {
      print('Starting FORCE job_images migration (updating all jobs)...');

      final jobsSnapshot =
          await FirebaseConfig.firestore.collection('jobs').get();

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

        final currentImages = data['job_images'];
        final jobImages = (currentImages is List && currentImages.isNotEmpty)
            ? currentImages
            : <String>[];

        batch.update(doc.reference, {'job_images': jobImages});
        batchCount++;
        updatedCount++;

        if (batchCount >= 500) {
          await batch.commit();
          print('Committed batch: $updatedCount jobs updated so far...');
          batch = FirebaseConfig.firestore.batch();
          batchCount = 0;
        }
      }

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
