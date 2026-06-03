import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/task_item.dart';
import '../shared/widgets/empty_state.dart';

enum _TaskFilter { all, mine, done }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider);
    final currentAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<_TaskFilter>(
              segments: const [
                ButtonSegment(value: _TaskFilter.all, label: Text('All')),
                ButtonSegment(value: _TaskFilter.mine, label: Text('Mine')),
                ButtonSegment(value: _TaskFilter.done, label: Text('Done')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
        ),
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (team) {
          if (team == null) return const SizedBox.shrink();
          return FutureBuilder<List<TaskItem>>(
            future: _load(ref, team.id, currentAsync.valueOrNull?.id),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snap.data!;
              if (tasks.isEmpty) {
                return EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'No tasks here',
                  subtitle: 'Tap + to create your first task',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/tasks/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('New task'),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, i) {
                  final t = tasks[i];
                  return Dismissible(
                    key: ValueKey(t.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.check_rounded),
                    ),
                    confirmDismiss: (_) async {
                      final current = await ref.read(currentMemberProvider.future);
                      if (current == null || t.status == TaskStatus.done) return false;
                      await ref.read(taskRepositoryProvider).completeTask(
                            t,
                            actorId: current.id,
                            memberName: current.name,
                          );
                      refreshAll(ref);
                      setState(() {});
                      return false;
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: _PriorityDot(priority: t.priority, done: t.status == TaskStatus.done),
                        title: Text(
                          t.title,
                          style: t.status == TaskStatus.done
                              ? const TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        subtitle: Text('${t.status.label} · ${t.priority.label}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/tasks/${t.id}'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<TaskItem>> _load(WidgetRef ref, String teamId, String? memberId) async {
    final repo = ref.read(taskRepositoryProvider);
    switch (_filter) {
      case _TaskFilter.done:
        return repo.getTasks(teamId, status: TaskStatus.done);
      case _TaskFilter.mine:
        if (memberId == null) return [];
        final all = await repo.getTasks(teamId);
        return all.where((t) => t.assigneeId == memberId).toList();
      case _TaskFilter.all:
        return repo.getTasks(teamId);
    }
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority, required this.done});
  final TaskPriority priority;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Colors.grey
        : switch (priority) {
            TaskPriority.urgent => Colors.red,
            TaskPriority.normal => Theme.of(context).colorScheme.primary,
            TaskPriority.low => Colors.blueGrey,
          };
    return CircleAvatar(radius: 8, backgroundColor: color);
  }
}
