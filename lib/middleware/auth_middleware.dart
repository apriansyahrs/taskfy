import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';

class AuthMiddleware extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;

  const AuthMiddleware({
    Key? key,
    required this.child,
    required this.allowedRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    if (!allowedRoles.contains(authState.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

