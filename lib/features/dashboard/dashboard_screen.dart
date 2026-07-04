import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/member.dart';
import '../../data/models/task_item.dart';
import '../clients/client_dashboard_screen.dart';
import '../shared/widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final member = memberAsync.valueOrNull;
    if (member?.role == MemberRole.client) {
      return const ClientDashboardScreen();
    }

    final teamAsync = ref.watch(teamProvider);

    return teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (team) {
        if (team == null) return const SizedBox.shrink();
        return FutureBuilder(
          future: _loadDashboard(ref, team.id, memberAsync.valueOrNull),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Hey, ${data.currentMember?.name ?? 'there'} 👋',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatRow(
                        openTasks: data.openTasks,
                        overdue: data.overdue.length,
                        meetingsToday: data.meetingsToday.length,
                        members: data.memberCount,
                      ),
                      if (data.currentMember?.role == MemberRole.head || data.currentMember?.role == MemberRole.coLead) ...[
                        const SizedBox(height: 20),
                        _SectionTitle('Workspace Management'),
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showAddMemberModal(context, ref, data.currentMember, team.id),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_rounded),
                                        SizedBox(width: 8),
                                        Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showAddClientModal(context, ref, data.currentMember, team.id),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.business_rounded),
                                        SizedBox(width: 8),
                                        Text('Add B2B Client', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionTitle('Next meeting'),
                      if (data.nextMeeting == null)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.event_available_rounded),
                            title: Text('Nothing scheduled soon'),
                            subtitle: Text('You\'re all caught up'),
                          ),
                        )
                      else
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.event_rounded),
                            title: Text(data.nextMeeting!.title),
                            subtitle: Text(DateFormat.MMMd().add_jm()
                                .format(data.nextMeeting!.startAt)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context
                                .push('/meetings/${data.nextMeeting!.id}'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _SectionTitle('My tasks'),
                      if (data.myTasks.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text('No open tasks assigned to you'),
                          ),
                        )
                      else
                        ...data.myTasks.take(5).map(
                              (t) => _TaskTile(task: t, onTap: () => context.push('/tasks/${t.id}')),
                            ),
                      if (data.overdue.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SectionTitle('Overdue', color: Theme.of(context).colorScheme.error),
                        ...data.overdue.take(3).map(
                              (t) => _TaskTile(
                                task: t,
                                onTap: () => context.push('/tasks/${t.id}'),
                                urgent: true,
                              ),
                            ),
                      ],
                      const SizedBox(height: 20),
                      _SectionTitle('Recent activity'),
                      if (data.recentActivity.isEmpty)
                        const EmptyState(
                          icon: Icons.timeline_rounded,
                          title: 'Activity will show here',
                          subtitle: 'Task updates and meetings appear in the feed',
                        )
                      else
                        ...data.recentActivity.take(5).map(
                              (a) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.bolt_rounded, size: 20),
                                title: Text(a.message),
                                subtitle: Text(
                                  DateFormat.MMMd().add_jm().format(a.createdAt),
                                ),
                              ),
                            ),
                    ]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_DashboardData> _loadDashboard(
    WidgetRef ref,
    String teamId,
    Member? currentMember,
  ) async {
    final tasks = await ref.read(taskRepositoryProvider).getTasks(teamId);
    final openTasks = tasks.where((t) => t.status != TaskStatus.done).length;
    final overdue = await ref.read(taskRepositoryProvider).getOverdue(teamId);
    final upcoming =
        await ref.read(meetingRepositoryProvider).getUpcoming(teamId, limit: 1);
    final today = DateTime.now();
    final meetingsToday =
        await ref.read(meetingRepositoryProvider).getMeetingsOnDay(teamId, today);
    final members = await ref.read(teamRepositoryProvider).getActiveMembers(teamId);
    final myTasks = currentMember != null
        ? await ref.read(taskRepositoryProvider).getTasksForAssignee(teamId, currentMember.id)
        : <TaskItem>[];
    final activity = await ref.read(teamRepositoryProvider).getActivity(teamId, limit: 5);

    return _DashboardData(
      currentMember: currentMember,
      openTasks: openTasks,
      overdue: overdue,
      nextMeeting: upcoming.isNotEmpty ? upcoming.first : null,
      meetingsToday: meetingsToday,
      memberCount: members.length,
      myTasks: myTasks,
      recentActivity: activity,
    );
  }

  void _showAddMemberModal(BuildContext context, WidgetRef ref, Member? currentMember, String teamId) {
    final nameCtrl = TextEditingController();
    MemberRole role = MemberRole.member;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. John Doe',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MemberRole>(
              value: role,
              decoration: const InputDecoration(labelText: 'Role Selection'),
              items: const [
                DropdownMenuItem(value: MemberRole.coLead, child: Text('Co-Lead')),
                DropdownMenuItem(value: MemberRole.member, child: Text('Member')),
              ],
              onChanged: (v) {
                if (v != null) role = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ref.read(teamRepositoryProvider).addMember(
                    teamId: teamId,
                    name: nameCtrl.text.trim(),
                    role: role,
                    actorId: currentMember?.id ?? 'creator',
                  );
              refreshAll(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  void _showAddClientModal(BuildContext context, WidgetRef ref, Member? currentMember, String teamId) {
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    bool isBatchMode = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add B2B Client Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Single Client'), icon: Icon(Icons.person_add_rounded)),
                  ButtonSegment(value: true, label: Text('Batch Import'), icon: Icon(Icons.library_add_rounded)),
                ],
                selected: {isBatchMode},
                onSelectionChanged: (val) {
                  setStateDialog(() {
                    isBatchMode = val.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!isBatchMode) ...[
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client Company Name',
                    hintText: 'e.g. Acme Corp',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Main Contact Email',
                    hintText: 'e.g. contact@acme.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ] else ...[
                const Text(
                  'Enter clients (one per line):\nFormat: Company Name, Contact Email',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: batchCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'e.g.\nAcme Corp, contact@acme.com\nGlobex, info@globex.com',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final repo = ref.read(teamRepositoryProvider);
                final actorId = currentMember?.id ?? 'creator';
                
                if (isBatchMode) {
                  final lines = batchCtrl.text.split('\n');
                  int count = 0;
                  for (final line in lines) {
                    final trimmed = line.trim();
                    if (trimmed.isEmpty) continue;
                    final parts = trimmed.split(',');
                    final name = parts[0].trim();
                    final email = parts.length > 1 ? parts[1].trim() : null;
                    if (name.isNotEmpty) {
                      await repo.addMember(
                        teamId: teamId,
                        name: name,
                        role: MemberRole.client,
                        actorId: actorId,
                        email: email,
                      );
                      count++;
                    }
                  }
                  if (context.mounted && count > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully imported $count B2B client profiles.')),
                    );
                  }
                } else {
                  if (companyCtrl.text.trim().isEmpty) return;
                  await repo.addMember(
                    teamId: teamId,
                    name: companyCtrl.text.trim(),
                    role: MemberRole.client,
                    actorId: actorId,
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully created B2B client profile.')),
                    );
                  }
                }
                
                refreshAll(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isBatchMode ? 'Import All' : 'Add Client'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.currentMember,
    required this.openTasks,
    required this.overdue,
    required this.nextMeeting,
    required this.meetingsToday,
    required this.memberCount,
    required this.myTasks,
    required this.recentActivity,
  });

  final Member? currentMember;
  final int openTasks;
  final List<TaskItem> overdue;
  final dynamic nextMeeting;
  final List<dynamic> meetingsToday;
  final int memberCount;
  final List<TaskItem> myTasks;
  final List<dynamic> recentActivity;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.openTasks,
    required this.overdue,
    required this.meetingsToday,
    required this.members,
  });

  final int openTasks;
  final int overdue;
  final int meetingsToday;
  final int members;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard('Tasks', '$openTasks', Icons.task_alt_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Overdue', '$overdue', Icons.warning_amber_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Today', '$meetingsToday', Icons.event_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('Team', '$members', Icons.groups_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap, this.urgent = false});
  final TaskItem task;
  final VoidCallback onTap;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          urgent ? Icons.priority_high_rounded : Icons.circle_outlined,
          color: urgent ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(task.title),
        subtitle: Text(task.priority.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
