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
  String _selectedRole = '';
  bool _isLoading = false;
  bool _hasInitialized = false;

  static const List<String> _availableRoles = [
    'admin',
    'manager',
    'pegawai',
    'direksi'
  ];

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

  void _initializeUserData(taskfy_user.User user) {
    if (!_hasInitialized) {
      _emailController.text = user.email;
      _selectedRole = user.role;
      _hasInitialized = true;
      _log.info('Initialized user data: ${user.email}, role: ${user.role}');
    }
  }

  Future<void> _updateUser() async {
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
        if (!mounted) return;
        if (result) {
          _showSuccessMessage();
          _navigateBack();
        } else {
          _showErrorMessage('Failed to update user role');
        }
      } catch (e) {
        _log.warning('Error updating user: $e');
        if (mounted) {
          _showErrorMessage('Error: $e');
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

  void _showSuccessMessage() {
    _log.info('User role updated successfully');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User role updated successfully')),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateBack() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.pop();
      }
    });
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: userAsyncValue.when(
              data: (taskfy_user.User? user) {
                if (user == null) {
                  return const Center(child: Text('User not found'));
                }
                _initializeUserData(user);
                return _buildUserEditForm(context);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserEditForm(BuildContext context) {

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildEmailDisplay(context),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 32),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _emailController.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
      items: _availableRoles.map((String value) {
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
    );
  }

  Widget _buildUpdateButton() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateUser,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Update User Role'),
      ),
    );
  }
}

