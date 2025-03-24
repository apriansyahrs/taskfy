import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:taskfy/services/service_locator.dart';

// Track if the app is in initialization phase (first load or refresh)
final appInitializingProvider = StateProvider<bool>((ref) => true);

// Improved auth loading provider
final authLoadingProvider = StateProvider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final initializing = ref.watch(appInitializingProvider);
  
  // Consider auth as loading if either the state is loading or app is initializing
  return authState is AsyncLoading || initializing;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = getIt<AuthService>();
  
  // Mark initialization as complete after auth stream emits first value
  authService.authStateChanges.listen((_) {
    Future.microtask(() {
      ref.read(appInitializingProvider.notifier).state = false;
    });
  });
  
  return authService.authStateChanges;
});

// Store last authenticated path to restore after refresh
final lastPathProvider = StateProvider<String?>((ref) => null);

// Track if we should remember current path (don't remember login paths)
final shouldRememberPathProvider = Provider<bool>((ref) {
  final currentPath = ref.watch(lastPathProvider);
  if (currentPath == null) return false;
  
  // Don't remember auth-related paths
  return !['/','forgot-password', '/reset-password'].contains(currentPath);
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = getIt<AuthService>();
  return await authService.getCurrentUser();
});

final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.role;
});

