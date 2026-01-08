

class AppRoutes {
  
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  
  static const String clientHome = '/client-home';
  static const String search = '/search';
  static const String clientProfile = '/client-profile';
  static const String clientBookings = '/client-bookings';
  
  
  static const String agencyDashboard = '/agency-dashboard';
  static const String addJob = '/add-job';
  static const String editJob = '/edit-job';
  static const String jobDetails = '/job-details';
  
  
  static const String cleanerProfile = '/cleaner-profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String manageJob = '/manage-job';
  
  
  static String? getRouteName(String path) {
    final routes = {
      onboarding: onboarding,
      login: login,
      signup: signup,
      forgotPassword: forgotPassword,
      clientHome: clientHome,
      search: search,
      clientProfile: clientProfile,
      clientBookings: clientBookings,
      agencyDashboard: agencyDashboard,
      addJob: addJob,
      editJob: editJob,
      jobDetails: jobDetails,
      cleanerProfile: cleanerProfile,
      editProfile: editProfile,
      settings: settings,
      manageJob: manageJob,
    };
    return routes[path];
  }
}


