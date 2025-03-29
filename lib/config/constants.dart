class AppConstants {
  // Routine Status
  static const String routineStatusNotStarted = 'not_started';
  static const String routineStatusInProgress = 'in_progress';
  static const String routineStatusCompleted = 'completed';
  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String routinesRoute = '/routines';
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
  // User permissions
  static const String permissionCreateUser = 'create_user';
  static const String permissionReadUser = 'read_user';
  static const String permissionUpdateUser = 'update_user';
  static const String permissionDeleteUser = 'delete_user';
  
  // Project permissions
  static const String permissionCreateProject = 'create_project';
  static const String permissionReadProject = 'read_project';
  static const String permissionUpdateProject = 'update_project';
  static const String permissionDeleteProject = 'delete_project';
  
  // Task permissions
  static const String permissionCreateTask = 'create_task';
  static const String permissionReadTask = 'read_task';
  static const String permissionUpdateTask = 'update_task';
  static const String permissionDeleteTask = 'delete_task';
  static const String permissionChangeTaskStatus = 'change_task_status';
  
  // Routine permissions
  static const String permissionCreateRoutine = 'create_routine';
  static const String permissionReadRoutine = 'read_routine';
  static const String permissionUpdateRoutine = 'update_routine';
  static const String permissionDeleteRoutine = 'delete_routine';
  static const String permissionChangeRoutineStatus = 'change_routine_status';
  
  // Report permissions
  static const String permissionViewReports = 'view_reports';

  // Error messages
  static const String genericErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

