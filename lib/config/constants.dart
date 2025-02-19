class AppConstants {
  // API endpoints
  static const String apiBaseUrl = 'https://api.example.com';

  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String tasksRoute = '/tasks';
  static const String projectsRoute = '/projects';
  static const String usersRoute = '/users';
  static const String reportsRoute = '/reports';

  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // Task statuses
  static const String taskStatusNotStarted = 'not_started';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';

  // Task priorities
  static const String taskPriorityLow = 'low';
  static const String taskPriorityMedium = 'medium';
  static const String taskPriorityHigh = 'high';

  // Project statuses
  static const String projectStatusNotStarted = 'not_started';
  static const String projectStatusInProgress = 'in_progress';
  static const String projectStatusCompleted = 'completed';
  static const String projectStatusOnHold = 'on_hold';
  static const String projectStatusCancelled = 'cancelled';

  static const List<String> projectStatuses = [
    projectStatusNotStarted,
    projectStatusInProgress,
    projectStatusCompleted,
    projectStatusOnHold,
    projectStatusCancelled,
  ];

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'pegawai';
  static const String roleExecutive = 'direksi';

  // Permissions
  static const String permissionManageUsers = 'manage_users';
  static const String permissionViewReports = 'view_reports';
  static const String permissionCreateProject = 'create_project';
  static const String permissionEditProject = 'edit_project';
  static const String permissionDeleteProject = 'delete_project';
  static const String permissionCreateTask = 'create_task';
  static const String permissionEditTask = 'edit_task';
  static const String permissionDeleteTask = 'delete_task';
  static const String permissionUpdateTaskStatus = 'update_task_status';
  static const String permissionUpdateProjectStatus = 'update_project_status';

  // Error messages
  static const String genericErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

