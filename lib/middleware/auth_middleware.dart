import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthMiddleware');

class AuthMiddleware extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;
  final List<String> requiredPermissions;

  const AuthMiddleware({
    super.key,
    required this.child,
    this.allowedRoles = const [],
    this.requiredPermissions = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final permissions = ref.watch(permissionProvider);

    if (user == null) {
      _log.info('User not authenticated, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    // Check role-based access if allowedRoles is provided
    if (allowedRoles.isNotEmpty && !allowedRoles.contains(user.role)) {
      _log.info('User role ${user.role} not allowed, redirecting to dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }

    // Check permission-based access if requiredPermissions is provided
    if (requiredPermissions.isNotEmpty && 
        !requiredPermissions.every((permission) => permissions.contains(permission))) {
      _log.info('User lacks required permissions, redirecting to dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

// Permission-based middleware for simpler usage
class PermissionMiddleware extends ConsumerWidget {
  final Widget child;
  final List<String> requiredPermissions;
  final bool requireAll;

  const PermissionMiddleware({
    super.key,
    required this.child,
    required this.requiredPermissions,
    this.requireAll = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final hasAccess = requireAll
        ? requiredPermissions.every((permission) => permissions.contains(permission))
        : requiredPermissions.any((permission) => permissions.contains(permission));

    if (!hasAccess) {
      _log.info('User lacks required permissions, redirecting to dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

