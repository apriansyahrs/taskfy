import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'dart:async';
import 'dart:io';
import 'package:taskfy/utils/logger_util.dart';
import 'package:taskfy/providers/auth_provider.dart' as auth_provider;

final _log = Logger('AuthService');

// Define the authServiceProvider that references the one in auth_provider.dart
final authServiceProvider = auth_provider.authServiceProvider;

class AuthError {
  final String message;
  final String code;
  
  AuthError(this.code, this.message);
  
  @override
  String toString() => message;
}

/// Service responsible for handling authentication-related operations.
class AuthService {
  final SupabaseClientWrapper _supabaseClientWrapper;

  AuthService(this._supabaseClientWrapper);

  supabase.SupabaseClient get _supabase => _supabaseClientWrapper.client;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.asyncMap((event) async {
        final session = event.session;
        return session != null ? await _getUserFromSession(session) : null;
      });

  /// Retrieves the user data from a given session.
  Future<User?> _getUserFromSession(supabase.Session session) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();
      return User.fromJson({
        ...userData,
        'id': session.user.id,
        'email': session.user.email!,
        'permissions': userData['permissions'] ?? _getDefaultPermissions(userData['role'] ?? 'pegawai'),
        'is_active': userData['is_active'] ?? true,
        'last_active': DateTime.now().toIso8601String(),
      });
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during _getUserFromSession', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during _getUserFromSession', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in _getUserFromSession response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during _getUserFromSession', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Retrieves the current user.
  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    return session != null ? await _getUserFromSession(session) : null;
  }

  /// Signs in a user with email and password.
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _log.info('User signed in: $email');
      return response.user != null
          ? await _getUserFromSession(response.session!)
          : null;
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during signIn', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during signIn', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in signIn response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during signIn', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _log.info('User signed out');
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during signOut', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during signOut', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in signOut response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during signOut', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Signs up a new user.
  Future<User?> signUp(String email, String password, String role) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': role,
          'is_active': true,
          'last_active': DateTime.now().toIso8601String(),
          'permissions': _getDefaultPermissions(role),
        });
        _log.info('New user signed up: $email with role: $role');
        return await _getUserFromSession(response.session!);
      }
      return null;
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during signUp', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during signUp', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in signUp response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during signUp', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Retrieves the role of a user by their ID.
  Future<String?> getUserRole(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      return userData['role'] as String?;
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during getUserRole', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during getUserRole', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in getUserRole response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during getUserRole', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Initiates the password reset process for a given email.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );
      _log.info('Password reset email sent to: $email');
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during resetPassword', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during resetPassword', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in resetPassword response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during resetPassword', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Updates the role of a user.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
      _log.info('User role updated: $userId to $newRole');
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during updateUserRole', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during updateUserRole', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in updateUserRole response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during updateUserRole', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Updates the user's password during the reset process.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      _log.info('Password updated successfully');
    } on SocketException catch (e) {
      LoggerUtil.error('Network error during updatePassword', tag: 'AUTH', error: e);
      throw AuthError('network_error', 'Please check your internet connection.');
    } on TimeoutException catch (e) {
      LoggerUtil.error('Request timed out during updatePassword', tag: 'AUTH', error: e);
      throw AuthError('timeout', 'The request timed out. Please try again.');
    } on FormatException catch (e) {
      LoggerUtil.error('Format error in updatePassword response', tag: 'AUTH', error: e);
      throw AuthError('format_error', 'There was a problem with the server response.');
    } catch (e, stackTrace) {
      LoggerUtil.error('Unexpected error during updatePassword', tag: 'AUTH', error: e, stackTrace: stackTrace);
      throw AuthError('unknown', 'An unexpected error occurred. Please try again later.');
    }
  }

  /// Provider for the AuthService.
  List<String> _getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return [
          'create_user',
          'update_user',
          'delete_user',
          'manage_roles',
          'view_reports',
          'create_task',
          'edit_task',
          'delete_task'
        ];
      case 'manager':
        return [
          'create_project',
          'update_project',
          'delete_project',
          'create_routine',
          'update_routine',
          'delete_routine',
          'view_reports',
          'monitor_progress',
          'create_task',
          'edit_task',
          'delete_task'
        ];
      case 'pegawai':
        return [
          'view_assigned_projects',
          'view_assigned_routines',
          'update_task_status',
          'update_routine_status',
          'update_project_status',
          'create_task',
          'edit_task'
        ];
      case 'direksi':
        return [
          'view_reports'
        ];
      default:
        return [];
    }
  }
}

// Note: authServiceProvider is defined in auth_provider.dart and overridden in main.dart
