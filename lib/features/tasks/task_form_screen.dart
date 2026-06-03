import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/permissions.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/task_item.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  TaskPriority _priority = TaskPriority.normal;
  TaskStatus _status = TaskStatus.todo;
  String? _assigneeId;
  DateTime? _dueAt;
  bool _loading = true;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.taskId == null) {
      setState(() => _loading = false);
      return;
    }
    final task = await ref.read(taskRepositoryProvider).getTask(widget.taskId!);
    if (task != null) {
      _title.text = task.title;
      _desc.text = task.description ?? '';
      _priority = task.priority;
      _status = task.status;
      _assigneeId = task.assigneeId;
      _dueAt = task.dueAt;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final team = await ref.read(teamProvider.future);
    final current = await ref.read(currentMemberProvider.future);
    final settings = team != null
        ? await ref.read(teamRepositoryProvider).getSettings(team.id)
        : null;
    if (team == null || current == null || _title.text.trim().isEmpty) return;

    final assignee = _assigneeId != null
        ? await ref.read(teamRepositoryProvider).getMemberById(_assigneeId!)
        : null;
    if (_assigneeId != null &&
        !Permissions.canAssignTaskTo(
          current,
          assignee,
          selfAssignOnly: settings?.selfAssignOnly ?? false,
        )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot assign to this member')),
        );
      }
      return;
    }

    final repo = ref.read(taskRepositoryProvider);
    if (widget.taskId == null) {
      final id = await repo.createTask(
        teamId: team.id,
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        assigneeId: _assigneeId,
        priority: _priority,
        dueAt: _dueAt,
        createdBy: current.id,
        actorId: current.id,
      );
      final task = await repo.getTask(id);
      if (task?.dueAt != null) {
        await ref.read(taskRepositoryProvider);
      }
      refreshAll(ref);
      if (mounted) context.pop();
    } else {
      final existing = await repo.getTask(widget.taskId!);
      if (existing == null) return;
      await repo.updateTask(
        existing.copyWith(
          title: _title.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          assigneeId: _assigneeId,
          priority: _priority,
          status: _status,
          dueAt: _dueAt,
          clearDueAt: _dueAt == null,
        ),
        actorId: current.id,
      );
      refreshAll(ref);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskId == null ? 'New task' : 'Edit task'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) => DropdownButtonFormField<String?>(
              value: _assigneeId,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                for (final m in members)
                  DropdownMenuItem(value: m.id, child: Text(m.name)),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: TaskPriority.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? TaskPriority.normal),
          ),
          if (widget.taskId != null) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? TaskStatus.todo),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Text(_dueAt == null
                ? 'None'
                : MaterialLocalizations.of(context).formatMediumDate(_dueAt!)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_rounded),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dueAt ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) setState(() => _dueAt = d);
              },
            ),
          ),
          if (_dueAt != null)
            TextButton(onPressed: () => setState(() => _dueAt = null), child: const Text('Clear due date')),
        ],
      ),
    );
  }
}
