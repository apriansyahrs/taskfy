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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > StyleGuide.breakpointTablet;

        if (isWideScreen) {
          // Use NavigationRail for wide screens (Desktop/Tablet)
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _buildNavigationRail(context),
                  Expanded(
                    child: Scaffold(
                      appBar: _buildStandardAppBar(context, isWideScreen),
                      body: _buildPageContent(context, isWideScreen),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Use NavigationDrawer for narrow screens (Mobile)
          return Scaffold(
            appBar: _buildStandardAppBar(context, isWideScreen),
            drawer: _buildNavigationDrawer(context),
            body: _buildPageContent(context, isWideScreen),
          );
        }
      },
    );
  }

  PreferredSizeWidget _buildStandardAppBar(
      BuildContext context, bool isWideScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(
        title,
        semanticsLabel: '$title page',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      actions: [
        _buildThemeToggle(context),
        const SizedBox(width: 8),
        _buildUserMenu(context),
      ],
      centerTitle: false,
      scrolledUnderElevation: 2.0,
    );
  }

  Widget _buildPageContent(BuildContext context, bool isWideScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 32.0 : 16.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header with title and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Semantic heading for screen readers
                    Semantics(
                      header: true,
                      child: Text(
                        pageTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null)
                Wrap(
                  spacing: 12,
                  children: actions!.map((action) {
                    // Add a MergeSemantics to make actions more accessible
                    return MergeSemantics(child: action);
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Main content area with standard elevation
          Expanded(
            child: Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeModeProvider);
      final isDark = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              MediaQuery.of(context).platformBrightness == Brightness.dark);

      final label = isDark ? 'Switch to light theme' : 'Switch to dark theme';

      return Tooltip(
        message: label,
        excludeFromSemantics: true, // We're using semanticLabel instead
        child: IconButton(
          icon:
              Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          onPressed: () {
            ref.read(themeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
      );
    });
  }

  Widget _buildUserMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer(builder: (context, ref, _) {
      final userState = ref.watch(authProvider);
      final user = userState.value;
      final displayName = user?.email.split('@').first ?? 'User';
      final avatarLetter = (user?.email.isNotEmpty ?? false)
          ? user!.email.substring(0, 1).toUpperCase()
          : 'U';

      return MenuAnchor(
        builder: (context, controller, child) {
          return Semantics(
            button: true,
            label: 'User menu for $displayName',
            child: InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        avatarLetter,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.person_outline),
            child: const Text('Profile'),
            onPressed: () {
              // Navigate to profile
            },
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.settings_outlined),
            child: const Text('Settings'),
            onPressed: () {
              // Navigate to settings
            },
          ),
          const Divider(),
          MenuItemButton(
            leadingIcon: Icon(
              Icons.logout_outlined,
              color: colorScheme.error,
            ),
            child: Text(
              AppLocalizations.of(context)!.logoutButton,
              style: TextStyle(
                color: colorScheme.error,
              ),
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = GoRouterState.of(context).uri.path;

    return Consumer(builder: (context, ref, _) {
      final permissions = ref.watch(permissionProvider);

      return NavigationDrawer(
        selectedIndex: _getSelectedIndex(currentRoute, permissions),
        onDestinationSelected: (index) {
          final route = _getRouteForIndex(index, permissions);
          context.go(route);
          Navigator.pop(context); // Close drawer
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: ExcludeSemantics(
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const Divider(indent: 28, endIndent: 28),

          // Build navigation items based on permissions
          ..._buildNavigationItems(context, permissions, l10n),
        ],
      );
    });
  }

  Widget _buildNavigationRail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = GoRouterState.of(context).uri.path;
    final textTheme = Theme.of(context).textTheme;

    return Consumer(builder: (context, ref, _) {
      final permissions = ref.watch(permissionProvider);
      
      // Creating a stateful builder to manage expanded state
      return StatefulBuilder(
        builder: (context, setState) {
          // Local state for expanded/collapsed
          bool isExpanded = true; // Default to expanded
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isExpanded ? 240 : 80,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(1, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title and expand/collapse toggle
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (isExpanded) ...[
                        Expanded(
                          child: Text(
                            l10n.appTitle,
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.chevron_left : Icons.chevron_right,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        tooltip: isExpanded ? 'Collapse' : 'Expand',
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Navigation items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildCustomNavigationItems(
                        context, 
                        permissions, 
                        l10n, 
                        currentRoute, 
                        isExpanded
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // Helper method to build custom navigation items for expanded/collapsed NavigationRail
  List<Widget> _buildCustomNavigationItems(
    BuildContext context, 
    Set<String> permissions, 
    AppLocalizations l10n,
    String currentRoute, 
    bool isExpanded
  ) {
    final List<Widget> items = [];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Dashboard (always shown)
    items.add(
      _buildCustomNavItem(
        context: context, 
        icon: Icons.dashboard_rounded,
        label: l10n.dashboardTitle,
        route: '/dashboard',
        isActive: currentRoute == '/dashboard',
        isExpanded: isExpanded,
      ),
    );
    
    // Projects section header
    if (permissions.contains('update_project_status') || 
        permissions.contains('create_project') || 
        permissions.contains('update_project')) {
          
      if (isExpanded) {
        items.add(const SizedBox(height: 16));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.projectsTitle.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else {
        items.add(const Divider(indent: 16, endIndent: 16));
      }
      
      // My Projects
      if (permissions.contains('update_project_status')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.work_rounded,
            label: l10n.myProjectsTitle,
            route: '/my-projects',
            isActive: currentRoute == '/my-projects',
            isExpanded: isExpanded,
          ),
        );
      }
      
      // Projects
      if (permissions.contains('create_project') || permissions.contains('update_project')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.folder_rounded,
            label: l10n.projectsTitle,
            route: '/projects',
            isActive: currentRoute == '/projects',
            isExpanded: isExpanded,
          ),
        );
      }
    }
    
    // Routines section header
    if (permissions.contains('update_routine_status') || 
        permissions.contains('update_routine') || 
        permissions.contains('create_routine')) {
          
      if (isExpanded) {
        items.add(const SizedBox(height: 16));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.routinesTitle.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else {
        items.add(const Divider(indent: 16, endIndent: 16));
      }
      
      // My Routines
      if (permissions.contains('update_routine_status')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            label: l10n.myRoutinesTitle,
            route: '/my-routines',
            isActive: currentRoute == '/my-routines',
            isExpanded: isExpanded,
          ),
        );
      }
      
      // Routines
      if (permissions.contains('update_routine') || permissions.contains('create_routine')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.repeat_rounded,
            label: l10n.routinesTitle,
            route: '/routines',
            isActive: currentRoute == '/routines',
            isExpanded: isExpanded,
          ),
        );
      }
    }
    
    // Admin section header
    if (permissions.contains('manage_users') || permissions.contains('view_reports')) {
          
      if (isExpanded) {
        items.add(const SizedBox(height: 16));
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.usersTitle.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else {
        items.add(const Divider(indent: 16, endIndent: 16));
      }
      
      // Users
      if (permissions.contains('manage_users')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.people_rounded,
            label: l10n.usersTitle,
            route: '/users',
            isActive: currentRoute == '/users',
            isExpanded: isExpanded,
          ),
        );
      }
      
      // Reports
      if (permissions.contains('view_reports')) {
        items.add(
          _buildCustomNavItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            label: l10n.reportsTitle,
            route: '/reports',
            isActive: currentRoute == '/reports',
            isExpanded: isExpanded,
          ),
        );
      }
    }
    
    return items;
  }
  
  // Build a custom navigation item with improved accessibility
  Widget _buildCustomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required bool isExpanded,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determine the best contrast color for accessibility
    final iconColor = isActive 
        ? colorScheme.primary 
        : colorScheme.onSurfaceVariant;
    
    final textColor = isActive 
        ? colorScheme.primary 
        : colorScheme.onSurfaceVariant;
    
    // Accessibility state description
    final String stateDescription = isActive 
        ? '$label, current page' 
        : label;
    
    return Semantics(
      selected: isActive,
      button: true,
      label: label,
      hint: isActive ? 'Current page' : 'Navigate to $label',
      value: stateDescription,
      excludeSemantics: true, // We'll handle semantics manually
      child: FocusableActionDetector(
        actions: <Type, Action<Intent>>{},
        shortcuts: <ShortcutActivator, Intent>{},
        onShowFocusHighlight: (focused) {
          // This could be used to show a custom focus indicator
        },
        child: Builder(builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(route),
              borderRadius: BorderRadius.circular(isExpanded ? 8 : 0),
              highlightColor: colorScheme.primaryContainer.withOpacity(0.3),
              hoverColor: colorScheme.primaryContainer.withOpacity(0.1),
              child: Container(
                height: 56,
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 16 : 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(isExpanded ? 8 : 0),
                  border: isFocused 
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 8 : 4,
                  vertical: 2,
                ),
                child: Directionality(
                  // Ensure consistent text direction for accessibility
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                        semanticLabel: isExpanded ? null : label, // Only add semanticLabel if collapsed
                      ),
                      if (isExpanded) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Tooltip(
                            message: 'Current page',
                            child: Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Helper method to build navigation destinations for the NavigationRail
  List<NavigationRailDestination> _buildNavigationDestinations(
      BuildContext context, Set<String> permissions, AppLocalizations l10n) {
    final List<NavigationRailDestination> destinations = [];

    // Dashboard (always shown)
    destinations.add(
      NavigationRailDestination(
        icon: const Icon(Icons.dashboard_rounded),
        selectedIcon: const Icon(Icons.dashboard_rounded),
        label: Text(l10n.dashboardTitle),
      ),
    );

    // My Projects
    if (permissions.contains('update_project_status')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.work_rounded),
          selectedIcon: const Icon(Icons.work_rounded),
          label: Text(l10n.myProjectsTitle),
        ),
      );
    }

    // Projects
    if (permissions.contains('create_project') ||
        permissions.contains('update_project')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.folder_rounded),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: Text(l10n.projectsTitle),
        ),
      );
    }

    // My Routines
    if (permissions.contains('update_routine_status')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.check_circle_outline_rounded),
          selectedIcon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(l10n.myRoutinesTitle),
        ),
      );
    }

    // Routines
    if (permissions.contains('update_routine') ||
        permissions.contains('create_routine')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.repeat_rounded),
          selectedIcon: const Icon(Icons.repeat_rounded),
          label: Text(l10n.routinesTitle),
        ),
      );
    }

    // Users (Admin)
    if (permissions.contains('manage_users')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.people_rounded),
          selectedIcon: const Icon(Icons.people_rounded),
          label: Text(l10n.usersTitle),
        ),
      );
    }

    // Reports (Admin)
    if (permissions.contains('view_reports')) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: Text(l10n.reportsTitle),
        ),
      );
    }

    return destinations;
  }

  // Helper method to build navigation items for the NavigationDrawer
  List<Widget> _buildNavigationItems(
      BuildContext context, Set<String> permissions, AppLocalizations l10n) {
    final List<Widget> items = [];
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).uri.path;

    // Dashboard (always shown)
    items.add(
      _buildAccessibleNavigationDestination(
        icon: const Icon(Icons.dashboard_rounded),
        selectedIcon: const Icon(Icons.dashboard_rounded),
        label: l10n.dashboardTitle,
        isActive: currentRoute == '/dashboard',
      ),
    );

    // Projects section
    if (permissions.contains('update_project_status') ||
        permissions.contains('create_project') ||
        permissions.contains('update_project')) {
      items.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
      );

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 16, 10),
          child: Text(
            l10n.projectsTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // My Projects
      if (permissions.contains('update_project_status')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.work_rounded),
            selectedIcon: const Icon(Icons.work_rounded),
            label: l10n.myProjectsTitle,
            isActive: currentRoute == '/my-projects',
          ),
        );
      }

      // Projects
      if (permissions.contains('create_project') ||
          permissions.contains('update_project')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.folder_rounded),
            selectedIcon: const Icon(Icons.folder_rounded),
            label: l10n.projectsTitle,
            isActive: currentRoute == '/projects',
          ),
        );
      }
    }

    // Routines section
    if (permissions.contains('update_routine_status') ||
        permissions.contains('update_routine') ||
        permissions.contains('create_routine')) {
      items.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
      );

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 16, 10),
          child: Text(
            l10n.routinesTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // My Routines
      if (permissions.contains('update_routine_status')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.check_circle_outline_rounded),
            selectedIcon: const Icon(Icons.check_circle_outline_rounded),
            label: l10n.myRoutinesTitle,
            isActive: currentRoute == '/my-routines',
          ),
        );
      }

      // Routines
      if (permissions.contains('update_routine') ||
          permissions.contains('create_routine')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.repeat_rounded),
            selectedIcon: const Icon(Icons.repeat_rounded),
            label: l10n.routinesTitle,
            isActive: currentRoute == '/routines',
          ),
        );
      }
    }

    // Admin section
    if (permissions.contains('manage_users') ||
        permissions.contains('view_reports')) {
      items.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
      );

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 16, 10),
          child: Text(
            l10n.usersTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // Users
      if (permissions.contains('manage_users')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.people_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: l10n.usersTitle,
            isActive: currentRoute == '/users',
          ),
        );
      }

      // Reports
      if (permissions.contains('view_reports')) {
        items.add(
          _buildAccessibleNavigationDestination(
            icon: const Icon(Icons.bar_chart_rounded),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.reportsTitle,
            isActive: currentRoute == '/reports',
          ),
        );
      }
    }

    return items;
  }

  // Accessibility-enhanced NavigationDrawerDestination
  Widget _buildAccessibleNavigationDestination({
    required Widget icon,
    required Widget selectedIcon,
    required String label,
    required bool isActive,
  }) {
    return Semantics(
      selected: isActive,
      label: label,
      hint: isActive ? 'Current page' : 'Navigate to $label',
      child: NavigationDrawerDestination(
        icon: icon,
        selectedIcon: selectedIcon,
        label: Text(label),
      ),
    );
  }

  // Helper method to get the selected index based on current route and permissions
  int _getSelectedIndex(String currentRoute, Set<String> permissions) {
    final routes = _getAvailableRoutes(permissions);
    return routes.indexOf(currentRoute);
  }

  // Helper method to get route for a given index
  String _getRouteForIndex(int index, Set<String> permissions) {
    final routes = _getAvailableRoutes(permissions);
    if (index >= 0 && index < routes.length) {
      return routes[index];
    }
    return '/dashboard'; // Default route
  }

  // Helper method to get available routes based on permissions
  List<String> _getAvailableRoutes(Set<String> permissions) {
    final List<String> routes = [];

    // Dashboard (always available)
    routes.add('/dashboard');

    // My Projects
    if (permissions.contains('update_project_status')) {
      routes.add('/my-projects');
    }

    // Projects
    if (permissions.contains('create_project') ||
        permissions.contains('update_project')) {
      routes.add('/projects');
    }

    // My Routines
    if (permissions.contains('update_routine_status')) {
      routes.add('/my-routines');
    }

    // Routines
    if (permissions.contains('update_routine') ||
        permissions.contains('create_routine')) {
      routes.add('/routines');
    }

    // Users (Admin)
    if (permissions.contains('manage_users')) {
      routes.add('/users');
    }

    // Reports (Admin)
    if (permissions.contains('view_reports')) {
      routes.add('/reports');
    }

    return routes;
  }
}
