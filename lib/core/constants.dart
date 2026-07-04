class AppConstants {
  static const appName = 'Krmaazha Team Hub';
  static const backupExtension = 'krmaazha';
  static const dbName = 'krmaazha_hub.db';
  static const dbVersion = 3;
  static const desktopBreakpoint = 600.0;
  static const defaultMeetingReminderMinutes = 15;
}

enum MemberRole { head, coLead, member, client }

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, normal, urgent }

enum ActivityType {
  teamCreated,
  memberAdded,
  memberRemoved,
  memberUpdated,
  taskCreated,
  taskUpdated,
  taskCompleted,
  taskComment,
  meetingCreated,
  meetingUpdated,
  backupExported,
  backupImported,
  settingsChanged,
}

extension MemberRoleX on MemberRole {
  String get label => switch (this) {
        MemberRole.head => 'Team Head',
        MemberRole.coLead => 'Co-lead',
        MemberRole.member => 'Member',
        MemberRole.client => 'Client Partner',
      };

  String get dbValue => switch (this) {
        MemberRole.coLead => 'co_lead',
        MemberRole.client => 'client',
        _ => name,
      };

  static MemberRole fromDb(String v) => switch (v) {
        'head' => MemberRole.head,
        'co_lead' => MemberRole.coLead,
        'client' => MemberRole.client,
        _ => MemberRole.member,
      };
}

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.todo => 'To do',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.done => 'Done',
      };

  String get dbValue => switch (this) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.done => 'done',
      };

  static TaskStatus fromDb(String v) => switch (v) {
        'in_progress' => TaskStatus.inProgress,
        'done' => TaskStatus.done,
        _ => TaskStatus.todo,
      };
}

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.normal => 'Normal',
        TaskPriority.urgent => 'Urgent',
      };

  String get dbValue => name;

  static TaskPriority fromDb(String v) =>
      TaskPriority.values.firstWhere((e) => e.name == v, orElse: () => TaskPriority.normal);
}
