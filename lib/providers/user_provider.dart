import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('UserNotifier');

final usersStreamProvider = StreamProvider<List<taskfy_user.User>>((ref) {
  return getIt<SupabaseClientWrapper>()
      .client
      .from('users')
      .stream(primaryKey: ['id']).map((data) =>
          data.map((json) => taskfy_user.User.fromJson(json)).toList());
});

final userProvider =
    StreamProvider.family<taskfy_user.User?, String>((ref, userId) {
  return getIt<SupabaseClientWrapper>()
      .client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) =>
          data.isNotEmpty ? taskfy_user.User.fromJson(data.first) : null);
});

class UserNotifier extends StateNotifier<AsyncValue<List<taskfy_user.User>>> {
  UserNotifier() : super(const AsyncValue.loading());

  final supabase.SupabaseClient _supabase =
      getIt<SupabaseClientWrapper>().client;

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

  Future<bool> updateUser(taskfy_user.User user) async {
    try {
      print('UserNotifier: Attempting to update user role to: ${user.role}');

      // Update only the role in the 'users' table
      final response = await _supabase.from('users').update({
        'role': user.role,
      }).eq('id', user.id);

      print('UserNotifier: Database update response: $response');

      // Fetch the updated user data
      final updatedUserData =
          await _supabase.from('users').select().eq('id', user.id).single();
      print('UserNotifier: Fetched updated user data: $updatedUserData');

      if (updatedUserData != null) {
        final updatedUser = taskfy_user.User.fromJson(updatedUserData);
        print(
            'UserNotifier: Verifying updated role - New role from database: ${updatedUser.role}');
        state = AsyncValue.data(state.value
                ?.map((u) => u.id == user.id ? updatedUser : u)
                .toList() ??
            []);
        _log.info(
            'User role updated successfully for user ID: ${user.id}. New role: ${updatedUser.role}');
        return true;
      } else {
        throw Exception('Failed to fetch updated user data');
      }
    } catch (e) {
      _log.warning('Error updating user role: $e');
      print('UserNotifier: Error updating user role: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      _log.info('User deleted from users table: $userId');

      try {
        await _supabase.auth.admin.deleteUser(userId);
        _log.info('User deleted from auth system: $userId');
      } catch (authError) {
        _log.warning('Failed to delete user from auth system: $authError');
        _log.warning('Proceeding to delete user data from database only.');
      }

      state = AsyncValue.data(
          state.value?.where((user) => user.id != userId).toList() ?? []);
      _log.info('User deleted successfully: $userId');
    } catch (e) {
      _log.warning('Failed to delete user: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<List<taskfy_user.User>>>(
        (ref) {
  return UserNotifier();
});
