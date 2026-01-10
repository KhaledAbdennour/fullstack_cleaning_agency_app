import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profiles/profile_repo.dart';
import '../../data/repositories/jobs/jobs_repo.dart';
import '../../core/debug/debug_logger.dart';


abstract class ProfilesState {}

class ProfilesInitial extends ProfilesState {}

class ProfilesLoading extends ProfilesState {}

class ProfilesLoaded extends ProfilesState {
  final Map<String, dynamic>? currentUser;
  ProfilesLoaded(this.currentUser);
}

class ProfilesError extends ProfilesState {
  final String message;
  ProfilesError(this.message);
}

class LoginSuccess extends ProfilesState {
  final Map<String, dynamic> user;
  LoginSuccess(this.user);
}

class SignupSuccess extends ProfilesState {
  final Map<String, dynamic> user;
  SignupSuccess(this.user);
}

class LogoutSuccess extends ProfilesState {}


class ProfilesCubit extends Cubit<ProfilesState> {
  final AbstractProfileRepo _repo = AbstractProfileRepo.getInstance();
  bool _isLoading = false;

  ProfilesCubit() : super(ProfilesInitial()) {
    // Don't auto-load - let the CheckAuthScreen handle it
    // loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) {
      return;
    }
    
    // If already loaded with the same user, don't reload
    if (state is ProfilesLoaded) {
      return;
    }
    
    _isLoading = true;
    emit(ProfilesLoading());
    try {
      final user = await _repo.getCurrentUser();
      DebugLogger.log('ProfilesCubit', 'loadCurrentUser', data: {
        'userId': user?['id'],
        'userIdType': user?['id']?.runtimeType.toString(),
        'userType': user?['user_type'],
        'storageKey': 'current_user_id',
        'source': 'SharedPreferences via ProfileRepo.getCurrentUser()',
      });
      emit(ProfilesLoaded(user));
    } catch (e, stack) {
      DebugLogger.error('ProfilesCubit', 'loadCurrentUser failed', e, stack);
      emit(ProfilesError('Failed to load user: $e'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> login(String username, String password) async {
    emit(ProfilesLoading());
    try {
      if (username.isEmpty || password.isEmpty) {
        emit(ProfilesError('Please enter both username and password'));
        return;
      }

      DebugLogger.log('ProfilesCubit', 'login START', data: {'username': username});
      final user = await _repo.login(username, password);
      if (user != null) {
        DebugLogger.log('ProfilesCubit', 'login SUCCESS', data: {
          'userId': user['id'],
          'userIdType': user['id']?.runtimeType.toString(),
          'userType': user['user_type'],
          'storageKey': 'current_user_id',
          'source': 'SharedPreferences set via ProfileRepo.login() -> setCurrentUser()',
        });
        emit(LoginSuccess(user));
        emit(ProfilesLoaded(user));
      } else {
        DebugLogger.log('ProfilesCubit', 'login FAILED', data: {'reason': 'Invalid credentials'});
        emit(ProfilesError('Incorrect username or password, try again'));
      }
    } catch (e, stack) {
      DebugLogger.error('ProfilesCubit', 'login ERROR', e, stack);
      emit(ProfilesError('Login failed: $e'));
    }
  }

  Future<void> signup(Map<String, dynamic> profileData) async {
    emit(ProfilesLoading());
    try {
      
      if (profileData['username'] == null || 
          (profileData['username'] as String).isEmpty) {
        emit(ProfilesError('Username is required'));
        return;
      }
      if (profileData['password'] == null || 
          (profileData['password'] as String).isEmpty) {
        emit(ProfilesError('Password is required'));
        return;
      }
      if (profileData['full_name'] == null || 
          (profileData['full_name'] as String).isEmpty) {
        emit(ProfilesError('Full name is required'));
        return;
      }

      
      final existingUsername = await _repo.getProfileByUsername(
        profileData['username'] as String,
      );
      if (existingUsername != null) {
        emit(ProfilesError('Username already exists'));
        return;
      }

      
      if (profileData['email'] != null && (profileData['email'] as String).isNotEmpty) {
        final existingEmail = await _repo.getProfileByEmail(
          profileData['email'] as String,
        );
        if (existingEmail != null) {
          emit(ProfilesError('Email already exists'));
          return;
        }
      }

      
      if (profileData['phone'] != null && (profileData['phone'] as String).isNotEmpty) {
        final existingPhone = await _repo.getProfileByPhone(
          profileData['phone'] as String,
        );
        if (existingPhone != null) {
          emit(ProfilesError('Phone number already exists'));
          return;
        }
      }

      
      profileData['created_at'] = DateTime.now().toIso8601String();

      final success = await _repo.insertProfile(profileData);
      if (success) {
        final user = await _repo.getProfileByUsername(
          profileData['username'] as String,
        );
        if (user != null) {
          emit(SignupSuccess(user));
          emit(ProfilesLoaded(user));
        } else {
          emit(ProfilesError('Failed to retrieve created profile'));
        }
      } else {
        emit(ProfilesError('Failed to create account'));
      }
    } catch (e) {
      emit(ProfilesError('Signup failed: $e'));
    }
  }

  Future<void> updateProfile(int id, Map<String, dynamic> profileData) async {
    emit(ProfilesLoading());
    try {
      // Get current user to compare email/phone
      final currentUser = await _repo.getCurrentUser();
      if (currentUser == null) {
        emit(ProfilesError('User not found'));
        return;
      }

      // Validate email uniqueness if email is being changed
      if (profileData['email'] != null && 
          profileData['email'] is String && 
          (profileData['email'] as String).isNotEmpty) {
        final newEmail = profileData['email'] as String;
        final currentEmail = currentUser['email'] as String?;
        
        // Only check if email is different from current email
        if (newEmail != currentEmail) {
          final existingEmail = await _repo.getProfileByEmail(newEmail);
          if (existingEmail != null && existingEmail['id'] != id) {
            emit(ProfilesError('Email already exists'));
            return;
          }
        }
      }

      // Validate phone uniqueness if phone is being changed
      if (profileData['phone'] != null && 
          profileData['phone'] is String && 
          (profileData['phone'] as String).isNotEmpty) {
        final newPhone = profileData['phone'] as String;
        final currentPhone = currentUser['phone'] as String?;
        
        // Only check if phone is different from current phone
        if (newPhone != currentPhone) {
          final existingPhone = await _repo.getProfileByPhone(newPhone);
          if (existingPhone != null && existingPhone['id'] != id) {
            emit(ProfilesError('Phone number already exists'));
            return;
          }
        }
      }

      // Filter out null values - Firestore doesn't accept null in update operations
      final filteredData = <String, dynamic>{};
      profileData.forEach((key, value) {
        if (value != null) {
          filteredData[key] = value;
        }
      });

      final success = await _repo.updateProfile(id, filteredData);
      if (success) {
        // Reload current user to get updated data
        final user = await _repo.getCurrentUser();
        emit(ProfilesLoaded(user));
      } else {
        emit(ProfilesError('Failed to update profile'));
      }
    } catch (e) {
      emit(ProfilesError('Update failed: $e'));
    }
  }

  Future<void> logout() async {
    emit(ProfilesLoading());
    try {
      await _repo.clearCurrentUser();
      emit(LogoutSuccess());
      emit(ProfilesLoaded(null));
    } catch (e) {
      emit(ProfilesError('Logout failed: $e'));
    }
  }

  Future<void> deleteAccount(int userId) async {
    emit(ProfilesLoading());
    try {
      // Mark all user's jobs as deleted
      final jobsRepo = AbstractJobsRepo.getInstance();
      await jobsRepo.markAllClientJobsAsDeleted(userId);
      
      // Delete the profile
      final success = await _repo.deleteProfile(userId);
      if (!success) {
        emit(ProfilesError('Failed to delete account'));
        return;
      }
      
      // Clear current user session
      await _repo.clearCurrentUser();
      emit(LogoutSuccess());
      emit(ProfilesLoaded(null));
    } catch (e) {
      emit(ProfilesError('Account deletion failed: $e'));
    }
  }
}

