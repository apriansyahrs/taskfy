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
        path: '/dashboard',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TaskListScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TaskCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: TaskDetailScreen(taskId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: TaskEditScreen(taskId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/projects',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ProjectListScreen(),
        ),
      ),
      GoRoute(
        path: '/projects/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ProjectCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/projects/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: ProjectDetailScreen(projectId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/projects/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: ProjectEditScreen(projectId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ReportScreen(),
        ),
      ),
      GoRoute(
        path: '/users',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AuthMiddleware(
            allowedRoles: ['admin'],
            child: const UserListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/users/create',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AuthMiddleware(
            allowedRoles: ['admin'],
            child: const UserCreateScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/users/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: AuthMiddleware(
              allowedRoles: ['admin'],
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
        return '/dashboard';
      }

      // Role-based redirects
      final userRole = authState.value?.role;
      if (isLoggedIn && userRole != null) {
        if (state.uri.path.startsWith('/users') && !_hasPermission('manage_users', userRole)) {
          return '/dashboard';
        }
        if (state.uri.path == '/reports' && !_hasPermission('view_reports', userRole)) {
          return '/dashboard';
        }
        if ((state.uri.path == '/tasks/create' || state.uri.path == '/projects/create') && 
            !_hasPermission('create_task', userRole) && !_hasPermission('create_project', userRole)) {
          return '/dashboard';
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
  // Implement your permission logic here
  switch (role) {
    case 'admin':
      return true;
    case 'manager':
      return ['create_project', 'create_task', 'assign_task', 'view_reports'].contains(permission);
    case 'employee':
      return ['update_task', 'update_project'].contains(permission);
    case 'viewer':
      return ['view_reports'].contains(permission);
    default:
      return false;
  }
}

