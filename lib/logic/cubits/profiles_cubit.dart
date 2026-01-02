import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profiles/profile_repo.dart';


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

  ProfilesCubit() : super(ProfilesInitial()) {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    emit(ProfilesLoading());
    try {
      final user = await _repo.getCurrentUser();
      emit(ProfilesLoaded(user));
    } catch (e) {
      emit(ProfilesError('Failed to load user: $e'));
    }
  }

  Future<void> login(String username, String password) async {
    emit(ProfilesLoading());
    try {
      if (username.isEmpty || password.isEmpty) {
        emit(ProfilesError('Please enter both username and password'));
        return;
      }

      final user = await _repo.login(username, password);
      if (user != null) {
        emit(LoginSuccess(user));
        emit(ProfilesLoaded(user));
      } else {
        emit(ProfilesError('Incorrect username or password, try again'));
      }
    } catch (e) {
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
      final success = await _repo.updateProfile(id, profileData);
      if (success) {
        
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
}

