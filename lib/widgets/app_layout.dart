import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppLayout');

class AppLayout extends ConsumerWidget {
  final String title;
  final String pageTitle;
  final Widget child;
  final List<Widget>? actions;

  const AppLayout({
    super.key,
    required this.title,
    required this.pageTitle,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider);
    final user = userState.value;
    final isSmallScreen = MediaQuery.of(context).size.width < StyleGuide.breakpointDesktop;

    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: ThemeConfig.background,
              title: Text(pageTitle),
              iconTheme: const IconThemeData(color: ThemeConfig.textPrimary),
              titleTextStyle: StyleGuide.titleStyle,
              actions: [
                if (actions != null) ...actions!,
                SizedBox(width: StyleGuide.spacingSmall),
                _buildUserMenu(
                    context, ref, user?.email ?? '', user?.role ?? ''),
              ],
            )
          : null,
      drawer: isSmallScreen
          ? _buildSidePanel(context, ref, user?.email ?? '', user?.role ?? '')
          : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            _buildSidePanel(context, ref, user?.email ?? '', user?.role ?? ''),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isSmallScreen)
                  _buildTopBar(context, ref, pageTitle, user?.email ?? '',
                      user?.role ?? ''),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(StyleGuide.paddingMedium),
                    color: ThemeConfig.background,
                    child: Container(
                      decoration: StyleGuide.cardDecoration(),
                      padding: EdgeInsets.all(StyleGuide.paddingMedium),
                      child: child,
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

  Widget _buildTopBar(BuildContext context, WidgetRef ref, String title,
      String email, String role) {
    // Google Play Console style top bar with more playful elements
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF202124),
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
          _buildUserMenu(context, ref, email, role),
        ],
      ),
    );
  }

  Widget _buildSidePanel(
      BuildContext context, WidgetRef ref, String email, String role) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDrawer =
        context.findAncestorWidgetOfExactType<Drawer>() != null;

    // Get user permissions instead of relying on roles
    final permissions = ref.watch(permissionProvider);

    // Log permissions for debugging
    _log.info('User role: $role, Permissions: ${permissions.toString()}');

    final bool isEmployee = role == AppConstants.roleEmployee;
    final bool isAdmin = role == AppConstants.roleAdmin;

    // Check specific permissions - ensure admin always has user management
    final canManageUsers = isAdmin ||
        permissions.contains(AppConstants.permissionCreateUser) ||
        permissions.contains(AppConstants.permissionReadUser) ||
        permissions.contains(AppConstants.permissionUpdateUser) ||
        permissions.contains(AppConstants.permissionDeleteUser);

    final canManageProjects =
        permissions.contains(AppConstants.permissionCreateProject) ||
            permissions.contains(AppConstants.permissionUpdateProject) ||
            permissions.contains(AppConstants.permissionDeleteProject);

    final canManageRoutines =
        permissions.contains(AppConstants.permissionCreateRoutine) ||
            permissions.contains(AppConstants.permissionUpdateRoutine) ||
            permissions.contains(AppConstants.permissionDeleteRoutine);

    final canViewProjects =
        permissions.contains(AppConstants.permissionReadProject);
    final canViewRoutines =
        permissions.contains(AppConstants.permissionReadRoutine);
    final canViewReports =
        permissions.contains(AppConstants.permissionViewReports);

    _log.info(
        'canManageUsers: $canManageUsers, isEmployee: $isEmployee, canViewProjects: $canViewProjects, canViewRoutines: $canViewRoutines');

    // Google Play Console style colors
    final primaryColor = const Color(0xFF1967D2);
    final selectedBgColor = const Color(0xFFE8F0FE);
    final hoverColor = const Color(0xFFF1F3F4);

    return Container(
      width: isDrawer ? null : 256,
      color: const Color(0xFFF8FAFD), // Changed to #f8fafd as per reference
      margin: isDrawer
          ? null
          : const EdgeInsets.only(right: 2), // Subtle separation
      child: Column(
        children: [
          // Google Play Console style header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.task_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TaskFy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF202124),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: l10n.dashboardTitle,
                  route: '/dashboard',
                  primaryColor: primaryColor,
                  selectedBgColor: selectedBgColor,
                  hoverColor: hoverColor,
                ),

                // Always show My Projects to employees (they have read permission)
                if (isEmployee || canViewProjects)
                  _buildNavItem(
                    context,
                    icon: Icons.work_outline,
                    title: l10n.myProjectsTitle,
                    route: '/my-projects',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),

                // Always show My Routines to employees (they have read permission)
                if (isEmployee || canViewRoutines)
                  _buildNavItem(
                    context,
                    icon: Icons.repeat,
                    title: l10n.myRoutinesTitle,
                    route: '/my-routines',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),

                // Management section - hide for regular employees
                if (!isEmployee &&
                    (canManageProjects ||
                        canManageRoutines ||
                        canManageUsers ||
                        isAdmin))
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'MANAGEMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5F6368),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                if (canManageProjects)
                  _buildNavItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: l10n.projectsTitle,
                    route: '/projects',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),

                if (canManageRoutines)
                  _buildNavItem(
                    context,
                    icon: Icons.repeat_outlined,
                    title: l10n.routinesTitle,
                    route: '/routines',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),

                if (canManageUsers || isAdmin)
                  _buildNavItem(
                    context,
                    icon: Icons.people_outline,
                    title: l10n.userManagementTitle,
                    route: '/users',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),

                if (canViewReports)
                  _buildNavItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    title: l10n.reportsTitle,
                    route: '/reports',
                    primaryColor: primaryColor,
                    selectedBgColor: selectedBgColor,
                    hoverColor: hoverColor,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE1E3E6)),
          _buildNavItem(
            context,
            icon: Icons.logout,
            title: l10n.logoutButton,
            onTap: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
            primaryColor: primaryColor,
            selectedBgColor: selectedBgColor,
            hoverColor: hoverColor,
            isBottomItem: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    required Color primaryColor,
    required Color selectedBgColor,
    required Color hoverColor,
    bool isBottomItem = false,
  }) {
    final bool isSelected =
        route != null && GoRouterState.of(context).matchedLocation == route;
    final iconColor = isSelected ? primaryColor : const Color(0xFF5F6368);
    final textColor = isSelected ? primaryColor : const Color(0xFF3C4043);
    final bgColor = isSelected ? selectedBgColor : Colors.transparent;

    return InkWell(
      onTap: onTap ?? (route != null ? () => context.go(route) : null),
      hoverColor: hoverColor,
      child: Container(
        height: 48,
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMenu(
      BuildContext context, WidgetRef ref, String email, String role) {
    // Google Play Console style user menu
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      position: PopupMenuPosition.under,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1967D2),
              radius: 16,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  email.split('@').first,
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3C4043),
                      fontSize: 14),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF5F6368),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: Color(0xFF5F6368)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: Color(0xFF5F6368)),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.logoutButton,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF3C4043))),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authProvider.notifier).signOut();
          context.go('/login');
        }
      },
    );
  }
}
