import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/permissions.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/member.dart';
import '../../data/models/task_item.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!;
        final task = data.task;
        if (task == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Task not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/tasks/${task.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(task.status.label)),
                  Chip(label: Text(task.priority.label)),
                  if (task.dueAt != null)
                    Chip(
                      label: Text(DateFormat.yMMMd().format(task.dueAt!)),
                      avatar: Icon(
                        task.isOverdue ? Icons.warning : Icons.schedule,
                        size: 16,
                      ),
                    ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(task.description!),
              ],
              const SizedBox(height: 16),
              if (task.status != TaskStatus.done)
                FilledButton.icon(
                  onPressed: () => _complete(task, data.current),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark done'),
                ),
              const Divider(height: 32),
              Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
              ...data.checklist.map((c) => CheckboxListTile(
                    value: c.isDone,
                    title: Text(c.title),
                    onChanged: (_) async {
                      await ref.read(taskRepositoryProvider).toggleChecklistItem(
                            TaskChecklistItem(
                              id: c.id,
                              taskId: c.taskId,
                              title: c.title,
                              isDone: !c.isDone,
                              sortOrder: c.sortOrder,
                            ),
                          );
                      setState(() {});
                    },
                  )),
              TextButton.icon(
                onPressed: () => _addChecklistItem(task.id),
                icon: const Icon(Icons.add),
                label: const Text('Add checklist item'),
              ),
              const Divider(height: 32),
              Text('Comments', style: Theme.of(context).textTheme.titleMedium),
              ...data.comments.map((c) {
                final author = data.memberNames[c.memberId] ?? 'Member';
                return ListTile(
                  title: Text(author),
                  subtitle: Text(c.body),
                );
              }),
              TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  hintText: 'Add a comment',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () => _addComment(task, data.current),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_TaskDetailData> _load() async {
    final task = await ref.read(taskRepositoryProvider).getTask(widget.taskId);
    final checklist = await ref.read(taskRepositoryProvider).getChecklist(widget.taskId);
    final comments = await ref.read(taskRepositoryProvider).getComments(widget.taskId);
    final current = await ref.read(currentMemberProvider.future);
    final members = await ref.read(membersProvider.future);
    final names = {for (final m in members) m.id as String: m.name as String};
    return _TaskDetailData(task: task, checklist: checklist, comments: comments, current: current, memberNames: names);
  }

  Future<void> _complete(TaskItem task, Member? current) async {
    if (current == null) return;
    if (!Permissions.canMarkTaskDone(current, task.assigneeId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot complete this task')),
      );
      return;
    }
    await ref.read(taskRepositoryProvider).completeTask(
          task,
          actorId: current.id,
          memberName: current.name,
        );
    refreshAll(ref);
    setState(() {});
  }

  Future<void> _addComment(TaskItem task, Member? current) async {
    if (current == null || _commentCtrl.text.trim().isEmpty) return;
    final team = await ref.read(teamProvider.future);
    if (team == null) return;
    await ref.read(taskRepositoryProvider).addComment(
          taskId: task.id,
          memberId: current.id,
          body: _commentCtrl.text.trim(),
          teamId: team.id,
          actorId: current.id,
          memberName: current.name,
        );
    _commentCtrl.clear();
    setState(() {});
  }

  Future<void> _addChecklistItem(String taskId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checklist item'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final items = await ref.read(taskRepositoryProvider).getChecklist(taskId);
      await ref.read(taskRepositoryProvider).addChecklistItem(taskId, ctrl.text.trim(), items.length);
      setState(() {});
    }
    ctrl.dispose();
  }
}

class _TaskDetailData {
  _TaskDetailData({
    required this.task,
    required this.checklist,
    required this.comments,
    required this.current,
    required this.memberNames,
  });

  final TaskItem? task;
  final List<TaskChecklistItem> checklist;
  final List<TaskComment> comments;
  final Member? current;
  final Map<String, String> memberNames;
}
