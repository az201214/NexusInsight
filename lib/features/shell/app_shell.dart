import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem('/dashboard', Icons.dashboard_rounded, 'Home'),
    _NavItem('/tasks', Icons.task_alt_rounded, 'Tasks'),
    _NavItem('/meetings', Icons.event_rounded, 'Meetings'),
    _NavItem('/team', Icons.groups_rounded, 'Team'),
    _NavItem('/activity', Icons.timeline_rounded, 'Feed'),
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;
    final selected = _indexForLocation(location);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              extended: MediaQuery.sizeOf(context).width >= 900,
              labelType: MediaQuery.sizeOf(context).width >= 900
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.hub_rounded,
                        size: 36, color: Theme.of(context).colorScheme.primary),
                    if (MediaQuery.sizeOf(context).width >= 900) ...[
                      const SizedBox(height: 8),
                      Text('Krmaazha',
                          style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ],
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          tooltip: 'Search',
                          onPressed: () => context.push('/search'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded),
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
      floatingActionButton: _fabForLocation(context, location),
    );
  }

  Widget? _fabForLocation(BuildContext context, String location) {
    if (location.startsWith('/tasks')) {
      return FloatingActionButton(
        onPressed: () => context.push('/tasks/new'),
        child: const Icon(Icons.add),
      );
    }
    if (location.startsWith('/meetings')) {
      return FloatingActionButton(
        onPressed: () => context.push('/meetings/new'),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
