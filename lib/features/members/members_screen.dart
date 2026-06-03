import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/permissions.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/member.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/member_avatar.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final membersAsync = ref.watch(membersProvider);
    final currentAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () async {
              final current = await ref.read(currentMemberProvider.future);
              if (!Permissions.canAddMembers(current)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot add members')),
                  );
                }
                return;
              }
              if (context.mounted) await _showAddMember(context, ref);
            },
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (team) {
          if (team == null) return const SizedBox.shrink();
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (members) {
              if (members.isEmpty) {
                return EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'No members yet',
                  subtitle: 'Add your first teammate',
                  action: FilledButton.icon(
                    onPressed: () => _showAddMember(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add member'),
                  ),
                );
              }
              return currentAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (current) => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, i) {
                    final m = members[i] as Member;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: MemberAvatar(name: m.name, colorValue: m.avatarColor),
                        title: Text(m.name),
                        subtitle: Text(m.role.label),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.isCurrentUser)
                              Chip(
                                label: const Text('You'),
                                visualDensity: VisualDensity.compact,
                              ),
                            PopupMenuButton<String>(
                              onSelected: (v) => _onMenu(context, ref, m, current, v, team.id),
                              itemBuilder: (_) => [
                                if (current?.id != m.id)
                                  const PopupMenuItem(
                                    value: 'switch',
                                    child: Text('Act as this member'),
                                  ),
                                if (Permissions.canRemoveMembers(current) && m.role != MemberRole.head)
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove from team'),
                                  ),
                                if (Permissions.canPromoteHead(current) && m.role != MemberRole.head)
                                  const PopupMenuItem(
                                    value: 'promote',
                                    child: Text('Make Team Head'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    Member member,
    Member? current,
    String action,
    String teamId,
  ) async {
    final repo = ref.read(teamRepositoryProvider);
    switch (action) {
      case 'switch':
        await repo.setCurrentUser(member.id, teamId);
        refreshAll(ref);
        break;
      case 'remove':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove member?'),
            content: Text('${member.name} will be archived.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
            ],
          ),
        );
        if (confirm == true) {
          await repo.archiveMember(
            memberId: member.id,
            actorId: current!.id,
            teamId: teamId,
          );
          refreshAll(ref);
        }
        break;
      case 'promote':
        await repo.promoteToHead(member.id, teamId);
        refreshAll(ref);
        break;
    }
  }

  Future<void> _showAddMember(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    var role = MemberRole.member;
    final team = await ref.read(teamProvider.future);
    final current = await ref.read(currentMemberProvider.future);
    if (team == null || current == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add member', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MemberRole>(
              value: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: MemberRole.values
                  .where((r) => r != MemberRole.head || current.role == MemberRole.head)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => role = v ?? MemberRole.member,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(teamRepositoryProvider).addMember(
                      teamId: team.id,
                      name: nameCtrl.text.trim(),
                      role: role == MemberRole.head ? MemberRole.member : role,
                      actorId: current.id,
                    );
                refreshAll(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }
}
