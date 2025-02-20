import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:taskfy/services/service_locator.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = getIt<AuthService>();
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = getIt<AuthService>();
  return await authService.getCurrentUser();
});

final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.role;
});

