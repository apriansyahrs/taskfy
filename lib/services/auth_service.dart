import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/supabase_client.dart';

final _log = Logger('AuthService');

/// Service responsible for handling authentication-related operations.
class AuthService {
  final SupabaseClientWrapper _supabaseClientWrapper;

  AuthService(this._supabaseClientWrapper);

  supabase.SupabaseClient get _supabase => _supabaseClientWrapper.client;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.asyncMap((event) async {
    final session = event.session;
    return session != null ? await _getUserFromSession(session) : null;
  });

  /// Retrieves the user data from a given session.
  Future<User?> _getUserFromSession(supabase.Session session) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .single();
      return User(
        id: session.user.id,
        email: session.user.email!,
        role: userData['role'] as String,
      );
    } catch (e) {
      _log.warning('Error getting user data: $e');
      return null;
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
      return response.user != null ? await _getUserFromSession(response.session!) : null;
    } catch (e) {
      _log.warning('Error signing in: $e');
      return null;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _log.info('User signed out');
    } catch (e) {
      _log.warning('Error signing out: $e');
      rethrow;
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
        });
        _log.info('New user signed up: $email with role: $role');
        return await _getUserFromSession(response.session!);
      }
      return null;
    } catch (e) {
      _log.warning('Error signing up: $e');
      return null;
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
    } catch (e) {
      _log.warning('Error getting user role: $e');
      return null;
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
    } catch (e) {
      _log.warning('Error resetting password: $e');
      throw e;
    }
  }

  /// Updates the role of a user.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
      _log.info('User role updated: $userId to $newRole');
    } catch (e) {
      _log.warning('Error updating user role: $e');
      throw e;
    }
  }

  /// Updates the user's password during the reset process.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      _log.info('Password updated successfully');
    } catch (e) {
      _log.warning('Error updating password: $e');
      throw e;
    }
  }
}

/// Provider for the AuthService.
final authServiceProvider = Provider<AuthService>((ref) => AuthService(SupabaseClientWrapper()));

