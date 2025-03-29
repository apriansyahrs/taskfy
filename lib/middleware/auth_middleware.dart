import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthMiddleware');

class AuthMiddleware extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;
  final List<String> requiredPermissions;
  final bool requireAll;

  const AuthMiddleware({
    super.key,
    required this.child,
    this.allowedRoles = const [],
    this.requiredPermissions = const [],
    this.requireAll = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);

    // Show loading indicator while checking auth state
    if (authStateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Handle authentication errors
    if (authStateAsync.hasError) {
      _log.severe('Auth state error: ${authStateAsync.error}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }
    
    final user = authStateAsync.value;

    // Check if user is authenticated
    if (user == null) {
      _log.info('User not authenticated, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Save the current path to redirect back after login
        final currentPath = GoRouterState.of(context).uri.toString();
        if (currentPath != '/') {
          // Could store this path in shared preferences to redirect after login
          _log.info('Saved path for redirect: $currentPath');
        }
        context.go('/');
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    // At this point, we know the user is authenticated
    
    // Check role-based access if allowedRoles is provided
    if (allowedRoles.isNotEmpty && !allowedRoles.contains(user.role)) {
      _log.warning('User role ${user.role} not allowed, redirecting to dashboard. Allowed roles: $allowedRoles');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const Center(child: CircularProgressIndicator());
    }

    // Check permission-based access
    if (requiredPermissions.isNotEmpty) {
      final permissions = ref.watch(permissionProvider);
      final hasPermission = requireAll 
          ? requiredPermissions.every((permission) => permissions.contains(permission))
          : requiredPermissions.any((permission) => permissions.contains(permission));
      
      if (!hasPermission) {
        _log.warning('User lacks required permissions: $requiredPermissions. User has: $permissions');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/dashboard');
        });
        return const Center(child: CircularProgressIndicator());
      }
    }

    // All checks passed, render the protected content
    return child;
  }
}

// Permission-specific middleware for different user actions
class UserManagementMiddleware extends ConsumerWidget {
  final Widget child;
  
  const UserManagementMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionCreateUser,
        AppConstants.permissionReadUser,
        AppConstants.permissionUpdateUser,
        AppConstants.permissionDeleteUser,
      ],
      requireAll: false, // At least one of these permissions
      child: child,
    );
  }
}

class ProjectManagementMiddleware extends ConsumerWidget {
  final Widget child;
  
  const ProjectManagementMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionCreateProject,
        AppConstants.permissionReadProject,
        AppConstants.permissionUpdateProject,
        AppConstants.permissionDeleteProject,
      ],
      requireAll: false, // At least one of these permissions
      child: child,
    );
  }
}

class ProjectViewMiddleware extends ConsumerWidget {
  final Widget child;
  
  const ProjectViewMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionReadProject,
      ],
      child: child,
    );
  }
}

class RoutineManagementMiddleware extends ConsumerWidget {
  final Widget child;
  
  const RoutineManagementMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionCreateRoutine,
        AppConstants.permissionReadRoutine,
        AppConstants.permissionUpdateRoutine,
        AppConstants.permissionDeleteRoutine,
      ],
      requireAll: false, // At least one of these permissions
      child: child,
    );
  }
}

class RoutineViewMiddleware extends ConsumerWidget {
  final Widget child;
  
  const RoutineViewMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionReadRoutine,
      ],
      child: child,
    );
  }
}

class ReportsMiddleware extends ConsumerWidget {
  final Widget child;
  
  const ReportsMiddleware({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthMiddleware(
      requiredPermissions: [
        AppConstants.permissionViewReports,
      ],
      child: child,
    );
  }
}

