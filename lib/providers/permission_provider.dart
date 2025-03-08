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

  if (user != null && user.permissions.isNotEmpty) {
    _log.info(
        'Setting permissions for user ${user.email} with role ${user.role}');
    permissionNotifier.setPermissionsFromUser(user.permissions);
  } else {
    _log.info('No user or permissions found, setting empty permissions');
    permissionNotifier.setPermissionsFromUser([]);
  }

  return permissionNotifier;
});

// Convenience providers for common permission checks
final canManageUsersProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionManageUsers);
});

final canViewReportsProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionViewReports);
});

final canManageProjectsProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateProject) ||
      permissions.contains(AppConstants.permissionEditProject) ||
      permissions.contains(AppConstants.permissionDeleteProject);
});

final canManageRoutinesProvider = Provider<bool>((ref) {
  final permissions = ref.watch(permissionProvider);
  return permissions.contains(AppConstants.permissionCreateRoutine) ||
      permissions.contains(AppConstants.permissionEditRoutine) ||
      permissions.contains(AppConstants.permissionDeleteRoutine);
});
