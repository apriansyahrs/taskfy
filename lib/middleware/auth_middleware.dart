import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:logging/logging.dart';
import 'package:taskfy/state/app_state.dart';

final _log = Logger('AuthMiddleware');

class AuthMiddleware extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  
  const AuthMiddleware({
    super.key, 
    required this.allowedRoles, 
    required this.child
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if auth is still initializing/loading
    final isLoading = ref.watch(authLoadingProvider);
    
    // Don't redirect if still loading
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final userState = ref.watch(currentUserProvider);
    
    return userState.when(
      data: (user) {
        // User is logged in but doesn't have the required role
        if (user != null && !allowedRoles.contains(user.role)) {
          // Use a better approach than navigation - show unauthorized screen
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Unauthorized Access',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('You don\'t have permission to access this page.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to dashboard safely
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // User has permission or is not logged in (will be handled by router)
        return child;
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
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

