import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/utils/logger_util.dart';
import 'package:taskfy/widgets/custom_text_field.dart';
import 'package:taskfy/utils/error_handler.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.loginTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            labelText: AppLocalizations.of(context)!.emailLabel,
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.emailRequired;
                              }
                              if (!value.contains('@')) {
                                return AppLocalizations.of(context)!.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: AppLocalizations.of(context)!.passwordLabel,
                            prefixIcon: Icons.lock,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.passwordRequired;
                              }
                              if (value.length < 6) {
                                return AppLocalizations.of(context)!.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : Text(AppLocalizations.of(context)!.loginButton),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: Text(AppLocalizations.of(context)!.forgotPasswordButton),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(authProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

        if (ref.read(authProvider).value != null) {
          if (!mounted) return;
          context.go('/dashboard');
        } else {
          if (!mounted) return;
          showErrorSnackBar(context, 'Invalid email or password');
        }
      } catch (e) {
        if (!mounted) return;
        
        // Handle specific authentication errors
        if (e is AuthError) {
          showErrorSnackBar(context, e.message);
        } else {
          showErrorSnackBar(context, getErrorMessage(e));
        }
        
        // Log the error for debugging
        LoggerUtil.error('Login error', tag: 'LOGIN', error: e);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

