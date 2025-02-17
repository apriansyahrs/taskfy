import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthService');

class AuthService {
  final supabase.SupabaseClient _supabase = supabaseClient.client;

  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.asyncMap((event) async {
    final session = event.session;
    return session != null ? await _getUserFromSession(session) : null;
  });

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

  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    return session != null ? await _getUserFromSession(session) : null;
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null ? await _getUserFromSession(response.session!) : null;
    } catch (e) {
      _log.warning('Error signing in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

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
        return await _getUserFromSession(response.session!);
      }
      return null;
    } catch (e) {
      _log.warning('Error signing up: $e');
      return null;
    }
  }

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

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      _log.warning('Error resetting password: $e');
      throw e;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges;
});

