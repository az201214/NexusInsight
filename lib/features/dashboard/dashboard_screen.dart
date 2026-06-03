import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/member.dart';
import '../../data/models/task_item.dart';
import '../shared/widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final memberAsync = ref.watch(currentMemberProvider);

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
