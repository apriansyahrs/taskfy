import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _init();
  }

  void _init() async {
    state = await _authService.getCurrentUser();
  }

  Future<void> signIn(String email, String password) async {
    state = await _authService.signIn(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  Future<void> signUp(String email, String password, String role) async {
    state = await _authService.signUp(email, password, role);
  }
}

final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider);
  return user?.email;
});

