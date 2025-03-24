import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/screens/login_screen.dart';
import 'package:taskfy/screens/forgot_password_screen.dart';
import 'package:taskfy/screens/dashboard_screen.dart';
import 'package:taskfy/screens/routine_detail_screen.dart';
import 'package:taskfy/screens/project_detail_screen.dart';
import 'package:taskfy/screens/routine_create_screen.dart';
import 'package:taskfy/screens/project_create_screen.dart';
import 'package:taskfy/screens/routine_list_screen.dart';
import 'package:taskfy/screens/project_list_screen.dart';
import 'package:taskfy/screens/routine_edit_screen.dart';
import 'package:taskfy/screens/project_edit_screen.dart';
import 'package:taskfy/screens/report_screen.dart';
import 'package:taskfy/screens/user_list_screen.dart';
import 'package:taskfy/screens/user_create_screen.dart';
import 'package:taskfy/screens/user_edit_screen.dart';
import 'package:taskfy/state/app_state.dart';
import 'package:taskfy/middleware/auth_middleware.dart';
import 'package:taskfy/screens/my_projects_screen.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/screens/reset_password_screen.dart';
import 'package:taskfy/screens/my_routines_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authLoading = ref.watch(authLoadingProvider);
  
  // Create a router notifier to observe path changes
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.dashboardRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routinesRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const RoutineListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routinesRoute}/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const RoutineCreateScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routinesRoute}/:routineId',
        pageBuilder: (context, state) {
          final routineId = state.pathParameters['routineId'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: RoutineDetailScreen(routineId: routineId ?? ''),
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.routinesRoute}/:routineId/edit',
        pageBuilder: (context, state) {
          final routineId = state.pathParameters['routineId'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: RoutineEditScreen(routineId: routineId ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppConstants.projectsRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ProjectListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.projectsRoute}/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ProjectCreateScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.projectsRoute}/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: ProjectDetailScreen(projectId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.projectsRoute}/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: ProjectEditScreen(projectId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppConstants.reportsRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ReportScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.usersRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AuthMiddleware(
            allowedRoles: [AppConstants.roleAdmin],
            child: const UserListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.usersRoute}/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AuthMiddleware(
            allowedRoles: [AppConstants.roleAdmin],
            child: const UserCreateScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.usersRoute}/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: AuthMiddleware(
              allowedRoles: [AppConstants.roleAdmin],
              child: UserEditScreen(userId: id ?? ''),
            ),
          );
        },
      ),
      GoRoute(
        path: '/my-routines',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const MyRoutinesScreen(),
        ),
      ),
      GoRoute(
        path: '/my-projects',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const MyProjectsScreen(),
        ),
      ),
    ],
    // Add observer to track navigation
    observers: [
      GoRouterObserver(ref),
    ],
    redirect: (context, state) {
      // Store current location for debugging
      final currentLocation = state.matchedLocation;
      debugPrint('Navigating to: $currentLocation, Auth loading: $authLoading');
      
      // Skip redirects during initial loading/app refresh
      if (authLoading) {
        // Try to restore from stored path if available
        final storedPath = ref.read(lastPathProvider);
        if (storedPath != null && storedPath != currentLocation) {
          debugPrint('Restoring path to: $storedPath');
          return storedPath;
        }
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/' || 
                          state.matchedLocation == '/forgot-password' || 
                          state.matchedLocation == '/reset-password';

      // Handle authentication redirects
      if (!isLoggedIn && !isAuthRoute) {
        debugPrint('Not logged in, redirecting to login');
        return '/';
      }

      if (isLoggedIn && isAuthRoute) {
        // Check if we have a stored path to restore
        final storedPath = ref.read(lastPathProvider);
        if (storedPath != null && storedPath != AppConstants.dashboardRoute) {
          debugPrint('Logged in, restoring to: $storedPath');
          return storedPath;
        }
        
        debugPrint('Logged in, redirecting to dashboard');
        return AppConstants.dashboardRoute;
      }

      // Handle permission checks
      final userRole = authState.value?.role;
      if (isLoggedIn && userRole != null) {
        // Permission checks (unchanged)
        if (state.matchedLocation.startsWith(AppConstants.usersRoute) && 
            !_hasPermission(AppConstants.permissionManageUsers, userRole)) {
          return AppConstants.dashboardRoute;
        }
        
        if (state.matchedLocation == AppConstants.reportsRoute && 
            !_hasPermission(AppConstants.permissionViewReports, userRole)) {
          return AppConstants.dashboardRoute;
        }
        
        if ((state.matchedLocation == '${AppConstants.routinesRoute}/create' || 
             state.matchedLocation == '${AppConstants.projectsRoute}/create') && 
            !_hasPermission(AppConstants.permissionCreateRoutine, userRole) && 
            !_hasPermission(AppConstants.permissionCreateProject, userRole)) {
          return AppConstants.dashboardRoute;
        }
      }

      // No redirection needed
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
  
  return router;
});

// Add router observer to track and store paths
class GoRouterObserver extends NavigatorObserver {
  final Ref ref;
  
  GoRouterObserver(this.ref);
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      _storePath(route.settings.name!);
    }
    super.didPush(route, previousRoute);
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings.name != null) {
      _storePath(newRoute!.settings.name!);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
  
  void _storePath(String path) {
    // Don't store auth routes
    if (path == '/' || path == '/forgot-password' || path == '/reset-password') {
      return;
    }
    
    // Store the path
    ref.read(lastPathProvider.notifier).state = path;
    // Also persist to local storage for recovery after refresh
    _persistPath(path);
  }
  
  Future<void> _persistPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_path', path);
    } catch (e) {
      debugPrint('Error storing path: $e');
    }
  }
}

// Use the permission provider instead of hardcoded role-based permissions
bool _hasPermission(String permission, String role) {
  switch (role) {
    case AppConstants.roleManager:
      return [
        AppConstants.permissionCreateProject,
        AppConstants.permissionEditProject,
        AppConstants.permissionDeleteProject,
        AppConstants.permissionCreateRoutine,
        AppConstants.permissionEditRoutine,
        AppConstants.permissionDeleteRoutine,
        AppConstants.permissionViewReports,
        'monitor_progress'
      ].contains(permission);
    case AppConstants.roleEmployee:
      return [
        'view_assigned_projects',
        'view_assigned_routines',
        AppConstants.permissionUpdateRoutineStatus,
        AppConstants.permissionUpdateProjectStatus
      ].contains(permission);
    case AppConstants.roleExecutive:
      return [AppConstants.permissionViewReports].contains(permission);
    case AppConstants.roleAdmin:
      return [AppConstants.permissionManageUsers].contains(permission);
    default:
      return false;
  }
}

