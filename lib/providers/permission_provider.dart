import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';

class PermissionNotifier extends StateNotifier<Set<String>> {
  PermissionNotifier() : super({});

  void setPermissions(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        state = {
          AppConstants.permissionManageUsers,
          AppConstants.permissionViewReports,
          AppConstants.permissionCreateProject,
          AppConstants.permissionEditProject,
          AppConstants.permissionDeleteProject,
          AppConstants.permissionCreateTask,
          AppConstants.permissionEditTask,
          AppConstants.permissionDeleteTask,
        };
        break;
      case AppConstants.roleManager:
        state = {
          AppConstants.permissionCreateProject,
          AppConstants.permissionEditProject,
          AppConstants.permissionDeleteProject,
          AppConstants.permissionCreateTask,
          AppConstants.permissionEditTask,
          AppConstants.permissionDeleteTask,
          AppConstants.permissionViewReports,
        };
        break;
      case AppConstants.roleEmployee:
        state = {
          AppConstants.permissionUpdateTaskStatus,
          AppConstants.permissionUpdateProjectStatus,
        };
        break;
      case AppConstants.roleExecutive:
        state = {AppConstants.permissionViewReports};
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

