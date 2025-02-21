import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/providers/user_provider.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('UserEditScreen');

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
      pageTitle: 'Edit User Role',
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
          if (_selectedRole == 'pegawai') {
            _selectedRole = user.role;
          }
          _log.info('Current selected role: $_selectedRole');

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${_emailController.text}',
                      style: Theme.of(context).textTheme.titleMedium,
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
                        if (newValue != null) {
                          setState(() {
                            _selectedRole = newValue;
                            _log.info('Role changed to: $_selectedRole');
                          });
                        }
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
                            child: Text('Update User Role'),
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

      try {
        _log.info('Updating user with role: $_selectedRole');
        final updatedUser = taskfy_user.User(
          id: widget.userId,
          email: _emailController.text,
          role: _selectedRole,
        );

        final result = await ref.read(userNotifierProvider.notifier).updateUser(updatedUser);

        if (mounted) {
          if (result) {
            _log.info('User role updated successfully');
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update user role')),
            );
          }
        }
      } catch (e) {
        _log.warning('Error updating user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
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

