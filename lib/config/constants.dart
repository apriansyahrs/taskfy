class AppConstants {
  // API endpoints
  static const String apiBaseUrl = 'https://api.example.com';
  
  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String tasksRoute = '/tasks';
  static const String projectsRoute = '/projects';
  
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
  
  // Error messages
  static const String genericErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';
  
  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

