import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > StyleGuide.breakpointTablet;
        return Scaffold(
          drawer: isWideScreen ? null : _buildSidebar(context),
          body: Row(
            children: [
              if (isWideScreen) _buildSidebar(context),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppBar(context, isWideScreen),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isWideScreen ? StyleGuide.paddingLarge : StyleGuide.paddingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              SizedBox(height: isWideScreen ? 24 : 16),
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
      },
    );
  }

  Widget _buildAppBar(BuildContext context, bool isWideScreen) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isWideScreen)
            IconButton(
              icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Scaffold.of(context).openDrawer(),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          const Spacer(),
          _buildUserMenu(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
            ),
            if (actions != null)
              Row(
                children: actions!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final userState = ref.watch(authProvider);
      final user = userState.value;

      return PopupMenuButton<String>(
        offset: const Offset(0, 40),
        position: PopupMenuPosition.under,
        elevation: 3,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user?.email ?? 'User',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.logoutButton,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
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
      final userRole = ref.watch(userRoleProvider);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return _Sidebar(
        permissions: permissions,
        userRole: userRole,
        isDarkMode: isDarkMode,
      );
    });
  }
}

class _Sidebar extends ConsumerStatefulWidget {
  final Set<String> permissions;
  final String? userRole;
  final bool isDarkMode;

  const _Sidebar({
    required this.permissions,
    required this.userRole,
    required this.isDarkMode,
  });

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed ? 70 : 240,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(1, 0),
          ),
        ],
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
                    title: l10n.dashboardTitle,
                    route: '/dashboard',
                    isDarkMode: widget.isDarkMode,
                  ),
                  if (widget.permissions.contains('update_routine_status'))
                    _buildSidebarItem(
                      icon: Icons.task_outlined,
                      title: l10n.myRoutinesTitle,
                      route: '/my-routines',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('update_project_status'))
                    _buildSidebarItem(
                      icon: Icons.work_outline,
                      title: l10n.myProjectsTitle,
                      route: '/my-projects',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('update_routine') ||
                      widget.permissions.contains('create_routine'))
                    _buildSidebarItem(
                      icon: Icons.task_outlined,
                      title: l10n.routinesTitle,
                      route: '/routines',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('create_project') ||
                      widget.permissions.contains('update_project'))
                    _buildSidebarItem(
                      icon: Icons.work_outline,
                      title: l10n.projectsTitle,
                      route: '/projects',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('manage_users'))
                    _buildSidebarItem(
                      icon: Icons.people,
                      title: l10n.usersTitle,
                      route: '/users',
                      isDarkMode: widget.isDarkMode,
                    ),
                  if (widget.permissions.contains('view_reports'))
                    _buildSidebarItem(
                      icon: Icons.bar_chart,
                      title: l10n.reportsTitle,
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Colors.transparent,
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
              l10n.appTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Theme.of(context).colorScheme.onSurface,
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
    final activeColor = Theme.of(context).colorScheme.primary;
    final hoverColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (route != null ? () => context.go(route) : null),
        hoverColor: hoverColor,
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              if (!_isSidebarCollapsed) ...[                
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

