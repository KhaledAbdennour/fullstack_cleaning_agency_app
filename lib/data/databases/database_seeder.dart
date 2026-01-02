import '../repositories/profiles/profile_repo.dart';
import '../repositories/jobs/jobs_repo.dart';
import '../repositories/cleaners/cleaners_repo.dart';
import '../repositories/cleaning_history/cleaning_history_repo.dart';
import '../repositories/cleaner_reviews/cleaner_reviews_repo.dart';
import '../models/job_model.dart';
import '../models/cleaner_model.dart';
import '../models/cleaning_history_item.dart';
import '../models/cleaner_review.dart';
import 'dbhelper.dart';



class DatabaseSeeder {
  static bool _seeded = false;

  
  static Future<void> seedDatabase() async {
    if (_seeded) return;

    try {
      
      final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
      if (profiles.isNotEmpty) {
        _seeded = true;
        return; 
      }

      
      await _seedProfiles();
      
      
      await _seedJobs();
      
      
      await _seedCleaners();

      
      await _seedCleaningHistory();
      await _seedCleanerReviews();

      _seeded = true;
      
    } catch (e) {
      
    }
  }

  static Future<void> _seedProfiles() async {
    final repo = AbstractProfileRepo.getInstance();
    
    
    await repo.insertProfile({
      'username': 'cleanagency1',
      'password': 'Agency123!',
      'full_name': 'CleanSpace Agency',
      'email': 'agency@cleanspace.dz',
      'phone': '+213555123456',
      'user_type': 'Agency',
      'agency_name': 'CleanSpace Agency',
      'business_id': 'BI123456',
      'bio': 'Professional cleaning services for homes and offices',
      'address': 'Alger, Algeria',
      'gender': 'Male',
      'birthdate': '1990-01-01',
      'avatar_url': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop',
      'created_at': DateTime.now().toIso8601String(),
    });

    
    await repo.insertProfile({
      'username': 'client1',
      'password': 'Client123!',
      'full_name': 'Ahmed Benali',
      'email': 'ahmed@example.com',
      'phone': '+213555789012',
      'user_type': 'Client',
      'bio': 'Looking for reliable cleaning services',
      'address': 'Oran, Algeria',
      'gender': 'Male',
      'birthdate': '1985-05-15',
      'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
      'created_at': DateTime.now().toIso8601String(),
    });

    
    await repo.insertProfile({
      'username': 'cleaner1',
      'password': 'Cleaner123!',
      'full_name': 'Fatima Zahra',
      'email': 'fatima@example.com',
      'phone': '+213555345678',
      'user_type': 'Individual Cleaner',
      'bio': 'Experienced cleaner with 5+ years of experience',
      'services': 'Home cleaning, Office cleaning, Deep cleaning',
      'hourly_rate': '1500',
      'address': 'Constantine, Algeria',
      'gender': 'Female',
      'birthdate': '1992-03-20',
      'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _seedJobs() async {
    final repo = AbstractJobsRepo.getInstance();
    
    
    final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
    final agency = profiles.firstWhere(
      (p) => p['user_type'] == 'Agency',
      orElse: () => profiles.first,
    );
    final agencyId = agency['id'] as int;

    
    final now = DateTime.now();
    
    await repo.createJob(Job(
      title: 'Office Cleaning',
      city: 'Algiers',
      country: 'Algeria',
      description: 'Daily cleaning for small-medium offices',
      status: JobStatus.active,
      postedDate: now.subtract(const Duration(days: 2)),
      jobDate: now.add(const Duration(days: 5)),
      agencyId: agencyId,
      coverImageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=400&fit=crop',
    ));

    await repo.createJob(Job(
      title: 'Apartment Cleaning Service',
      city: 'Oran',
      country: 'Algeria',
      description: 'Deep cleaning for 2-bedroom apartments',
      status: JobStatus.active,
      postedDate: now.subtract(const Duration(days: 5)),
      jobDate: now.add(const Duration(days: 3)),
      agencyId: agencyId,
      coverImageUrl: 'https://images.unsplash.com/photo-1581579184808-b72b4f5f8a03?w=800&h=400&fit=crop',
    ));

    await repo.createJob(Job(
      title: 'Window Washing Service',
      city: 'Constantine',
      country: 'Algeria',
      description: 'Professional window cleaning for homes and businesses',
      status: JobStatus.paused,
      postedDate: now.subtract(const Duration(days: 10)),
      jobDate: now.add(const Duration(days: 7)),
      agencyId: agencyId,
      coverImageUrl: 'https://images.unsplash.com/photo-1581578017423-3b243dbb3a34?w=800&h=400&fit=crop',
    ));

    
    final client = profiles.firstWhere(
      (p) => p['user_type'] == 'Client',
      orElse: () => profiles.first,
    );
    final clientId = client['id'] as int;

    
    await repo.createJob(Job(
      title: 'Specialty Cleaning - Alger',
      city: 'Algiers',
      country: 'Algeria',
      description: 'Deep cleaning needed for a 3-bedroom apartment. Focus on kitchen and bathrooms.',
      status: JobStatus.active,
      postedDate: now.subtract(const Duration(days: 1)),
      jobDate: now.add(const Duration(days: 3)),
      clientId: clientId,
      coverImageUrl: 'https://images.unsplash.com/photo-1581579184808-b72b4f5f8a03?w=800&h=400&fit=crop',
      budgetMin: 5000.0,
      budgetMax: 8000.0,
      estimatedHours: 4,
      requiredServices: ['Deep Cleaning', 'Kitchen Cleaning', 'Bathroom Cleaning'],
    ));

    await repo.createJob(Job(
      title: 'Office Cleaning - Béchar',
      city: 'Béchar',
      country: 'Algeria',
      description: 'Weekly office cleaning service for a small business. Need reliable and professional service.',
      status: JobStatus.active,
      postedDate: now.subtract(const Duration(days: 2)),
      jobDate: now.add(const Duration(days: 5)),
      clientId: clientId,
      coverImageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=400&fit=crop',
      budgetMin: 3000.0,
      budgetMax: 5000.0,
      estimatedHours: 3,
      requiredServices: ['Office Cleaning', 'Floor Cleaning'],
    ));

    await repo.createJob(Job(
      title: 'Villa Deep Clean',
      city: 'Oran',
      country: 'Algeria',
      description: 'Complete deep cleaning for a large villa. All rooms including windows and outdoor areas.',
      status: JobStatus.active,
      postedDate: now.subtract(const Duration(days: 3)),
      jobDate: now.add(const Duration(days: 7)),
      clientId: clientId,
      coverImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&h=400&fit=crop',
      budgetMin: 10000.0,
      budgetMax: 15000.0,
      estimatedHours: 8,
      requiredServices: ['Deep Cleaning', 'Window Cleaning', 'Outdoor Cleaning'],
    ));
  }

  static Future<void> _seedCleaners() async {
    final repo = AbstractCleanersRepo.getInstance();
    
    
    final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
    final agency = profiles.firstWhere(
      (p) => p['user_type'] == 'Agency',
      orElse: () => profiles.first,
    );
    final agencyId = agency['id'] as int;

    
    await repo.addCleaner(Cleaner(
      name: 'Fatima Zahra',
      rating: 4.8,
      jobsCompleted: 124,
      agencyId: agencyId,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
    ));

    await repo.addCleaner(Cleaner(
      name: 'Ahmed Ali',
      rating: 5.0,
      jobsCompleted: 98,
      agencyId: agencyId,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    ));

    await repo.addCleaner(Cleaner(
      name: 'Yasmine K.',
      rating: 4.5,
      jobsCompleted: 76,
      agencyId: agencyId,
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop',
    ));
  }

  static Future<void> _seedCleaningHistory() async {
    final repo = AbstractCleaningHistoryRepo.getInstance();
    
    
    final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
    final cleaner = profiles.firstWhere(
      (p) => p['user_type'] == 'Individual Cleaner' && p['full_name'] == 'Fatima Zahra',
      orElse: () => profiles.firstWhere(
        (p) => p['user_type'] == 'Individual Cleaner',
        orElse: () => profiles.first,
      ),
    );
    final cleanerId = cleaner['id'] as int;
    final now = DateTime.now();

    
    await repo.addHistoryItem(CleaningHistoryItem(
      cleanerId: cleanerId,
      title: 'Office Building',
      date: now.subtract(const Duration(days: 5)),
      description: 'Standard office cleaning, completed successfully.',
      type: CleaningHistoryType.office,
    ));

    await repo.addHistoryItem(CleaningHistoryItem(
      cleanerId: cleanerId,
      title: 'Apartment',
      date: now.subtract(const Duration(days: 20)),
      description: 'Deep cleaning service for a 3-bedroom apartment.',
      type: CleaningHistoryType.apartment,
    ));

    await repo.addHistoryItem(CleaningHistoryItem(
      cleanerId: cleanerId,
      title: 'Villa',
      date: now.subtract(const Duration(days: 30)),
      description: 'Full-day cleaning for a large villa, including windows.',
      type: CleaningHistoryType.villa,
    ));
  }

  static Future<void> _seedCleanerReviews() async {
    final repo = AbstractCleanerReviewsRepo.getInstance();
    
    
    final profiles = await AbstractProfileRepo.getInstance().getAllProfiles();
    final cleaner = profiles.firstWhere(
      (p) => p['user_type'] == 'Individual Cleaner' && p['full_name'] == 'Fatima Zahra',
      orElse: () => profiles.firstWhere(
        (p) => p['user_type'] == 'Individual Cleaner',
        orElse: () => profiles.first,
      ),
    );
    final cleanerId = cleaner['id'] as int;
    final now = DateTime.now();

    
    await repo.addReview(CleanerReview(
      cleanerId: cleanerId,
      reviewerName: 'Amina K.',
      rating: 5.0,
      date: now.subtract(const Duration(days: 10)),
      comment: 'Fatima was amazing! She left my apartment sparkling clean. Very professional and friendly.',
      hasPhotos: false,
    ));

    await repo.addReview(CleanerReview(
      cleanerId: cleanerId,
      reviewerName: 'Karim B.',
      rating: 5.0,
      date: now.subtract(const Duration(days: 28)),
      comment: 'Great service, very thorough. Would hire again.',
      hasPhotos: false,
    ));

    await repo.addReview(CleanerReview(
      cleanerId: cleanerId,
      reviewerName: 'Yasmine L.',
      rating: 5.0,
      date: now.subtract(const Duration(days: 45)),
      comment: 'Excellent work! My house has never been cleaner. Fatima paid attention to every detail.',
      hasPhotos: true,
      photoUrls: ['photo1.jpg', 'photo2.jpg'],
    ));
  }
}

