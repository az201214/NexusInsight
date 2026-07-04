import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/permissions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currentAsync = ref.watch(currentMemberProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (team) {
          if (team == null) return const SizedBox.shrink();
          return ListView(
            children: [
              ListTile(
                title: const Text('Team name'),
                subtitle: Text(team.name),
                trailing: Permissions.canChangeTeamName(currentAsync.valueOrNull)
                    ? IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _renameTeam(context, ref, team),
                      )
                    : null,
              ),
              const Divider(),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(themeMode.name),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!),
              ),
              const Divider(),
              settingsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (settings) {
                  if (settings == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notifications'),
                        value: settings.notificationsEnabled,
                        onChanged: (v) async {
                          await ref.read(teamRepositoryProvider).updateSettings(
                                settings.copyWith(notificationsEnabled: v),
                              );
                          refreshAll(ref);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Members can only self-assign tasks'),
                        value: settings.selfAssignOnly,
                        onChanged: Permissions.canChangeTeamName(currentAsync.valueOrNull)
                            ? (v) async {
                                await ref.read(teamRepositoryProvider).updateSettings(
                                      settings.copyWith(selfAssignOnly: v),
                                    );
                                refreshAll(ref);
                              }
                            : null,
                      ),
                      SwitchListTile(
                        title: const Text('App lock (PIN)'),
                        value: settings.lockEnabled,
                        onChanged: (v) async {
                          if (!v) {
                            await ref.read(teamRepositoryProvider).setPin(team.id, null);
                          } else {
                            await _setPin(context, ref, team.id);
                          }
                          refreshAll(ref);
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              if (Permissions.canExportBackup(currentAsync.valueOrNull))
                ListTile(
                  leading: const Icon(Icons.backup_rounded),
                  title: const Text('Export backup'),
                  subtitle: Text('.${AppConstants.backupExtension} file'),
                  onTap: () => _export(context, ref),
                ),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('Import backup'),
                onTap: () async {
                  await ref.read(backupRepositoryProvider).importFromPicker();
                  ref.read(unlockedProvider.notifier).state = true;
                  refreshAll(ref);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup restored')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi_rounded),
                title: const Text('LAN team sync'),
                subtitle: const Text('Same Wi‑Fi, no cloud'),
                onTap: () => context.push('/lan'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.developer_mode_rounded, color: Colors.purpleAccent),
                title: const Text('Portal Perspective Simulator'),
                subtitle: const Text('Switch simulated viewpoints for testing'),
                onTap: () => _showPerspectiveSimulator(context, ref, team.id),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('About'),
                subtitle: Text(AppConstants.appName),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Krmaazha Team Hub keeps your data on this device. '
                  'Export backups regularly.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _renameTeam(BuildContext context, WidgetRef ref, dynamic team) async {
    final ctrl = TextEditingController(text: team.name as String);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Team name'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(teamRepositoryProvider).updateTeam(team.copyWith(name: ctrl.text.trim()));
      refreshAll(ref);
    }
    ctrl.dispose();
  }

  Future<void> _setPin(BuildContext context, WidgetRef ref, String teamId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: '4–6 digits'),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await ref.read(teamRepositoryProvider).setPin(teamId, ctrl.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(backupRepositoryProvider).exportBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $path'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => ref.read(backupRepositoryProvider).shareBackup(path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _showPerspectiveSimulator(BuildContext context, WidgetRef ref, String teamId) async {
    final teamRepo = ref.read(teamRepositoryProvider);
    final db = await ref.read(databaseProvider).database;

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulate Portal Perspective',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a role perspective below to inspect the respective dashboards and permission restrictions.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _perspectiveTile(context, ref, db, teamRepo, teamId, MemberRole.head, 'Admin Head', Icons.admin_panel_settings_rounded),
              _perspectiveTile(context, ref, db, teamRepo, teamId, MemberRole.member, 'Employee/Member', Icons.person_rounded),
              _perspectiveTile(context, ref, db, teamRepo, teamId, MemberRole.client, 'B2B Client Partner', Icons.business_rounded),
            ],
          ),
        ),
      );
    }
  }

  Widget _perspectiveTile(
    BuildContext context,
    WidgetRef ref,
    dynamic db,
    dynamic teamRepo,
    String teamId,
    MemberRole role,
    String label,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: () async {
        final members = await teamRepo.getAllMembers(teamId);
        dynamic target;
        for (final m in members) {
          if (m.role == role) {
            target = m;
            break;
          }
        }

        if (target == null) {
          final id = UniqueKey().toString();
          final now = DateTime.now();
          String name = switch (role) {
            MemberRole.head => 'Web Admin',
            MemberRole.coLead => 'Demo Co-Lead',
            MemberRole.client => 'Demo Client',
            MemberRole.member => 'Demo Member',
          };
          await db.insert('members', {
            'id': id,
            'team_id': teamId,
            'name': name,
            'role': role.dbValue,
            'avatar_color': 0xFF2C3E7A,
            'is_active': 1,
            'joined_at': now.millisecondsSinceEpoch,
            'is_current_user': 0,
          });
          
          final updatedMembers = await teamRepo.getAllMembers(teamId);
          for (final m in updatedMembers) {
            if (m.role == role) {
              target = m;
              break;
            }
          }
        }

        if (target != null) {
          await teamRepo.setCurrentUser(target.id, teamId);
        }

        refreshAll(ref);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched view to $label')),
          );
        }
      },
    );
  }
}
