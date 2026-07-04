import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/task_item.dart';
import '../shared/widgets/empty_state.dart';

enum _TaskFilter { all, mine }

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
        title: const Text('Status Board'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SegmentedButton<_TaskFilter>(
                  segments: const [
                    ButtonSegment(value: _TaskFilter.all, label: Text('All Tasks')),
                    ButtonSegment(value: _TaskFilter.mine, label: Text('My Tasks')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const Spacer(),
                if (currentAsync.valueOrNull?.role != MemberRole.client)
                  FilledButton.icon(
                    onPressed: () => context.push('/tasks/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Task'),
                  ),
              ],
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
                  title: 'No tasks found',
                  subtitle: 'Create a task to get started',
                  action: currentAsync.valueOrNull?.role != MemberRole.client
                      ? FilledButton.icon(
                          onPressed: () => context.push('/tasks/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('New task'),
                        )
                      : null,
                );
              }
              return _buildKanbanBoard(tasks, team.id, currentAsync.valueOrNull?.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildKanbanBoard(List<TaskItem> allTasks, String teamId, String? currentActorId) {
    final todoTasks = allTasks.where((t) => t.status == TaskStatus.todo).toList();
    final inProgressTasks = allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final doneTasks = allTasks.where((t) => t.status == TaskStatus.done).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn('To Do', todoTasks, TaskStatus.todo, teamId, currentActorId),
          const SizedBox(width: 16),
          _buildKanbanColumn('In Progress', inProgressTasks, TaskStatus.inProgress, teamId, currentActorId),
          const SizedBox(width: 16),
          _buildKanbanColumn('Done', doneTasks, TaskStatus.done, teamId, currentActorId),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<TaskItem> tasks,
    TaskStatus status,
    String teamId,
    String? currentActorId,
  ) {
    final theme = Theme.of(context);
    final headerColor = switch (status) {
      TaskStatus.todo => Colors.blueAccent,
      TaskStatus.inProgress => Colors.orangeAccent,
      TaskStatus.done => Colors.greenAccent,
    };

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: headerColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Task Cards List
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 120,
              maxHeight: MediaQuery.sizeOf(context).height - 240,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tasks.length,
              itemBuilder: (ctx, idx) {
                final task = tasks[idx];
                return _buildKanbanCard(task, currentActorId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(TaskItem task, String? currentActorId) {
    final theme = Theme.of(context);
    final priorityColor = switch (task.priority) {
      TaskPriority.urgent => Colors.red,
      TaskPriority.normal => theme.colorScheme.primary,
      TaskPriority.low => Colors.blueGrey,
    };

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.priority.label,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  PopupMenuButton<TaskStatus>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Change Status',
                    onSelected: (newStatus) async {
                      if (currentActorId == null) return;
                      final repo = ref.read(taskRepositoryProvider);
                      if (newStatus == TaskStatus.done) {
                        final current = await ref.read(currentMemberProvider.future);
                        await repo.completeTask(task, actorId: currentActorId, memberName: current?.name ?? 'Admin');
                      } else {
                        await repo.updateTask(task.copyWith(status: newStatus, completedAt: null), actorId: currentActorId);
                      }
                      refreshAll(ref);
                      setState(() {});
                    },
                    itemBuilder: (ctx) => [
                      if (task.status != TaskStatus.todo)
                        const PopupMenuItem(
                          value: TaskStatus.todo,
                          child: Text('Move to To Do'),
                        ),
                      if (task.status != TaskStatus.inProgress)
                        const PopupMenuItem(
                          value: TaskStatus.inProgress,
                          child: Text('Move to In Progress'),
                        ),
                      if (task.status != TaskStatus.done)
                        const PopupMenuItem(
                          value: TaskStatus.done,
                          child: Text('Move to Done'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    task.dueAt != null
                        ? DateFormat.yMMMd().format(task.dueAt!)
                        : 'No due date',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<TaskItem>> _load(WidgetRef ref, String teamId, String? memberId) async {
    final repo = ref.read(taskRepositoryProvider);
    final all = await repo.getTasks(teamId);
    if (_filter == _TaskFilter.mine) {
      if (memberId == null) return [];
      return all.where((t) => t.assigneeId == memberId).toList();
    }
    return all;
  }
}
