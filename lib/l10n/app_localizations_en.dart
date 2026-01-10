// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CleanSpace';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get loginWithFacebook => 'Login with Facebook';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createOneNow => 'Create one now';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get bio => 'Bio';

  @override
  String get gender => 'Gender';

  @override
  String get birthdate => 'Birthdate';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get iAmA => 'I am a...';

  @override
  String get client => 'Client';

  @override
  String get agency => 'Agency';

  @override
  String get individualCleaner => 'Individual Cleaner';

  @override
  String get agencyName => 'Agency Name';

  @override
  String get businessId => 'Business Registration ID';

  @override
  String get enterAgencyName => 'Enter agency name';

  @override
  String get enterBusinessRegistrationId => 'Enter business registration ID';

  @override
  String get agencyNameRequired => 'Agency name is required';

  @override
  String get businessIdRequired => 'Business registration ID is required';

  @override
  String get services => 'Services Offered';

  @override
  String get hourlyRate => 'Hourly Rate';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get profile => 'Profile';

  @override
  String get activeListings => 'Active Listings';

  @override
  String get pastBookings => 'Past Bookings';

  @override
  String get cleanerTeam => 'Cleaner Team';

  @override
  String get jobsCompleted => 'Jobs Completed';

  @override
  String get addNewJob => 'Add New Job';

  @override
  String get noActiveListings => 'No active listings yet.';

  @override
  String get noPastBookings => 'No past bookings yet.';

  @override
  String get noCleaners => 'No cleaners in your team yet.';

  @override
  String postedOn(String date) {
    return 'Posted on: $date';
  }

  @override
  String get edit => 'Edit';

  @override
  String get pause => 'Pause';

  @override
  String get activate => 'Activate';

  @override
  String get delete => 'Delete';

  @override
  String get searchMyListings => 'Search my listings...';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get sortByDate => 'Sort by Date';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get paused => 'Paused';

  @override
  String get booked => 'Booked';

  @override
  String get completed => 'Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get recentListings => 'Recent Listings';

  @override
  String get topAgencies => 'Top Agencies';

  @override
  String get topCleaners => 'Top Cleaners';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get apply => 'Apply';

  @override
  String get bookNow => 'Book Now';

  @override
  String get myPosts => 'My Posts';

  @override
  String get history => 'History';

  @override
  String get reviews => 'Reviews';

  @override
  String get favorites => 'Favorites';

  @override
  String get logout => 'Logout';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String accountCreated(String role) {
    return 'Account created as $role!';
  }

  @override
  String get invalidCredentials => 'Invalid username or password';

  @override
  String get usernameExists => 'Username already exists';

  @override
  String get emailExists => 'Email already exists';

  @override
  String get phoneExists => 'Phone number already exists';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String confirmDelete(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteJob => 'Delete Job';

  @override
  String get jobDeleted => 'Job deleted successfully';

  @override
  String get jobStatusChanged => 'Job status updated';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get goToHome => 'Go to Home';

  @override
  String hello(String name) {
    return 'Hello $name';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required to receive updates';

  @override
  String get notificationPermissionDenied => 'Notification permission denied';

  @override
  String get newBooking => 'New Booking';

  @override
  String get bookingUpdated => 'Booking Updated';

  @override
  String get newJobAvailable => 'New Job Available';

  @override
  String get settingsPage => 'Settings Page';

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get payment => 'Payment';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get support => 'Support';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logOut => 'Log Out?';

  @override
  String get logOutMessage =>
      'Are you sure you want to log out of your CleanSpace account?';

  @override
  String get yesLogOut => 'Yes, Log Out';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get addPost => 'Add Post';

  @override
  String get postNow => 'Post Now';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get budget => 'Budget';

  @override
  String get estimatedDuration => 'Estimated Duration';

  @override
  String get hours => 'Hours';

  @override
  String get days => 'Days';

  @override
  String get selectServiceType => 'Select Service Type';

  @override
  String get selectProvince => 'Select Province';

  @override
  String get uploadImages => 'Upload Images';

  @override
  String get maxImages => 'Maximum 5 images';

  @override
  String get pleaseLogin => 'Please login to post a job';

  @override
  String get jobPostedSuccessfully => 'Job posted successfully!';

  @override
  String get searchForCleaningServices => 'Search for cleaning services';

  @override
  String get location => 'Location';

  @override
  String get rating => 'Rating';

  @override
  String get price => 'Price';

  @override
  String get selectWilayasMultiple => 'Select Wilayas (Multiple)';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get done => 'Done';

  @override
  String get ratingRange => 'Rating Range';

  @override
  String get minRating => 'Min Rating (0-5)';

  @override
  String get maxRating => 'Max Rating (0-5)';

  @override
  String get clear => 'Clear';

  @override
  String get priceRangeDzd => 'Price Range (DZD)';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get noCleanersFound => 'No cleaners found';

  @override
  String get addToTeam => 'Add to Team';

  @override
  String get invalidProfile => 'Invalid profile';

  @override
  String get cleanerAlreadyInTeam => 'This cleaner is already in your team';

  @override
  String get cleanerAddedSuccessfully => 'Cleaner added successfully!';

  @override
  String get errorAddingCleaner => 'Error adding cleaner';

  @override
  String get remove => 'Remove';

  @override
  String get removeCleaner => 'Remove Cleaner';

  @override
  String get areYouSureRemoveCleaner =>
      'Are you sure you want to remove this cleaner from your team?';

  @override
  String get cleanerRemovedSuccessfully => 'Cleaner removed successfully!';

  @override
  String get errorRemovingCleaner => 'Error removing cleaner';

  @override
  String get availableJobs => 'Available Jobs';

  @override
  String get pending => 'Pending';

  @override
  String get assigned => 'Assigned';

  @override
  String get jobDone => 'Done';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get manageJob => 'Manage Job';

  @override
  String get pauseJob => 'Pause Job';

  @override
  String get activateJob => 'Activate Job';

  @override
  String get leaveReview => 'Leave a Review';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get applications => 'Applications';

  @override
  String get noApplications => 'No applications yet';

  @override
  String get assignedWorker => 'Assigned Worker';

  @override
  String get noWorkerAssigned => 'No worker assigned yet';

  @override
  String get overview => 'Overview';

  @override
  String get aboutMe => 'About Me';

  @override
  String get viewDetails => 'View Details';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get idVerificationMessage =>
      'For the safety of our community, we require ID verification.';

  @override
  String get uploadId => 'Upload ID';

  @override
  String get idUploadDescription => 'Front and back of your ID';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get dateFormatHint => 'mm/dd/yyyy';

  @override
  String get wilayaProvince => 'Wilaya (Province)';

  @override
  String get selectYourWilaya => 'Select your wilaya';

  @override
  String get baladiya => 'Baladiya';

  @override
  String get selectYourBaladiya => 'Select your baladiya (optional)';

  @override
  String get enterStreetName => 'Enter street name, building number, etc.';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself...';

  @override
  String get contactForPricing => 'Contact for pricing';

  @override
  String get postANewJob => 'Post a New Job';

  @override
  String get locationWilaya => 'Location (Wilaya)';

  @override
  String get selectYourProvince => 'Select your province';

  @override
  String get yourBudgetDzd => 'Your Budget (DZD)';

  @override
  String get enterYourBudget => 'Enter your budget';

  @override
  String get durationExample => 'e.g., 3';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get maximumPhotosAllowed => 'Maximum 5 photos allowed';

  @override
  String get pleaseSelectServiceType => 'Please select a service type';

  @override
  String get pleaseSelectLocation => 'Please select a location';

  @override
  String get pleaseEnterBudget => 'Please enter a budget';

  @override
  String get pleaseEnterJobDescription => 'Please enter a job description';

  @override
  String errorPickingImages(String error) {
    return 'Error picking images: $error';
  }

  @override
  String errorPostingJob(String error) {
    return 'Error posting job: $error';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get posted => 'Posted';

  @override
  String get weeks => 'Weeks';

  @override
  String get homeCleaning => 'Home Cleaning';

  @override
  String get officeCleaning => 'Office Cleaning';

  @override
  String get specialtyCleaning => 'Specialty Cleaning';

  @override
  String get industrialCleaning => 'Industrial Cleaning';

  @override
  String get clickToUpload => 'Click to upload';

  @override
  String get dragAndDrop => ' or drag and drop';

  @override
  String get maximumPhotosReached => 'Maximum 5 photos reached';

  @override
  String get egPlaceholder => 'e.g., 3';

  @override
  String fromDzdPerHr(String hourlyRate) {
    return 'From $hourlyRate DZD/hr';
  }

  @override
  String get available => 'Available';

  @override
  String get noActiveListingsYet => 'No active listings yet.';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get noUserDataAvailable => 'No user data available';

  @override
  String get unknown => 'Unknown';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get justNow => 'Just now';

  @override
  String get budgetNegotiable => 'Budget negotiable';

  @override
  String get untitledJob => 'Untitled Job';

  @override
  String areYouSureDeleteJob(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get verified => 'Verified';

  @override
  String partOfAgency(String agency) {
    return 'Part of $agency';
  }

  @override
  String get experience => 'Experience';

  @override
  String get age => 'Age';

  @override
  String get languages => 'Languages';

  @override
  String get servicesOffered => 'Services Offered';

  @override
  String get noCleaningHistoryYet => 'No cleaning history yet.';

  @override
  String get jobDetails => 'Job Details';

  @override
  String get postedBy => 'Posted by';

  @override
  String get description => 'Description';

  @override
  String estimatedHours(int hours) {
    return 'Est. $hours hours';
  }

  @override
  String get submitBid => 'Submit Bid';

  @override
  String get yourBidPrice => 'Your Bid Price (DZD)';

  @override
  String get enterBidPrice => 'Enter your bid price';

  @override
  String get messageToClient => 'Message to Client (Optional)';

  @override
  String get enterMessage => 'Enter your message';

  @override
  String get pleaseLoginToSubmitBid => 'Please login to submit a bid';

  @override
  String get unableToGetUserId => 'Unable to get user ID';

  @override
  String get pleaseEnterValidBidPrice => 'Please enter a valid bid price';

  @override
  String get bidSubmittedSuccessfully => 'Bid submitted successfully!';

  @override
  String get errorSubmittingBid => 'Error submitting bid';

  @override
  String get errorSubmittingBidInvalidData =>
      'Error submitting bid: Invalid data format. Please try again.';

  @override
  String get errorSubmittingBidUnexpected =>
      'Error submitting bid: An unexpected error occurred';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get profilePictureUpdatedSuccessfully =>
      'Profile picture updated successfully!';

  @override
  String get profilePictureRemovedSuccessfully =>
      'Profile picture removed successfully!';

  @override
  String get failedToRemoveProfilePicture => 'Failed to remove profile picture';

  @override
  String get servicesOfferedLabel => 'Services Offered';

  @override
  String get experienceLevel => 'Experience Level';

  @override
  String get selectExperienceLevel => 'Select experience level';

  @override
  String get entry => 'Entry';

  @override
  String get mid => 'Mid';

  @override
  String get senior => 'Senior';

  @override
  String get hourlyRateDzd => 'Hourly Rate (DZD)';

  @override
  String get pleaseSelectAtLeastOneService =>
      'Please select at least one service';

  @override
  String get wilayaRequired => 'Wilaya is required';

  @override
  String get baladiyaMunicipality => 'Baladiya (Municipality)';

  @override
  String get streetAddressOptional => 'Street Address (Optional)';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get areYouSureDeleteAccount =>
      'Are you sure you want to delete your account? This action is irreversible and all your posts will be deleted.';

  @override
  String get yesDeleteAccount => 'Yes, Delete Account';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get settings => 'Settings';

  @override
  String get cleaner => 'Cleaner';

  @override
  String get individual => 'Individual';

  @override
  String get agencyProfileComingSoon => 'Agency profile coming soon';

  @override
  String get noPastBookingsYet => 'No past bookings yet.';

  @override
  String get noCleanersInTeamYet => 'No cleaners in your team yet.';

  @override
  String get errorLoadingCleanerProfile => 'Error loading cleaner profile';

  @override
  String get addCleaner => 'Add Cleaner';

  @override
  String get requiredServices => 'Required Services';

  @override
  String get yourBid => 'Your Bid';

  @override
  String get yourPriceDa => 'Your Price (DA)';

  @override
  String get enterYourBidPrice => 'Enter your bid price';

  @override
  String get pleaseEnterBidPrice => 'Please enter a bid price';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get messageOptional => 'Message (Optional)';

  @override
  String get addShortMessageToClient => 'Add a short message to the client...';

  @override
  String estimatedHoursFormat(int hours) {
    return 'Est. $hours hours';
  }

  @override
  String get noReviewsYet => 'No reviews yet.';

  @override
  String get bid => 'Bid';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get phone => 'Phone';

  @override
  String get partOf => 'Part of';

  @override
  String get allReviews => 'All Reviews';

  @override
  String get cleaningHistory => 'Cleaning History';

  @override
  String get noCleaningHistoryAvailable => 'No cleaning history available';

  @override
  String get cleanerIdNotFound => 'Cleaner ID not found';

  @override
  String get cleaningJob => 'Cleaning Job';

  @override
  String get activePosts => 'Active Posts';

  @override
  String get noPostsYet => 'No posts yet.';

  @override
  String get noActivePosts => 'No active posts.';

  @override
  String get myPostsOnlyForClients => 'My Posts is only available for clients.';

  @override
  String get activePostsOnlyForClients =>
      'Active Posts is only available for clients.';

  @override
  String reviewsCount(int count) {
    return '$count Reviews';
  }

  @override
  String get cleanSpaceFeatures => 'CleanSpace Features';

  @override
  String get everythingYouNeed => 'Everything you need in one app';

  @override
  String get findVerifiedCleaners => 'Find Verified Cleaners';

  @override
  String get browseTrustedProfessionals =>
      'Browse trusted professionals with verified profiles and ratings';

  @override
  String get easyBooking => 'Easy Booking';

  @override
  String get postYourJob =>
      'Post your job and receive offers from qualified cleaners';

  @override
  String get jobOpportunities => 'Job Opportunities';

  @override
  String get findStableWork =>
      'Find stable work and grow your cleaning business';

  @override
  String get cleaspaceExperience => 'CLEASPACE EXPERIENCE';

  @override
  String get allInOnePlatform =>
      'All-in-one platform for trusted cleaning services.';

  @override
  String get verifiedProfessionals => 'Verified Professionals';

  @override
  String get everyCleanerPasses =>
      'Every cleaner and agency passes identity and quality checks for full trust.';

  @override
  String get smartMatching => 'Smart Matching';

  @override
  String get browseCuratedLists =>
      'Browse curated lists or let CleanSpace suggest best-fit cleaners.';

  @override
  String get transparentPricing => 'Transparent Pricing';

  @override
  String get seeClearHourlyRates =>
      'See clear hourly rates before booking. No hidden surprises.';

  @override
  String get cleaspaceAlgeria => 'CLEASPACE ALGERIA';

  @override
  String get readyToLaunch => 'Ready to launch your next clean space?';

  @override
  String get createAccountDescription =>
      'Create an account to book trusted cleaners, manage agencies, or offer your cleaning services to Algeria\'s growing market.';

  @override
  String get next => 'Next';

  @override
  String get skipToLogin => 'Skip to login';

  @override
  String get iAlreadyHaveAccount => 'I already have an account';

  @override
  String get createAccountPage => 'Create Account Page';

  @override
  String get uploadProfilePicture => 'Upload Profile Picture';

  @override
  String get uploadAClearPhoto => 'Upload a clear photo';

  @override
  String get photoSelected => 'Photo selected';
}
