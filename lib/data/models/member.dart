import '../../core/constants.dart';

class Member {
  const Member({
    required this.id,
    required this.teamId,
    required this.name,
    required this.role,
    required this.avatarColor,
    required this.isActive,
    required this.joinedAt,
    this.isCurrentUser = false,
  });

  final String id;
  final String teamId;
  final String name;
  final MemberRole role;
  final int avatarColor;
  final bool isActive;
  final DateTime joinedAt;
  final bool isCurrentUser;

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'role': role.dbValue,
        'avatar_color': avatarColor,
        'is_active': isActive ? 1 : 0,
        'joined_at': joinedAt.millisecondsSinceEpoch,
        'is_current_user': isCurrentUser ? 1 : 0,
      };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        name: m['name'] as String,
        role: MemberRoleX.fromDb(m['role'] as String),
        avatarColor: m['avatar_color'] as int,
        isActive: (m['is_active'] as int) == 1,
        joinedAt: DateTime.fromMillisecondsSinceEpoch(m['joined_at'] as int),
        isCurrentUser: (m['is_current_user'] as int? ?? 0) == 1,
      );

  Member copyWith({
    String? name,
    MemberRole? role,
    bool? isActive,
    bool? isCurrentUser,
  }) =>
      Member(
        id: id,
        teamId: teamId,
        name: name ?? this.name,
        role: role ?? this.role,
        avatarColor: avatarColor,
        isActive: isActive ?? this.isActive,
        joinedAt: joinedAt,
        isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      );
}
