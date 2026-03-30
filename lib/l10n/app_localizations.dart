import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'CleanSpace'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Login with Facebook'**
  String get loginWithFacebook;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createOneNow.
  ///
  /// In en, this message translates to:
  /// **'Create one now'**
  String get createOneNow;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a...'**
  String get iAmA;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @agency.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get agency;

  /// No description provided for @individualCleaner.
  ///
  /// In en, this message translates to:
  /// **'Individual Cleaner'**
  String get individualCleaner;

  /// No description provided for @agencyName.
  ///
  /// In en, this message translates to:
  /// **'Agency Name'**
  String get agencyName;

  /// No description provided for @businessId.
  ///
  /// In en, this message translates to:
  /// **'Business Registration ID'**
  String get businessId;

  /// No description provided for @enterAgencyName.
  ///
  /// In en, this message translates to:
  /// **'Enter agency name'**
  String get enterAgencyName;

  /// No description provided for @enterBusinessRegistrationId.
  ///
  /// In en, this message translates to:
  /// **'Enter business registration ID'**
  String get enterBusinessRegistrationId;

  /// No description provided for @agencyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Agency name is required'**
  String get agencyNameRequired;

  /// No description provided for @businessIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Business registration ID is required'**
  String get businessIdRequired;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services Offered'**
  String get services;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @pastBookings.
  ///
  /// In en, this message translates to:
  /// **'Past Bookings'**
  String get pastBookings;

  /// No description provided for @cleanerTeam.
  ///
  /// In en, this message translates to:
  /// **'Cleaner Team'**
  String get cleanerTeam;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Completed'**
  String get jobsCompleted;

  /// No description provided for @addNewJob.
  ///
  /// In en, this message translates to:
  /// **'Add New Job'**
  String get addNewJob;

  /// No description provided for @noActiveListings.
  ///
  /// In en, this message translates to:
  /// **'No active listings yet.'**
  String get noActiveListings;

  /// No description provided for @noPastBookings.
  ///
  /// In en, this message translates to:
  /// **'No past bookings yet.'**
  String get noPastBookings;

  /// No description provided for @noCleaners.
  ///
  /// In en, this message translates to:
  /// **'No cleaners in your team yet.'**
  String get noCleaners;

  /// No description provided for @postedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted on: {date}'**
  String postedOn(String date);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchMyListings.
  ///
  /// In en, this message translates to:
  /// **'Search my listings...'**
  String get searchMyListings;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date'**
  String get sortByDate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @recentListings.
  ///
  /// In en, this message translates to:
  /// **'Recent Listings'**
  String get recentListings;

  /// No description provided for @topAgencies.
  ///
  /// In en, this message translates to:
  /// **'Top Agencies'**
  String get topAgencies;

  /// No description provided for @topCleaners.
  ///
  /// In en, this message translates to:
  /// **'Top Cleaners'**
  String get topCleaners;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created as {role}!'**
  String accountCreated(String role);

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @usernameExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists'**
  String get usernameExists;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists'**
  String get emailExists;

  /// No description provided for @phoneExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists'**
  String get phoneExists;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDelete(String title);

  /// No description provided for @deleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get deleteJob;

  /// No description provided for @jobDeleted.
  ///
  /// In en, this message translates to:
  /// **'Job deleted successfully'**
  String get jobDeleted;

  /// No description provided for @jobStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Job status updated'**
  String get jobStatusChanged;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}'**
  String hello(String name);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to receive updates'**
  String get notificationPermissionRequired;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationPermissionDenied;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get newBooking;

  /// No description provided for @bookingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Booking Updated'**
  String get bookingUpdated;

  /// No description provided for @newJobAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Job Available'**
  String get newJobAvailable;

  /// No description provided for @settingsPage.
  ///
  /// In en, this message translates to:
  /// **'Settings Page'**
  String get settingsPage;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get logOut;

  /// No description provided for @logOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your CleanSpace account?'**
  String get logOutMessage;

  /// No description provided for @yesLogOut.
  ///
  /// In en, this message translates to:
  /// **'Yes, Log Out'**
  String get yesLogOut;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @addPost.
  ///
  /// In en, this message translates to:
  /// **'Add Post'**
  String get addPost;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Post Now'**
  String get postNow;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @selectServiceType.
  ///
  /// In en, this message translates to:
  /// **'Select Service Type'**
  String get selectServiceType;

  /// No description provided for @selectProvince.
  ///
  /// In en, this message translates to:
  /// **'Select Province'**
  String get selectProvince;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImages;

  /// No description provided for @maxImages.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 images'**
  String get maxImages;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login to post a job'**
  String get pleaseLogin;

  /// No description provided for @jobPostedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Job posted successfully!'**
  String get jobPostedSuccessfully;

  /// No description provided for @searchForCleaningServices.
  ///
  /// In en, this message translates to:
  /// **'Search for cleaning services'**
  String get searchForCleaningServices;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @selectWilayasMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select Wilayas (Multiple)'**
  String get selectWilayasMultiple;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ratingRange.
  ///
  /// In en, this message translates to:
  /// **'Rating Range'**
  String get ratingRange;

  /// No description provided for @minRating.
  ///
  /// In en, this message translates to:
  /// **'Min Rating (0-5)'**
  String get minRating;

  /// No description provided for @maxRating.
  ///
  /// In en, this message translates to:
  /// **'Max Rating (0-5)'**
  String get maxRating;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @priceRangeDzd.
  ///
  /// In en, this message translates to:
  /// **'Price Range (DZD)'**
  String get priceRangeDzd;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @noCleanersFound.
  ///
  /// In en, this message translates to:
  /// **'No cleaners found'**
  String get noCleanersFound;

  /// No description provided for @addToTeam.
  ///
  /// In en, this message translates to:
  /// **'Add to Team'**
  String get addToTeam;

  /// No description provided for @invalidProfile.
  ///
  /// In en, this message translates to:
  /// **'Invalid profile'**
  String get invalidProfile;

  /// No description provided for @cleanerAlreadyInTeam.
  ///
  /// In en, this message translates to:
  /// **'This cleaner is already in your team'**
  String get cleanerAlreadyInTeam;

  /// No description provided for @cleanerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cleaner added successfully!'**
  String get cleanerAddedSuccessfully;

  /// No description provided for @errorAddingCleaner.
  ///
  /// In en, this message translates to:
  /// **'Error adding cleaner'**
  String get errorAddingCleaner;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeCleaner.
  ///
  /// In en, this message translates to:
  /// **'Remove Cleaner'**
  String get removeCleaner;

  /// No description provided for @areYouSureRemoveCleaner.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this cleaner from your team?'**
  String get areYouSureRemoveCleaner;

  /// No description provided for @cleanerRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cleaner removed successfully!'**
  String get cleanerRemovedSuccessfully;

  /// No description provided for @errorRemovingCleaner.
  ///
  /// In en, this message translates to:
  /// **'Error removing cleaner'**
  String get errorRemovingCleaner;

  /// No description provided for @availableJobs.
  ///
  /// In en, this message translates to:
  /// **'Available Jobs'**
  String get availableJobs;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @jobDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get jobDone;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @manageJob.
  ///
  /// In en, this message translates to:
  /// **'Manage Job'**
  String get manageJob;

  /// No description provided for @pauseJob.
  ///
  /// In en, this message translates to:
  /// **'Pause Job'**
  String get pauseJob;

  /// No description provided for @activateJob.
  ///
  /// In en, this message translates to:
  /// **'Activate Job'**
  String get activateJob;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get leaveReview;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @noApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get noApplications;

  /// No description provided for @assignedWorker.
  ///
  /// In en, this message translates to:
  /// **'Assigned Worker'**
  String get assignedWorker;

  /// No description provided for @noWorkerAssigned.
  ///
  /// In en, this message translates to:
  /// **'No worker assigned yet'**
  String get noWorkerAssigned;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @idVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'For the safety of our community, we require ID verification.'**
  String get idVerificationMessage;

  /// No description provided for @uploadId.
  ///
  /// In en, this message translates to:
  /// **'Upload ID'**
  String get uploadId;

  /// No description provided for @idUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Front and back of your ID'**
  String get idUploadDescription;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @dateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'mm/dd/yyyy'**
  String get dateFormatHint;

  /// No description provided for @wilayaProvince.
  ///
  /// In en, this message translates to:
  /// **'Wilaya (Province)'**
  String get wilayaProvince;

  /// No description provided for @selectYourWilaya.
  ///
  /// In en, this message translates to:
  /// **'Select your wilaya'**
  String get selectYourWilaya;

  /// No description provided for @baladiya.
  ///
  /// In en, this message translates to:
  /// **'Baladiya'**
  String get baladiya;

  /// No description provided for @selectYourBaladiya.
  ///
  /// In en, this message translates to:
  /// **'Select your baladiya (optional)'**
  String get selectYourBaladiya;

  /// No description provided for @enterStreetName.
  ///
  /// In en, this message translates to:
  /// **'Enter street name, building number, etc.'**
  String get enterStreetName;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// No description provided for @contactForPricing.
  ///
  /// In en, this message translates to:
  /// **'Contact for pricing'**
  String get contactForPricing;

  /// No description provided for @postANewJob.
  ///
  /// In en, this message translates to:
  /// **'Post a New Job'**
  String get postANewJob;

  /// No description provided for @locationWilaya.
  ///
  /// In en, this message translates to:
  /// **'Location (Wilaya)'**
  String get locationWilaya;

  /// No description provided for @selectYourProvince.
  ///
  /// In en, this message translates to:
  /// **'Select your province'**
  String get selectYourProvince;

  /// No description provided for @yourBudgetDzd.
  ///
  /// In en, this message translates to:
  /// **'Your Budget (DZD)'**
  String get yourBudgetDzd;

  /// No description provided for @enterYourBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter your budget'**
  String get enterYourBudget;

  /// No description provided for @durationExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 3'**
  String get durationExample;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @maximumPhotosAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos allowed'**
  String get maximumPhotosAllowed;

  /// No description provided for @pleaseSelectServiceType.
  ///
  /// In en, this message translates to:
  /// **'Please select a service type'**
  String get pleaseSelectServiceType;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectLocation;

  /// No description provided for @pleaseEnterBudget.
  ///
  /// In en, this message translates to:
  /// **'Please enter a budget'**
  String get pleaseEnterBudget;

  /// No description provided for @pleaseEnterJobDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a job description'**
  String get pleaseEnterJobDescription;

  /// No description provided for @errorPickingImages.
  ///
  /// In en, this message translates to:
  /// **'Error picking images: {error}'**
  String errorPickingImages(String error);

  /// No description provided for @errorPostingJob.
  ///
  /// In en, this message translates to:
  /// **'Error posting job: {error}'**
  String errorPostingJob(String error);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @posted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get posted;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @homeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Home Cleaning'**
  String get homeCleaning;

  /// No description provided for @officeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Office Cleaning'**
  String get officeCleaning;

  /// No description provided for @specialtyCleaning.
  ///
  /// In en, this message translates to:
  /// **'Specialty Cleaning'**
  String get specialtyCleaning;

  /// No description provided for @industrialCleaning.
  ///
  /// In en, this message translates to:
  /// **'Industrial Cleaning'**
  String get industrialCleaning;

  /// No description provided for @clickToUpload.
  ///
  /// In en, this message translates to:
  /// **'Click to upload'**
  String get clickToUpload;

  /// No description provided for @dragAndDrop.
  ///
  /// In en, this message translates to:
  /// **' or drag and drop'**
  String get dragAndDrop;

  /// No description provided for @maximumPhotosReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos reached'**
  String get maximumPhotosReached;

  /// No description provided for @egPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., 3'**
  String get egPlaceholder;

  /// No description provided for @fromDzdPerHr.
  ///
  /// In en, this message translates to:
  /// **'From {hourlyRate} DZD/hr'**
  String fromDzdPerHr(String hourlyRate);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @noActiveListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No active listings yet.'**
  String get noActiveListingsYet;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @noUserDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No user data available'**
  String get noUserDataAvailable;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @budgetNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Budget negotiable'**
  String get budgetNegotiable;

  /// No description provided for @untitledJob.
  ///
  /// In en, this message translates to:
  /// **'Untitled Job'**
  String get untitledJob;

  /// No description provided for @areYouSureDeleteJob.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String areYouSureDeleteJob(String title);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @partOfAgency.
  ///
  /// In en, this message translates to:
  /// **'Part of {agency}'**
  String partOfAgency(String agency);

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @servicesOffered.
  ///
  /// In en, this message translates to:
  /// **'Services Offered'**
  String get servicesOffered;

  /// No description provided for @noCleaningHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No cleaning history yet.'**
  String get noCleaningHistoryYet;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @estimatedHours.
  ///
  /// In en, this message translates to:
  /// **'Est. {hours} hours'**
  String estimatedHours(int hours);

  /// No description provided for @submitBid.
  ///
  /// In en, this message translates to:
  /// **'Submit Bid'**
  String get submitBid;

  /// No description provided for @yourBidPrice.
  ///
  /// In en, this message translates to:
  /// **'Your Bid Price (DZD)'**
  String get yourBidPrice;

  /// No description provided for @enterBidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter your bid price'**
  String get enterBidPrice;

  /// No description provided for @messageToClient.
  ///
  /// In en, this message translates to:
  /// **'Message to Client (Optional)'**
  String get messageToClient;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterMessage;

  /// No description provided for @pleaseLoginToSubmitBid.
  ///
  /// In en, this message translates to:
  /// **'Please login to submit a bid'**
  String get pleaseLoginToSubmitBid;

  /// No description provided for @unableToGetUserId.
  ///
  /// In en, this message translates to:
  /// **'Unable to get user ID'**
  String get unableToGetUserId;

  /// No description provided for @pleaseEnterValidBidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid bid price'**
  String get pleaseEnterValidBidPrice;

  /// No description provided for @bidSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bid submitted successfully!'**
  String get bidSubmittedSuccessfully;

  /// No description provided for @errorSubmittingBid.
  ///
  /// In en, this message translates to:
  /// **'Error submitting bid'**
  String get errorSubmittingBid;

  /// No description provided for @errorSubmittingBidInvalidData.
  ///
  /// In en, this message translates to:
  /// **'Error submitting bid: Invalid data format. Please try again.'**
  String get errorSubmittingBidInvalidData;

  /// No description provided for @errorSubmittingBidUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Error submitting bid: An unexpected error occurred'**
  String get errorSubmittingBidUnexpected;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @profilePictureUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdatedSuccessfully;

  /// No description provided for @profilePictureRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed successfully!'**
  String get profilePictureRemovedSuccessfully;

  /// No description provided for @failedToRemoveProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile picture'**
  String get failedToRemoveProfilePicture;

  /// No description provided for @servicesOfferedLabel.
  ///
  /// In en, this message translates to:
  /// **'Services Offered'**
  String get servicesOfferedLabel;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevel;

  /// No description provided for @selectExperienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Select experience level'**
  String get selectExperienceLevel;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @mid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get mid;

  /// No description provided for @senior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get senior;

  /// No description provided for @hourlyRateDzd.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (DZD)'**
  String get hourlyRateDzd;

  /// No description provided for @pleaseSelectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get pleaseSelectAtLeastOneService;

  /// No description provided for @wilayaRequired.
  ///
  /// In en, this message translates to:
  /// **'Wilaya is required'**
  String get wilayaRequired;

  /// No description provided for @baladiyaMunicipality.
  ///
  /// In en, this message translates to:
  /// **'Baladiya (Municipality)'**
  String get baladiyaMunicipality;

  /// No description provided for @streetAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Street Address (Optional)'**
  String get streetAddressOptional;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @areYouSureDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is irreversible and all your posts will be deleted.'**
  String get areYouSureDeleteAccount;

  /// No description provided for @yesDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete Account'**
  String get yesDeleteAccount;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cleaner.
  ///
  /// In en, this message translates to:
  /// **'Cleaner'**
  String get cleaner;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @agencyProfileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Agency profile coming soon'**
  String get agencyProfileComingSoon;

  /// No description provided for @noPastBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No past bookings yet.'**
  String get noPastBookingsYet;

  /// No description provided for @noCleanersInTeamYet.
  ///
  /// In en, this message translates to:
  /// **'No cleaners in your team yet.'**
  String get noCleanersInTeamYet;

  /// No description provided for @errorLoadingCleanerProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading cleaner profile'**
  String get errorLoadingCleanerProfile;

  /// No description provided for @addCleaner.
  ///
  /// In en, this message translates to:
  /// **'Add Cleaner'**
  String get addCleaner;

  /// No description provided for @requiredServices.
  ///
  /// In en, this message translates to:
  /// **'Required Services'**
  String get requiredServices;

  /// No description provided for @yourBid.
  ///
  /// In en, this message translates to:
  /// **'Your Bid'**
  String get yourBid;

  /// No description provided for @yourPriceDa.
  ///
  /// In en, this message translates to:
  /// **'Your Price (DA)'**
  String get yourPriceDa;

  /// No description provided for @enterYourBidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter your bid price'**
  String get enterYourBidPrice;

  /// No description provided for @pleaseEnterBidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a bid price'**
  String get pleaseEnterBidPrice;

  /// No description provided for @pleaseEnterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get pleaseEnterValidPrice;

  /// No description provided for @messageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (Optional)'**
  String get messageOptional;

  /// No description provided for @addShortMessageToClient.
  ///
  /// In en, this message translates to:
  /// **'Add a short message to the client...'**
  String get addShortMessageToClient;

  /// No description provided for @estimatedHoursFormat.
  ///
  /// In en, this message translates to:
  /// **'Est. {hours} hours'**
  String estimatedHoursFormat(int hours);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get noReviewsYet;

  /// No description provided for @bid.
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get bid;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @partOf.
  ///
  /// In en, this message translates to:
  /// **'Part of'**
  String get partOf;

  /// No description provided for @allReviews.
  ///
  /// In en, this message translates to:
  /// **'All Reviews'**
  String get allReviews;

  /// No description provided for @cleaningHistory.
  ///
  /// In en, this message translates to:
  /// **'Cleaning History'**
  String get cleaningHistory;

  /// No description provided for @noCleaningHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cleaning history available'**
  String get noCleaningHistoryAvailable;

  /// No description provided for @cleanerIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cleaner ID not found'**
  String get cleanerIdNotFound;

  /// No description provided for @cleaningJob.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Job'**
  String get cleaningJob;

  /// No description provided for @activePosts.
  ///
  /// In en, this message translates to:
  /// **'Active Posts'**
  String get activePosts;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPostsYet;

  /// No description provided for @noActivePosts.
  ///
  /// In en, this message translates to:
  /// **'No active posts.'**
  String get noActivePosts;

  /// No description provided for @myPostsOnlyForClients.
  ///
  /// In en, this message translates to:
  /// **'My Posts is only available for clients.'**
  String get myPostsOnlyForClients;

  /// No description provided for @activePostsOnlyForClients.
  ///
  /// In en, this message translates to:
  /// **'Active Posts is only available for clients.'**
  String get activePostsOnlyForClients;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Reviews'**
  String reviewsCount(int count);

  /// No description provided for @cleanSpaceFeatures.
  ///
  /// In en, this message translates to:
  /// **'CleanSpace Features'**
  String get cleanSpaceFeatures;

  /// No description provided for @everythingYouNeed.
  ///
  /// In en, this message translates to:
  /// **'Everything you need in one app'**
  String get everythingYouNeed;

  /// No description provided for @findVerifiedCleaners.
  ///
  /// In en, this message translates to:
  /// **'Find Verified Cleaners'**
  String get findVerifiedCleaners;

  /// No description provided for @browseTrustedProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Browse trusted professionals with verified profiles and ratings'**
  String get browseTrustedProfessionals;

  /// No description provided for @easyBooking.
  ///
  /// In en, this message translates to:
  /// **'Easy Booking'**
  String get easyBooking;

  /// No description provided for @postYourJob.
  ///
  /// In en, this message translates to:
  /// **'Post your job and receive offers from qualified cleaners'**
  String get postYourJob;

  /// No description provided for @jobOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Job Opportunities'**
  String get jobOpportunities;

  /// No description provided for @findStableWork.
  ///
  /// In en, this message translates to:
  /// **'Find stable work and grow your cleaning business'**
  String get findStableWork;

  /// No description provided for @cleaspaceExperience.
  ///
  /// In en, this message translates to:
  /// **'CLEASPACE EXPERIENCE'**
  String get cleaspaceExperience;

  /// No description provided for @allInOnePlatform.
  ///
  /// In en, this message translates to:
  /// **'All-in-one platform for trusted cleaning services.'**
  String get allInOnePlatform;

  /// No description provided for @verifiedProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Verified Professionals'**
  String get verifiedProfessionals;

  /// No description provided for @everyCleanerPasses.
  ///
  /// In en, this message translates to:
  /// **'Every cleaner and agency passes identity and quality checks for full trust.'**
  String get everyCleanerPasses;

  /// No description provided for @smartMatching.
  ///
  /// In en, this message translates to:
  /// **'Smart Matching'**
  String get smartMatching;

  /// No description provided for @browseCuratedLists.
  ///
  /// In en, this message translates to:
  /// **'Browse curated lists or let CleanSpace suggest best-fit cleaners.'**
  String get browseCuratedLists;

  /// No description provided for @transparentPricing.
  ///
  /// In en, this message translates to:
  /// **'Transparent Pricing'**
  String get transparentPricing;

  /// No description provided for @seeClearHourlyRates.
  ///
  /// In en, this message translates to:
  /// **'See clear hourly rates before booking. No hidden surprises.'**
  String get seeClearHourlyRates;

  /// No description provided for @cleaspaceAlgeria.
  ///
  /// In en, this message translates to:
  /// **'CLEASPACE ALGERIA'**
  String get cleaspaceAlgeria;

  /// No description provided for @readyToLaunch.
  ///
  /// In en, this message translates to:
  /// **'Ready to launch your next clean space?'**
  String get readyToLaunch;

  /// No description provided for @createAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account to book trusted cleaners, manage agencies, or offer your cleaning services to Algeria\'s growing market.'**
  String get createAccountDescription;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skipToLogin.
  ///
  /// In en, this message translates to:
  /// **'Skip to login'**
  String get skipToLogin;

  /// No description provided for @iAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get iAlreadyHaveAccount;

  /// No description provided for @createAccountPage.
  ///
  /// In en, this message translates to:
  /// **'Create Account Page'**
  String get createAccountPage;

  /// No description provided for @uploadProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Picture'**
  String get uploadProfilePicture;

  /// No description provided for @uploadAClearPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo'**
  String get uploadAClearPhoto;

  /// No description provided for @photoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get photoSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
