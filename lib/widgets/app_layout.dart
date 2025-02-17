import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppLayout extends ConsumerStatefulWidget {
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
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final permissions = ref.watch(permissionProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF8F7FB),
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(isDarkMode, permissions),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(user, isDarkMode),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.pageTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (widget.actions != null) ...widget.actions!,
                          ],
                        ),
                        if (widget.subtitle != null) ...[
                          SizedBox(height: 8),
                          Text(
                            widget.subtitle!,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                        SizedBox(height: 24),
                        widget.child,
                      ],
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

  Widget _buildTopBar(User? user, bool isDarkMode) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Spacer(),
          PopupMenuButton<String>(
            offset: Offset(0, 40),
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
                SizedBox(width: 8),
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
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDarkMode, Set<String> permissions) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: _isSidebarCollapsed ? 70 : 240,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 24),
          _buildSidebarHeader(isDarkMode),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isDarkMode: isDarkMode,
                  ),
                  if (permissions.contains('update_task') ||
                      permissions.contains('create_task'))
                    _buildSidebarItem(
                      icon: Icons.task_outlined,
                      title: 'Tasks',
                      route: '/tasks',
                      isDarkMode: isDarkMode,
                    ),
                  if (permissions.contains('create_project') ||
                      permissions.contains('update_project'))
                    _buildSidebarItem(
                      icon: Icons.work_outline,
                      title: 'Projects',
                      route: '/projects',
                      isDarkMode: isDarkMode,
                    ),
                  if (permissions.contains('manage_users'))
                    _buildSidebarItem(
                      icon: Icons.people,
                      title: 'Users',
                      route: '/users',
                      isDarkMode: isDarkMode,
                    ),
                  if (permissions.contains('view_reports'))
                    _buildSidebarItem(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      route: '/reports',
                      isDarkMode: isDarkMode,
                    ),
                ],
              ),
            ),
          ),
          Divider(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          const _ThemeToggle(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
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
            SizedBox(width: 8),
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
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: 16),
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
                SizedBox(width: 12),
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

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          ref.read(themeModeProvider.notifier).state =
              isDarkMode ? ThemeMode.light : ThemeMode.dark;
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

