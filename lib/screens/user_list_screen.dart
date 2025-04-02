import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/models/user.dart' as taskfy_user; // Changed to lowercase with underscores
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/user_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/services/auth_service.dart' as auth_service;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/widgets/stat_card.dart';

final userListStreamProvider = StreamProvider<List<taskfy_user.User>>((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => taskfy_user.User.fromJson(json)).toList());
});

final isAdmin = Provider<bool>((ref) {
  final userState = ref.watch(authProvider);
  return userState.value?.role == 'admin';
});

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
    ref.watch(authProvider);
    final usersAsyncValue = ref.watch(userListStreamProvider);
    final permissions = ref.watch(permissionProvider);
    final l10n = AppLocalizations.of(context)!;
    final isUserAdmin = ref.watch(isAdmin);

    return AppLayout(
      title: l10n.appTitle,
      pageTitle: l10n.userManagementTitle,
      floatingActionButton: (isUserAdmin || permissions.contains('create_user')) 
        ? FloatingActionButton.extended(
            icon: const Icon(Icons.person_add),
            label: Text(l10n.addUserButton),
            onPressed: () => context.go('/users/create'),
          )
        : null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserStats(usersAsyncValue),
            const SizedBox(height: 24),
            _buildUserList(context, usersAsyncValue, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats(AsyncValue<List<taskfy_user.User>> usersAsyncValue) {
    final l10n = AppLocalizations.of(context)!;
    return usersAsyncValue.when(
      data: (users) {
        final totalUsers = users.length;
        final adminCount = users.where((user) => user.role == 'admin').length;
        final managerCount = users.where((user) => user.role == 'manager').length;
        final employeeCount = users.where((user) => user.role == 'pegawai').length;
        final direksiCount = users.where((user) => user.role == 'direksi').length;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(l10n.totalUsersTitle, totalUsers.toString(), Icons.people, Colors.blue, constraints),
                _buildStatCard(l10n.adminsTitle, adminCount.toString(), Icons.admin_panel_settings, Colors.red, constraints),
                _buildStatCard(l10n.managersTitle, managerCount.toString(), Icons.manage_accounts, Colors.orange, constraints),
                _buildStatCard(l10n.employeesTitle, employeeCount.toString(), Icons.work, Colors.green, constraints),
                _buildStatCard(l10n.executivesTitle, direksiCount.toString(), Icons.business, Colors.purple, constraints),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.userListTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchUsersPlaceholder,
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
                return _buildUserTable(filteredUsers, permissions, l10n);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable(List<taskfy_user.User> users, Set<String> permissions, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  DataColumn(label: Text(l10n.userLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.roleLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.actionsLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: users.map((user) => _buildUserRow(context, user, permissions)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildUserRow(BuildContext context, taskfy_user.User user, Set<String> permissions) {
    final isAdmin = ref.read(authProvider).value?.role == 'admin';

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
    final cardWidth = (constraints.maxWidth - (4 * 16)) / 5; // Changed divisor to 5 and spacing count to 4
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
              ref.read(auth_service.authServiceProvider).resetPassword(email).then((_) {
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

