import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/providers/auth_provider.dart';

class PermissionNotifier extends StateNotifier<Set<String>> {
  PermissionNotifier() : super({});

  void setPermissions(String role) {
    switch (role) {
      case 'admin':
        state = {
          'manage_users',
          'create_project',
          'edit_project',
          'delete_project',
          'create_task',
          'edit_task',
          'delete_task',
          'view_reports',
        };
        break;
      case 'manager':
        state = {
          'create_project',
          'edit_project',
          'delete_project',
          'create_task',
          'edit_task',
          'delete_task',
          'view_reports',
        };
        break;
      case 'pegawai':
        state = {
          'update_task_status',
          'update_project_status',
        };
        break;
      case 'direksi':
        state = {'view_reports'};
        break;
      default:
        state = {};
    }
  }

  bool hasPermission(String permission) {
    return state.contains(permission);
  }
}

final permissionProvider = StateNotifierProvider<PermissionNotifier, Set<String>>((ref) {
  final authState = ref.watch(authProvider);
  final permissionNotifier = PermissionNotifier();

  if (authState != null) {
    permissionNotifier.setPermissions(authState.role);
  } else {
    permissionNotifier.setPermissions('');
  }

  return permissionNotifier;
});

