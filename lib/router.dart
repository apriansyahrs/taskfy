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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

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
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/';
      final isForgotPassword = state.uri.path == '/forgot-password';
      final isResetPassword = state.uri.path == '/reset-password';

      if (!isLoggedIn && !isLoggingIn && !isForgotPassword && !isResetPassword) {
        return '/';
      }

      if (isLoggedIn && (isLoggingIn || isForgotPassword || isResetPassword)) {
        return AppConstants.dashboardRoute;
      }

      final userRole = authState.value?.role;
      if (isLoggedIn && userRole != null) {
        if (state.uri.path.startsWith(AppConstants.usersRoute) && !_hasPermission(AppConstants.permissionManageUsers, userRole)) {
          return AppConstants.dashboardRoute;
        }
        if (state.uri.path == AppConstants.reportsRoute && !_hasPermission(AppConstants.permissionViewReports, userRole)) {
          return AppConstants.dashboardRoute;
        }
        if ((state.uri.path == '${AppConstants.routinesRoute}/create' || state.uri.path == '${AppConstants.projectsRoute}/create') && 
            !_hasPermission(AppConstants.permissionCreateRoutine, userRole) && !_hasPermission(AppConstants.permissionCreateProject, userRole)) {
          return AppConstants.dashboardRoute;
        }
      }

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

