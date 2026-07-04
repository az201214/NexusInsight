import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem('/dashboard', Icons.dashboard_rounded, 'Home'),
    _NavItem('/tasks', Icons.task_alt_rounded, 'Tasks'),
    _NavItem('/meetings/active-huddle/huddle', Icons.video_call_rounded, 'Huddle Call'),
    _NavItem('/meetings', Icons.event_rounded, 'Meetings'),
    _NavItem('/team', Icons.groups_rounded, 'Team'),
    _NavItem('/activity', Icons.timeline_rounded, 'Feed'),
  ];

  static const _clientDestinations = [
    _NavItem('/dashboard', Icons.dashboard_rounded, 'Portal'),
    _NavItem('/tasks', Icons.task_alt_rounded, 'My Tasks'),
    _NavItem('/meetings/active-huddle/huddle', Icons.video_call_rounded, 'Huddle Call'),
    _NavItem('/meetings', Icons.event_rounded, 'Meetings'),
  ];

  int _indexForLocation(String location, List<_NavItem> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;
    
    final currentMember = ref.watch(currentMemberProvider).valueOrNull;
    final isClient = currentMember?.role == MemberRole.client;
    final destinations = isClient ? _clientDestinations : _destinations;
    final selected = _indexForLocation(location, destinations);

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
                    Icon(
                      isClient ? Icons.vpn_key_rounded : Icons.hub_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (MediaQuery.sizeOf(context).width >= 900) ...[
                      const SizedBox(height: 8),
                      Text(
                        isClient ? 'Client Portal' : 'Krmaazha',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ],
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
              onDestinationSelected: (i) => context.go(destinations[i].path),
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
                        if (!isClient)
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
    } else {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(destinations[i].path),
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
        floatingActionButton: _fabForLocation(context, location, isClient),
      );
    }
  }

  Widget? _fabForLocation(BuildContext context, String location, bool isClient) {
    if (isClient) return null;
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
