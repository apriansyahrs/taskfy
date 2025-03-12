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
      final authResponse = await _supabase.auth.admin.createUser(
        supabase.AdminUserAttributes(
          email: user.email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in Auth');
      }

      List<String> permissions = user.permissions.isNotEmpty
          ? user.permissions
          : _getDefaultPermissions(user.role);

      final newUser = user.copyWith(
        id: authResponse.user!.id,
        permissions: permissions,
        isActive: true,
      );

      // Only insert fields that exist in the database schema
      await _supabase.from('users').insert({
        'id': newUser.id,
        'email': newUser.email,
        'role': newUser.role,
      });

      state = AsyncValue.data([...state.value ?? [], newUser]);
      _log.info(
          'User created successfully: ${newUser.email} with role: ${newUser.role}');
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
      _log.info('Attempting to update user role to: ${user.role}');

      // Update both role and permissions in the database
      await _supabase.from('users').update({
        'role': user.role,
      }).eq('id', user.id);

      // Fetch the updated user data
      final updatedUserData =
          await _supabase.from('users').select().eq('id', user.id).single();
      _log.info('Fetched updated user data: $updatedUserData');

      // Create updated user with permissions calculated from role
      final updatedUser = taskfy_user.User.fromJson({
        ...updatedUserData,
        'role': user.role,
      });

      _log.info(
          'Updated user role: ${updatedUser.role} with permissions: ${updatedUser.permissions}');

      // Update state with the new user data
      state = AsyncValue.data(
          state.value?.map((u) => u.id == user.id ? updatedUser : u).toList() ??
              []);

      _log.info(
          'User role updated successfully for user ID: ${user.id}. New role: ${updatedUser.role}');
      return true;
    } catch (e) {
      _log.warning('Error updating user role: $e');
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

  List<String> _getDefaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return ['view_reports'];
      case 'manager':
        return [
          'create_project',
          'update_project',
          'delete_project',
          'create_routine',
          'update_routine',
          'delete_routine',
          'view_reports',
          'monitor_progress'
        ];
      case 'pegawai':
        return [
          'view_assigned_projects',
          'view_assigned_routines',
          'update_task_status',
          'update_routine_status'
        ];
      case 'direksi':
        return ['view_reports'];
      default:
        return [];
    }
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<List<taskfy_user.User>>>(
        (ref) {
  return UserNotifier();
});
