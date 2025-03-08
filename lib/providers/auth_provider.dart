import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthProvider');

final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider must be overridden');
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);

      // Listen to auth state changes
      _authService.authStateChanges.listen(
        (user) => state = AsyncValue.data(user),
        onError: (error) => state = AsyncValue.error(error, StackTrace.current),
      );
    } catch (error, stackTrace) {
      _log.warning('Error initializing auth state: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      _log.warning('Error signing in: $error');
      // Make sure to preserve the original error type for proper handling in UI
      state = AsyncValue.error(error, stackTrace);
      // Re-throw the error to ensure it's caught by the UI layer
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      _log.warning('Error signing out: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signUp(String email, String password, String role) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signUp(email, password, role);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      _log.warning('Error signing up: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final userEmailProvider = Provider<String?>((ref) {
  final userState = ref.watch(authProvider);
  return userState.value?.email;
});

final userRoleProvider = Provider<String?>((ref) {
  final userState = ref.watch(authProvider);
  return userState.value?.role;
});