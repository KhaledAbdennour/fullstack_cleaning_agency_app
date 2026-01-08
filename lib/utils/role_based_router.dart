import 'package:flutter/material.dart';
import '../screens/homescreen.dart';
import '../screens/agency_dashboard_page.dart';



class RoleBasedRouter {
  
  
  
  
  
  
  static Widget getHomeScreenForUser(Map<String, dynamic>? user) {
    if (user == null) {
      return const HomeScreen();
    }

    final userType = (user['user_type'] as String? ?? '').trim();
    
    
    if (userType == 'Agency' || userType == 'Individual Cleaner') {
      return const AgencyDashboardPage();
    }
    
    
    return const HomeScreen();
  }

  
  static bool isAgency(Map<String, dynamic>? user) {
    if (user == null) return false;
    final userType = (user['user_type'] as String? ?? '').trim();
    return userType == 'Agency';
  }

  
  static bool isIndividualCleaner(Map<String, dynamic>? user) {
    if (user == null) return false;
    final userType = (user['user_type'] as String? ?? '').trim();
    return userType == 'Individual Cleaner';
  }

  
  static bool isClient(Map<String, dynamic>? user) {
    if (user == null) return false;
    final userType = (user['user_type'] as String? ?? '').trim();
    return userType == 'Client' || (!isAgency(user) && !isIndividualCleaner(user));
  }

  
  static String normalizeUserType(String? userType) {
    if (userType == null) return 'Client';
    final normalized = userType.trim();
    
    if (normalized.toLowerCase() == 'agency') return 'Agency';
    if (normalized.toLowerCase() == 'individual cleaner' || 
        normalized.toLowerCase() == 'cleaner' ||
        normalized.toLowerCase() == 'individual_cleaner') {
      return 'Individual Cleaner';
    }
    if (normalized.toLowerCase() == 'client') return 'Client';
    return normalized; 
  }
}

