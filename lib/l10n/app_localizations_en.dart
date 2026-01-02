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
  String get createAccount => 'Create Account';

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
  String get noActiveListings =>
      'No active listings yet.\nTap the + button to add a new job.';

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
}
