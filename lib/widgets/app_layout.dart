import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppLayout extends ConsumerWidget {
  final String title;
  final String pageTitle;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  const AppLayout({
    super.key,
    required this.title,
    required this.pageTitle,
    this.subtitle,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
          _buildUserMenu(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pageTitle,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final user = ref.watch(authProvider);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return PopupMenuButton<String>(
        offset: const Offset(0, 40),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                user?.email.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user?.email ?? 'User',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: const [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'logout') {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/');
            }
          }
        },
      );
    });
  }

  Widget _buildSidebar(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final permissions = ref.watch(permissionProvider);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return _Sidebar(
        permissions: permissions,
        isDarkMode: isDarkMode,
      );
    });
  }
}

class _Sidebar extends ConsumerStatefulWidget {
  final Set<String> permissions;
  final bool isDarkMode;

  const _Sidebar({
    required this.permissions,
    required this.isDarkMode,
  });

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed ? 70 : 240,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(widget.isDarkMode),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isDarkMode: widget.isDarkMode,
                  ),
                  if (widget.permissions.contains('update_task_status'))
                    _buildSidebarItem(
                      icon: Icons.task_outlined,
                      title: 'My Tasks',
                      route: '/my-tasks',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('update_project_status'))
                    _buildSidebarItem(
                      icon: Icons.work_outline,
                      title: 'My Projects',
                      route: '/my-projects',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('update_task') ||
                      widget.permissions.contains('create_task'))
                    _buildSidebarItem(
                      icon: Icons.task_outlined,
                      title: 'Tasks',
                      route: '/tasks',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('create_project') ||
                      widget.permissions.contains('update_project'))
                    _buildSidebarItem(
                      icon: Icons.work_outline,
                      title: 'Projects',
                      route: '/projects',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('manage_users'))
                    _buildSidebarItem(
                      icon: Icons.people,
                      title: 'Users',
                      route: '/users',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('view_reports'))
                    _buildSidebarItem(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      route: '/reports',
                      isDarkMode: widget.isDarkMode,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 8),
            Text(
              'Task Manager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    final isActive =
        route != null && GoRouterState.of(context).uri.path == route;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final activeColor = Theme.of(context).colorScheme.primary;
    final hoverColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (route != null ? () => context.go(route) : null),
        hoverColor: hoverColor,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : textColor.withOpacity(0.7),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? activeColor : textColor.withOpacity(0.7),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

