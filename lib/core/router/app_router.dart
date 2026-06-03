import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_screen.dart';
import '../../features/auth/lock_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/setup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/meetings/meeting_detail_screen.dart';
import '../../features/meetings/meeting_form_screen.dart';
import '../../features/meetings/meetings_screen.dart';
import '../../features/members/members_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/lan_sync_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tasks/task_detail_screen.dart';
import '../../features/tasks/task_form_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../providers/app_providers.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(refreshTriggerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref, refresh),
    redirect: (context, state) async {
      final hasTeam = await ref.read(hasTeamProvider.future);
      final path = state.matchedLocation;

      if (!hasTeam) {
        if (path == '/setup' || path == '/onboarding') return null;
        return '/onboarding';
      }

      final team = await ref.read(teamProvider.future);
      final settings = team != null
          ? await ref.read(teamRepositoryProvider).getSettings(team.id)
          : null;

      if (settings != null &&
          !settings.onboardingDone &&
          path != '/setup' &&
          path != '/onboarding') {
        return '/setup';
      }

      if (settings?.lockEnabled == true && path != '/lock') {
        final unlocked = ref.read(unlockedProvider);
        if (!unlocked) return '/lock';
      }

      if (path == '/onboarding' || path == '/setup' || path == '/lock') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
          GoRoute(
            path: '/tasks/new',
            builder: (_, __) => const TaskFormScreen(),
          ),
          GoRoute(
            path: '/tasks/:id',
            builder: (_, s) => TaskDetailScreen(taskId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/tasks/:id/edit',
            builder: (_, s) => TaskFormScreen(taskId: s.pathParameters['id']),
          ),
          GoRoute(path: '/meetings', builder: (_, __) => const MeetingsScreen()),
          GoRoute(
            path: '/meetings/new',
            builder: (_, __) => const MeetingFormScreen(),
          ),
          GoRoute(
            path: '/meetings/:id',
            builder: (_, s) =>
                MeetingDetailScreen(meetingId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/meetings/:id/edit',
            builder: (_, s) =>
                MeetingFormScreen(meetingId: s.pathParameters['id']),
          ),
          GoRoute(path: '/team', builder: (_, __) => const MembersScreen()),
          GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/lan', builder: (_, __) => const LanSyncScreen()),
        ],
      ),
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
    ],
  );
});

final unlockedProvider = StateProvider<bool>((ref) => false);

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref, this._tick);
  final Ref _ref;
  final int _tick;

  @override
  void addListener(VoidCallback listener) {
    _ref.listen(refreshTriggerProvider, (_, __) => listener());
  }

  @override
  void removeListener(VoidCallback listener) {}
}
