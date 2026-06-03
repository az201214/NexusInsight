import '../../core/constants.dart';

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.teamId,
    required this.type,
    this.referenceId,
    required this.message,
    required this.createdAt,
    this.actorId,
  });

  final String id;
  final String teamId;
  final ActivityType type;
  final String? referenceId;
  final String message;
  final DateTime createdAt;
  final String? actorId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'type': type.name,
        'reference_id': referenceId,
        'message': message,
        'created_at': createdAt.millisecondsSinceEpoch,
        'actor_id': actorId,
      };

  factory ActivityLog.fromMap(Map<String, dynamic> m) => ActivityLog(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        type: ActivityType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => ActivityType.settingsChanged,
        ),
        referenceId: m['reference_id'] as String?,
        message: m['message'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        actorId: m['actor_id'] as String?,
      );
}
