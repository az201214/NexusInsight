import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/notifications/notification_service.dart';
import '../database/app_database.dart';
import '../models/task_item.dart';

const _uuid = Uuid();

class TaskRepository {
  TaskRepository(this._db, this._teamRepo);
  final AppDatabase _db;
  final dynamic _teamRepo;

  Future<List<TaskItem>> getTasks(String teamId, {TaskStatus? status}) async {
    final db = await _db.database;
    var where = 'team_id = ?';
    final args = <Object>[teamId];
    if (status != null) {
      where += ' AND status = ?';
      args.add(status.dbValue);
    }
    final r = await db.query('tasks', where: where, whereArgs: args,
        orderBy: 'updated_at DESC');
    return r.map(TaskItem.fromMap).toList();
  }

  Future<List<TaskItem>> getTasksForAssignee(String teamId, String memberId) async {
    final db = await _db.database;
    final r = await db.query(
      'tasks',
      where: 'team_id = ? AND assignee_id = ? AND status != ?',
      whereArgs: [teamId, memberId, TaskStatus.done.dbValue],
      orderBy: 'due_at ASC',
    );
    return r.map(TaskItem.fromMap).toList();
  }

  Future<List<TaskItem>> getOverdue(String teamId) async {
    final all = await getTasks(teamId);
    return all.where((t) => t.isOverdue).toList();
  }

  Future<TaskItem?> getTask(String id) async {
    final db = await _db.database;
    final r = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (r.isEmpty) return null;
    return TaskItem.fromMap(r.first);
  }

  Future<List<TaskItem>> search(String teamId, String query) async {
    if (query.trim().isEmpty) return getTasks(teamId);
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final r = await db.query(
      'tasks',
      where: 'team_id = ? AND (title LIKE ? OR description LIKE ?)',
      whereArgs: [teamId, q, q],
      orderBy: 'updated_at DESC',
    );
    return r.map(TaskItem.fromMap).toList();
  }

  Future<String> createTask({
    required String teamId,
    required String title,
    String? description,
    String? assigneeId,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueAt,
    required String createdBy,
    required String actorId,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    await db.insert('tasks', {
      'id': id,
      'team_id': teamId,
      'title': title,
      'description': description,
      'assignee_id': assigneeId,
      'status': TaskStatus.todo.dbValue,
      'priority': priority.dbValue,
      'due_at': dueAt?.millisecondsSinceEpoch,
      'created_by': createdBy,
      'completed_at': null,
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });
    await _teamRepo.logActivity(
      teamId: teamId,
      type: ActivityType.taskCreated,
      message: 'Task created: $title',
      referenceId: id,
      actorId: actorId,
    );
    if (dueAt != null) {
      final task = await getTask(id);
      if (task != null) {
        await NotificationService.instance.scheduleTaskDueReminder(task);
      }
    }
    return id;
  }

  Future<void> updateTask(TaskItem task, {required String actorId}) async {
    final db = await _db.database;
    final updated = task.copyWith(updatedAt: DateTime.now());
    await db.update('tasks', updated.toMap(), where: 'id = ?', whereArgs: [task.id]);
    await _teamRepo.logActivity(
      teamId: task.teamId,
      type: ActivityType.taskUpdated,
      message: 'Task updated: ${task.title}',
      referenceId: task.id,
      actorId: actorId,
    );
  }

  Future<void> completeTask(TaskItem task, {required String actorId, required String memberName}) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      status: TaskStatus.done,
      completedAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.update('tasks', updated.toMap(), where: 'id = ?', whereArgs: [task.id]);
    await _teamRepo.logActivity(
      teamId: task.teamId,
      type: ActivityType.taskCompleted,
      message: '$memberName completed "${task.title}"',
      referenceId: task.id,
      actorId: actorId,
    );
  }

  Future<void> deleteTask(String id, String teamId, String actorId) async {
    final db = await _db.database;
    await db.delete('task_checklist', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('task_comments', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await _teamRepo.logActivity(
      teamId: teamId,
      type: ActivityType.taskUpdated,
      message: 'Task deleted',
      referenceId: id,
      actorId: actorId,
    );
  }

  Future<List<TaskChecklistItem>> getChecklist(String taskId) async {
    final db = await _db.database;
    final r = await db.query('task_checklist',
        where: 'task_id = ?', whereArgs: [taskId], orderBy: 'sort_order ASC');
    return r.map(TaskChecklistItem.fromMap).toList();
  }

  Future<void> addChecklistItem(String taskId, String title, int order) async {
    final db = await _db.database;
    await db.insert('task_checklist', {
      'id': _uuid.v4(),
      'task_id': taskId,
      'title': title,
      'is_done': 0,
      'sort_order': order,
    });
  }

  Future<void> toggleChecklistItem(TaskChecklistItem item) async {
    final db = await _db.database;
    await db.update(
      'task_checklist',
      {'is_done': item.isDone ? 0 : 1},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<TaskComment>> getComments(String taskId) async {
    final db = await _db.database;
    final r = await db.query('task_comments',
        where: 'task_id = ?', whereArgs: [taskId], orderBy: 'created_at ASC');
    return r.map(TaskComment.fromMap).toList();
  }

  Future<void> addComment({
    required String taskId,
    required String memberId,
    required String body,
    required String teamId,
    required String actorId,
    required String memberName,
  }) async {
    final db = await _db.database;
    await db.insert('task_comments', {
      'id': _uuid.v4(),
      'task_id': taskId,
      'member_id': memberId,
      'body': body,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _teamRepo.logActivity(
      teamId: teamId,
      type: ActivityType.taskComment,
      message: '$memberName commented on a task',
      referenceId: taskId,
      actorId: actorId,
    );
  }
}
