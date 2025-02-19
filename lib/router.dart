import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/screens/login_screen.dart';
import 'package:taskfy/screens/forgot_password_screen.dart';
import 'package:taskfy/screens/dashboard_screen.dart';
import 'package:taskfy/screens/task_detail_screen.dart';
import 'package:taskfy/screens/project_detail_screen.dart';
import 'package:taskfy/screens/task_create_screen.dart';
import 'package:taskfy/screens/project_create_screen.dart';
import 'package:taskfy/screens/task_list_screen.dart';
import 'package:taskfy/screens/project_list_screen.dart';
import 'package:taskfy/screens/task_edit_screen.dart';
import 'package:taskfy/screens/project_edit_screen.dart';
import 'package:taskfy/screens/report_screen.dart';
import 'package:taskfy/screens/user_list_screen.dart';
import 'package:taskfy/screens/user_create_screen.dart';
import 'package:taskfy/screens/user_edit_screen.dart';
import 'package:taskfy/state/app_state.dart';
import 'package:taskfy/middleware/auth_middleware.dart';
import 'package:taskfy/screens/my_tasks_screen.dart';
import 'package:taskfy/screens/my_projects_screen.dart';
import 'package:taskfy/config/constants.dart';

/// Provider for the application's router.
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
        path: AppConstants.dashboardRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.tasksRoute,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TaskListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.tasksRoute}/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TaskCreateScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.tasksRoute}/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: TaskDetailScreen(taskId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.tasksRoute}/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: TaskEditScreen(taskId: id ?? ''),
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
        path: '/my-tasks',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const MyTasksScreen(),
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

      if (!isLoggedIn && !isLoggingIn && !isForgotPassword) {
        return '/';
      }

      if (isLoggedIn && (isLoggingIn || isForgotPassword)) {
        return AppConstants.dashboardRoute;
      }

      // Role-based redirects
      final userRole = authState.value?.role;
      if (isLoggedIn && userRole != null) {
        if (state.uri.path.startsWith(AppConstants.usersRoute) && !_hasPermission(AppConstants.permissionManageUsers, userRole)) {
          return AppConstants.dashboardRoute;
        }
        if (state.uri.path == AppConstants.reportsRoute && !_hasPermission(AppConstants.permissionViewReports, userRole)) {
          return AppConstants.dashboardRoute;
        }
        if ((state.uri.path == '${AppConstants.tasksRoute}/create' || state.uri.path == '${AppConstants.projectsRoute}/create') && 
            !_hasPermission(AppConstants.permissionCreateTask, userRole) && !_hasPermission(AppConstants.permissionCreateProject, userRole)) {
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

/// Checks if a user has a specific permission based on their role.
bool _hasPermission(String permission, String role) {
  switch (role) {
    case AppConstants.roleAdmin:
      return true;
    case AppConstants.roleManager:
      return [
        AppConstants.permissionCreateProject,
        AppConstants.permissionCreateTask,
        AppConstants.permissionEditTask,
        AppConstants.permissionViewReports
      ].contains(permission);
    case AppConstants.roleEmployee:
      return [
        AppConstants.permissionUpdateTaskStatus,
        AppConstants.permissionUpdateProjectStatus
      ].contains(permission);
    case AppConstants.roleExecutive:
      return [AppConstants.permissionViewReports].contains(permission);
    default:
      return false;
  }
}

