import 'constants.dart';
import '../data/models/member.dart';

class Permissions {
  static bool canAddMembers(Member? actor) =>
      actor != null && (actor.role == MemberRole.head || actor.role == MemberRole.coLead);

  static bool canRemoveMembers(Member? actor) =>
      actor != null && actor.role == MemberRole.head;

  static bool canAssignTaskTo(Member? actor, Member? assignee, {required bool selfAssignOnly}) {
    if (actor == null) return false;
    if (actor.role == MemberRole.head || actor.role == MemberRole.coLead) return true;
    if (selfAssignOnly) return assignee?.id == actor.id;
    return assignee?.id == actor.id;
  }

  static bool canCreateMeeting(Member? actor) =>
      actor != null && (actor.role == MemberRole.head || actor.role == MemberRole.coLead);

  static bool canMarkTaskDone(Member? actor, String? assigneeId) {
    if (actor == null) return false;
    if (actor.role == MemberRole.head || actor.role == MemberRole.coLead) return true;
    return assigneeId == actor.id;
  }

  static bool canExportBackup(Member? actor) =>
      actor != null && actor.role == MemberRole.head;

  static bool canChangeTeamName(Member? actor) =>
      actor != null && actor.role == MemberRole.head;

  static bool canPromoteHead(Member? actor) =>
      actor != null && actor.role == MemberRole.head;
}
