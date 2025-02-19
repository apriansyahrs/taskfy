import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/providers/user_provider.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserEditScreen({super.key, required this.userId});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  String _selectedRole = 'pegawai';
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider(widget.userId));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Edit User',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          onPressed: _isLoading ? null : _updateUser,
        ),
      ],
      child: userAsyncValue.when(
        data: (taskfy_user.User? user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          _emailController.text = user.email;
          _selectedRole = user.role;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: ['admin', 'manager', 'pegawai', 'direksi'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateUser,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Update User'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updatedUser = taskfy_user.User(
        id: widget.userId,
        email: _emailController.text,
        role: _selectedRole,
      );

      try {
        await ref.read(userNotifierProvider.notifier).updateUser(updatedUser);
        if (mounted) {
          context.go('/users');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating user: $e')),
          );
        }
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

