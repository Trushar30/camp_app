/// Authentication Service for CampusEase
/// Handles login, signup, and session management with Supabase
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get current user session
  Session? get currentSession => _client.auth.currentSession;
  
  // Check if user is logged in
  bool get isLoggedIn => currentSession != null;

  // Determine user role from ID
  String? getRoleFromId(String userId) {
    if (AppConstants.studentIdPattern.hasMatch(userId)) {
      return AppConstants.roleStudent;
    } else if (AppConstants.facultyIdPattern.hasMatch(userId)) {
      return AppConstants.roleFaculty;
    } else if (AppConstants.adminIdPattern.hasMatch(userId)) {
      return AppConstants.roleAdmin;
    }
    return null;
  }

  // Login for Student
  Future<AuthResult> loginStudent(String userId, String password) async {
    try {
      // Fetch student record
      final studentRecord = await _client
          .from('student_records')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (studentRecord == null) {
        return AuthResult.error('Student ID not found. Please contact admin.');
      }

      final email = studentRecord['email'] ?? AppConstants.studentEmail(userId);
      final defaultPassword = AppConstants.generateDefaultPassword(userId);
      final isDefaultPassword = password == defaultPassword;

      if (isDefaultPassword) {
        // Try login with default password
        final authResponse = await _client.auth.signInWithPassword(
          email: email,
          password: defaultPassword,
        );

        if (authResponse.user == null) {
          // Account doesn't exist, create it
          if (studentRecord['auth_id'] != null) {
            return AuthResult.error('Password has been changed. Use your new password.');
          }

          final signUpResponse = await _client.auth.signUp(
            email: email,
            password: defaultPassword,
          );

          if (signUpResponse.user != null) {
            // Update student record with auth_id
            await _client
                .from('student_records')
                .update({
                  'auth_id': signUpResponse.user!.id,
                  'account_activated': false,
                  'email_verified': true,
                })
                .eq('user_id', userId);
          }
        }
      } else {
        // Regular login with custom password
        final authResponse = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.user == null) {
          final isActivated = studentRecord['account_activated'] ?? false;
          if (!isActivated) {
            return AuthResult.error(
              'Incorrect password. Try default: $defaultPassword',
            );
          }
          return AuthResult.error('Invalid password.');
        }

        // Mark as activated if using custom password
        if (!(studentRecord['account_activated'] ?? false)) {
          await _client
              .from('student_records')
              .update({'account_activated': true})
              .eq('user_id', userId);
        }
      }

      final user = UserModel.fromJson({
        ...studentRecord,
        'role': AppConstants.roleStudent,
      });

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  // Login for Faculty
  Future<AuthResult> loginFaculty(String userId, String password) async {
    try {
      final facultyRecord = await _client
          .from('faculty')
          .select()
          .ilike('user_id', userId)
          .maybeSingle();

      if (facultyRecord == null) {
        return AuthResult.error('Faculty ID not found.');
      }

      final email = facultyRecord['email'];

      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult.error('Invalid credentials.');
      }

      final user = UserModel.fromJson({
        ...facultyRecord,
        'role': AppConstants.roleFaculty,
      });

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  // Unified login method
  Future<AuthResult> login(String userId, String password) async {
    final role = getRoleFromId(userId);

    if (role == null) {
      return AuthResult.error('Invalid ID format.');
    }

    if (role == AppConstants.roleAdmin) {
      return AuthResult.error('Admin login is only available on web.');
    }

    if (role == AppConstants.roleStudent) {
      return loginStudent(userId, password);
    }

    if (role == AppConstants.roleFaculty) {
      return loginFaculty(userId, password);
    }

    return AuthResult.error('Invalid role.');
  }

  // Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = currentSession;
      if (session == null) return null;

      final authUser = session.user;
      final email = authUser.email;

      // Try student_records first
      var userData = await _client
          .from('student_records')
          .select()
          .eq('email', email ?? '')
          .maybeSingle();

      if (userData != null) {
        return UserModel.fromJson({...userData, 'role': AppConstants.roleStudent});
      }

      // Try faculty
      userData = await _client
          .from('faculty')
          .select()
          .eq('email', email ?? '')
          .maybeSingle();

      if (userData != null) {
        return UserModel.fromJson({...userData, 'role': AppConstants.roleFaculty});
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

// Result class for auth operations
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
  });

  factory AuthResult.success(UserModel user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(success: false, error: message);
  }
}
