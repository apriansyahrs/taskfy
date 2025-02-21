import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/models/user.dart' as taskfy_user; // Changed to lowercase with underscores
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/user_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/services/auth_service.dart';

import '../widgets/stat_card.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(usersStreamProvider);
    final permissions = ref.watch(permissionProvider);
    final isAdmin = ref.watch(authProvider)?.role == 'admin';

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'User Management',
      actions: [
        if (isAdmin || permissions.contains('create_user'))
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
            onPressed: () => context.go('/users/create'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserStats(usersAsyncValue),
          const SizedBox(height: 24),
          _buildUserList(context, usersAsyncValue, permissions),
        ],
      ),
    );
  }

  Widget _buildUserStats(AsyncValue<List<taskfy_user.User>> usersAsyncValue) {
    return usersAsyncValue.when(
      data: (users) {
        final totalUsers = users.length;
        final adminCount = users.where((user) => user.role == 'admin').length;
        final managerCount = users.where((user) => user.role == 'manager').length;
        final employeeCount = users.where((user) => user.role == 'pegawai').length;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue, constraints),
                _buildStatCard('Admins', adminCount.toString(), Icons.admin_panel_settings, Colors.red, constraints),
                _buildStatCard('Managers', managerCount.toString(), Icons.manage_accounts, Colors.orange, constraints),
                _buildStatCard('Employees', employeeCount.toString(), Icons.work, Colors.green, constraints),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildUserList(BuildContext context, AsyncValue<List<taskfy_user.User>> usersAsyncValue, Set<String> permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'User List',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            usersAsyncValue.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No users found'),
                    ),
                  );
                }
                final filteredUsers = users.where((user) =>
                    user.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                    user.role.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                return _buildUserTable(filteredUsers, permissions);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable(List<taskfy_user.User> users, Set<String> permissions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: users.map((user) => _buildUserRow(context, user, permissions)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildUserRow(BuildContext context, taskfy_user.User user, Set<String> permissions) {
    final isAdmin = ref.read(authProvider)?.role == 'admin';

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(user.email[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(user.email, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        DataCell(Text(user.role)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin || permissions.contains('update_user'))
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/users/${user.id}/edit'),
                ),
              if (isAdmin || permissions.contains('reset_password'))
                IconButton(
                  icon: const Icon(Icons.lock_reset),
                  onPressed: () => _showResetPasswordDialog(context, user.email),
                ),
              if (isAdmin || permissions.contains('delete_user'))
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteUserDialog(context, user.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BoxConstraints constraints) {
    final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
    return SizedBox(
      width: cardWidth,
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Are you sure you want to reset the password for $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              ref.read(authServiceProvider).resetPassword(email).then((_) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Password reset email sent to $email')),
                  );
                }
              }).catchError((e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              });
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              ref.read(userNotifierProvider.notifier).deleteUser(userId).then((_) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                }
              }).catchError((e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting user: $e')),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

