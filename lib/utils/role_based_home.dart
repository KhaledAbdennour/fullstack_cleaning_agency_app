import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/homescreen.dart';
import '../screens/agency_dashboard_page.dart';
import '../screens/welcome_inside.dart';
import '../screens/login.dart';
import '../logic/cubits/profiles_cubit.dart';










class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        
        if (state is! ProfilesLoaded || state.currentUser == null) {
          return const Login();
        }

        final user = state.currentUser!;
        final userType = (user['user_type'] as String? ?? '').trim();

        
        if (userType == 'Agency' || userType == 'Individual Cleaner') {
          return const AgencyDashboardPage();
        }

        
        
        return WelcomeInside(
          name: user['full_name'] as String? ?? 
                user['username'] as String? ?? 
                'User',
        );
      },
    );
  }

  
  
  static Widget getHomeScreenForUser(Map<String, dynamic>? user) {
    if (user == null) {
      return const Login();
    }

    final userType = (user['user_type'] as String? ?? '').trim();
    
    
    if (userType == 'Agency' || userType == 'Individual Cleaner') {
      return const AgencyDashboardPage();
    }
    
    
    return WelcomeInside(
      name: user['full_name'] as String? ?? 
            user['username'] as String? ?? 
            'User',
    );
  }

  
  
  static void navigateToHome(BuildContext context, Map<String, dynamic> user) {
    final userType = (user['user_type'] as String? ?? '').trim();
    
    if (userType == 'Agency' || userType == 'Individual Cleaner') {
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const AgencyDashboardPage(),
        ),
        (route) => false, 
      );
    } else {
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeInside(
            name: user['full_name'] as String? ?? 
                  user['username'] as String? ?? 
                  'User',
          ),
        ),
        (route) => false, 
      );
    }
  }
}


