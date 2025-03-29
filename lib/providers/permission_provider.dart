import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:logging/logging.dart';

final _log = Logger('PermissionProvider');

class PermissionNotifier extends StateNotifier<Set<String>> {
  PermissionNotifier() : super({});

  void setPermissionsFromUser(List<String> permissions) {
    state = Set<String>.from(permissions);
    _log.fine('Permissions set: $state');
  }

  bool hasPermission(String permission) {
    return state.contains(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => state.contains(permission));
  }

  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => state.contains(permission));
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, Set<String>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  final permissionNotifier = PermissionNotifier();

  if (user != null) {
    _log.info(
        'Setting permissions for user ${user.email} with role ${user.role}');
    
    // Default permissions based on user role
    List<String> rolePermissions = [];
    
    // Ensure admin always has user management permissions
    if (user.role == AppConstants.roleAdmin) {
      _log.info('Setting admin permissions');
      rolePermissions = [
        AppConstants.permissionCreateUser,
        AppConstants.permissionReadUser,
        AppConstants.permissionUpdateUser,
        AppConstants.permissionDeleteUser,
      ];
    } else if (user.role == AppConstants.roleManager) {
      rolePermissions = [
        AppConstants.permissionCreateProject,
        AppConstants.permissionReadProject,
        AppConstants.permissionUpdateProject,
        AppConstants.permissionDeleteProject,
        AppConstants.permissionCreateTask,
        AppConstants.permissionReadTask,
        AppConstants.permissionUpdateTask,
        AppConstants.permissionDeleteTask,
        AppConstants.permissionChangeTaskStatus,
        AppConstants.permissionCreateRoutine,
        AppConstants.permissionReadRoutine,
        AppConstants.permissionUpdateRoutine,
        AppConstants.permissionDeleteRoutine,
        AppConstants.permissionChangeRoutineStatus,
        AppConstants.permissionViewReports,
      ];
    } else if (user.role == AppConstants.roleEmployee) {
      rolePermissions = [
        AppConstants.permissionReadProject,
        AppConstants.permissionReadTask,
        AppConstants.permissionChangeTaskStatus,
        AppConstants.permissionReadRoutine,
        AppConstants.permissionChangeRoutineStatus,
      ];
    } else if (user.role == AppConstants.roleExecutive) {
      rolePermissions = [
        AppConstants.permissionViewReports,
      ];
    }
    
    // If user has specific permissions, use those instead
    if (user.permissions.isNotEmpty) {
      permissionNotifier.setPermissionsFromUser(user.permissions);
    } else {
      permissionNotifier.setPermissionsFromUser(rolePermissions);
    }
    
    _log.info('Permissions set: ${permissionNotifier.state}');
  } else {
    _log.info('No user found, setting empty permissions');
    permissionNotifier.setPermissionsFromUser([]);
  }

  return permissionNotifier;
});

// Convenience providers for common permission checks
final canManageUsersProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateUser) ||
         permissions.contains(AppConstants.permissionUpdateUser) ||
         permissions.contains(AppConstants.permissionDeleteUser);
});

final canViewReportsProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionViewReports);
});

final canManageProjectsProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateProject) ||
      permissions.contains(AppConstants.permissionUpdateProject) ||
      permissions.contains(AppConstants.permissionDeleteProject);
});

final canManageRoutinesProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateRoutine) ||
      permissions.contains(AppConstants.permissionUpdateRoutine) ||
      permissions.contains(AppConstants.permissionDeleteRoutine);
});

final canManageTasksProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateTask) ||
      permissions.contains(AppConstants.permissionUpdateTask) ||
      permissions.contains(AppConstants.permissionDeleteTask);
});
