import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('UserNotifier');

final usersStreamProvider = StreamProvider<List<taskfy_user.User>>((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => taskfy_user.User.fromJson(json)).toList());
});

final userProvider = StreamProvider.family<taskfy_user.User?, String>((ref, userId) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) => data.isNotEmpty ? taskfy_user.User.fromJson(data.first) : null);
});

class UserNotifier extends StateNotifier<AsyncValue<List<taskfy_user.User>>> {
  UserNotifier() : super(const AsyncValue.loading());

  final supabase.SupabaseClient _supabase = getIt<SupabaseClientWrapper>().client;

  Future<void> createUser(taskfy_user.User user, String password) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in Auth');
      }

      final newUser = user.copyWith(id: authResponse.user!.id);

      await _supabase.from('users').insert(newUser.toJson());

      state = AsyncValue.data([...state.value ?? [], newUser]);
      _log.info('User created successfully: ${newUser.email}');
    } catch (e) {
      if (e is supabase.AuthException) {
        _log.warning('Auth error creating user: ${e.message}');
        throw Exception('Authentication error: ${e.message}');
      } else if (e is supabase.PostgrestException) {
        _log.warning('Database error creating user: ${e.message}');
        throw Exception('Database error: ${e.message}');
      } else {
        _log.warning('Unknown error creating user: $e');
        throw Exception('An unexpected error occurred');
      }
    }
  }

  Future<void> updateUser(taskfy_user.User user) async {
    try {
      // Update user data in the 'users' table
      await _supabase.from('users').update({
        'email': user.email,
        'role': user.role,
      }).eq('id', user.id);

      // Update user email in Auth if it has changed
      final currentUser = await _supabase.auth.getUser();
      if (currentUser.user?.email != user.email) {
        await _supabase.auth.updateUser(supabase.UserAttributes(
          email: user.email,
        ));
      }

      state = AsyncValue.data(state.value?.map((u) => u.id == user.id ? user : u).toList() ?? []);
      _log.info('User updated successfully: ${user.email}');
    } catch (e) {
      if (e is supabase.AuthException) {
        _log.warning('Auth error updating user: ${e.message}');
        throw Exception('Authentication error: ${e.message}');
      } else if (e is supabase.PostgrestException) {
        _log.warning('Database error updating user: ${e.message}');
        throw Exception('Database error: ${e.message}');
      } else {
        _log.warning('Unknown error updating user: $e');
        throw Exception('An unexpected error occurred');
      }
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Only delete the user from the 'users' table
      await _supabase.from('users').delete().eq('id', userId);
      state = AsyncValue.data(state.value?.where((user) => user.id != userId).toList() ?? []);
      _log.info('User deleted successfully: $userId');
    } catch (e) {
      _log.warning('Failed to delete user: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<List<taskfy_user.User>>>((ref) {
  return UserNotifier();
});

