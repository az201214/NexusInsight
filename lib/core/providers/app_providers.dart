import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/member.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../lan/lan_sync_service.dart';
import '../../data/models/shared_file.dart';
import '../../data/models/meeting.dart';
import '../../data/repositories/shared_file_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(databaseProvider));
});

final currentUserProvider = FutureProvider<SessionUser?>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(ref.watch(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider), ref.watch(teamRepositoryProvider));
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.watch(databaseProvider), ref.watch(teamRepositoryProvider));
});

final sharedFileRepositoryProvider = Provider<SharedFileRepository>((ref) {
  return SharedFileRepository(ref.watch(databaseProvider));
});

final clientMeetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  final team = await ref.watch(teamProvider.future);
  if (team == null) return [];
  return ref.watch(meetingRepositoryProvider).getMeetings(team.id);
});

final clientFilesProvider = FutureProvider<List<SharedFile>>((ref) async {
  final team = await ref.watch(teamProvider.future);
  if (team == null) return [];
  return ref.watch(sharedFileRepositoryProvider).getFiles(team.id);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref.watch(databaseProvider), ref.watch(teamRepositoryProvider));
});

final lanSyncServiceProvider = Provider<LanSyncService>((ref) {
  return LanSyncService(ref.watch(databaseProvider));
});

final hasTeamProvider = FutureProvider<bool>((ref) async {
  return ref.watch(teamRepositoryProvider).hasTeam();
});

final teamProvider = FutureProvider((ref) async {
  return ref.watch(teamRepositoryProvider).getTeam();
});

final currentMemberProvider = FutureProvider((ref) async {
  return ref.watch(teamRepositoryProvider).getCurrentMember();
});

final settingsProvider = FutureProvider((ref) async {
  final team = await ref.watch(teamProvider.future);
  if (team == null) return null;
  return ref.watch(teamRepositoryProvider).getSettings(team.id);
});

final membersProvider = FutureProvider<List<Member>>((ref) async {
  final team = await ref.watch(teamProvider.future);
  if (team == null) return [];
  return ref.watch(teamRepositoryProvider).getActiveMembers(team.id);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _load();
  }
  final Ref _ref;

  Future<void> _load() async {
    final team = await _ref.read(teamProvider.future);
    if (team == null) return;
    state = switch (team.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final team = await _ref.read(teamProvider.future);
    if (team == null) return;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _ref.read(teamRepositoryProvider).updateTeam(team.copyWith(themeMode: value));
    _ref.invalidate(teamProvider);
  }
}

final refreshTriggerProvider = StateProvider<int>((ref) => 0);

void refreshAll(WidgetRef ref) {
  ref.read(refreshTriggerProvider.notifier).state++;
  ref.invalidate(currentUserProvider);
  ref.invalidate(hasTeamProvider);
  ref.invalidate(teamProvider);
  ref.invalidate(currentMemberProvider);
  ref.invalidate(settingsProvider);
  ref.invalidate(membersProvider);
}
