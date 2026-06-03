import '../../core/constants.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.teamId,
    required this.title,
    this.description,
    this.assigneeId,
    required this.status,
    required this.priority,
    this.dueAt,
    required this.createdBy,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teamId;
  final String title;
  final String? description;
  final String? assigneeId;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final String createdBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue =>
      dueAt != null && status != TaskStatus.done && dueAt!.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'status': status.dbValue,
        'priority': priority.dbValue,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'created_by': createdBy,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        assigneeId: m['assignee_id'] as String?,
        status: TaskStatusX.fromDb(m['status'] as String),
        priority: TaskPriorityX.fromDb(m['priority'] as String),
        dueAt: m['due_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['due_at'] as int)
            : null,
        createdBy: m['created_by'] as String,
        completedAt: m['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int)
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  TaskItem copyWith({
    String? title,
    String? description,
    String? assigneeId,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) =>
      TaskItem(
        id: id,
        teamId: teamId,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeId: assigneeId ?? this.assigneeId,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
        createdBy: createdBy,
        completedAt:
            clearCompletedAt ? null : (completedAt ?? this.completedAt),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class TaskChecklistItem {
  const TaskChecklistItem({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.sortOrder,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final int sortOrder;

  Map<String, dynamic> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_done': isDone ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory TaskChecklistItem.fromMap(Map<String, dynamic> m) =>
      TaskChecklistItem(
        id: m['id'] as String,
        taskId: m['task_id'] as String,
        title: m['title'] as String,
        isDone: (m['is_done'] as int) == 1,
        sortOrder: m['sort_order'] as int,
      );
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.memberId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String memberId;
  final String body;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'task_id': taskId,
        'member_id': memberId,
        'body': body,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory TaskComment.fromMap(Map<String, dynamic> m) => TaskComment(
        id: m['id'] as String,
        taskId: m['task_id'] as String,
        memberId: m['member_id'] as String,
        body: m['body'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}
