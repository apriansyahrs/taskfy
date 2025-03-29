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
import 'package:logging/logging.dart';

final _log = Logger('Router');

// Create a provider to track if we're refreshing/initializing
final initialLoadingProvider = StateProvider<bool>((ref) => true);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // This will track whether we're in the initial loading phase
  final isInitialLoading = ref.watch(initialLoadingProvider);

  // When authState changes from loading to a value, mark initial loading as complete
  ref.listen(authStateProvider, (previous, next) {
    if (previous?.isLoading == true && next.isLoading == false) {
      ref.read(initialLoadingProvider.notifier).state = false;
    }
  });

  return GoRouter(
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
    redirect: (context, state) {
      // Get the current loading state
      final isLoading = isInitialLoading || authState.isLoading;

      // During initial loading or auth state loading, don't redirect
      if (isLoading) {
        _log.fine('Auth state is still loading, no redirect');
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/';
      final isForgotPassword = state.uri.path == '/forgot-password';
      final isResetPassword = state.uri.path == '/reset-password';

      _log.fine('Current path: ${state.uri.path}, isLoggedIn: $isLoggedIn');

      // Handle authentication redirects
      if (!isLoggedIn) {
        // If not logged in and not already on auth pages, redirect to login
        if (!isLoggingIn && !isForgotPassword && !isResetPassword) {
          final currentPath = state.uri.toString();
          _log.info('User not logged in, redirecting to login from: $currentPath');
          return '/';
        }
        return null;
      }

      // User is logged in
      if (isLoggingIn || isForgotPassword || isResetPassword) {
        _log.info('User logged in but on auth page, redirecting to dashboard');
        return AppConstants.dashboardRoute;
      }

      // Handle permission checks for specific routes
      final userRole = authState.value?.role;
      if (userRole != null) {
        if (state.uri.path == AppConstants.reportsRoute &&
            !_hasPermission(AppConstants.permissionViewReports, userRole)) {
          return AppConstants.dashboardRoute;
        }

        if ((state.uri.path == '${AppConstants.routinesRoute}/create' ||
                state.uri.path == '${AppConstants.projectsRoute}/create') &&
            !_hasPermission(AppConstants.permissionCreateRoutine, userRole) &&
            !_hasPermission(AppConstants.permissionCreateProject, userRole)) {
          return AppConstants.dashboardRoute;
        }
      }

      // User is logged in and has permission, stay on current page
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});

// Use the permission provider instead of hardcoded role-based permissions
bool _hasPermission(String permission, String role) {
  switch (role) {
    case AppConstants.roleAdmin:
      return [
        AppConstants.permissionCreateUser,
        AppConstants.permissionReadUser,
        AppConstants.permissionUpdateUser,
        AppConstants.permissionDeleteUser,
      ].contains(permission);
    case AppConstants.roleManager:
      return [
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
      ].contains(permission);
    case AppConstants.roleEmployee:
      return [
        AppConstants.permissionReadProject,
        AppConstants.permissionReadTask,
        AppConstants.permissionChangeTaskStatus,
        AppConstants.permissionReadRoutine,
        AppConstants.permissionChangeRoutineStatus,
      ].contains(permission);
    case AppConstants.roleExecutive:
      return [AppConstants.permissionViewReports].contains(permission);
    default:
      return false;
  }
}

