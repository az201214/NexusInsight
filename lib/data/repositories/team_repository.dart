import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../database/app_database.dart';
import '../models/activity_log.dart';
import '../models/app_settings.dart';
import '../models/member.dart';
import '../models/team.dart';

const _uuid = Uuid();

class TeamRepository {
  TeamRepository(this._db);
  final AppDatabase _db;

  Future<bool> hasTeam() async {
    final db = await _db.database;
    final r = await db.query('teams', limit: 1);
    return r.isNotEmpty;
  }

  Future<Team?> getTeam() async {
    final db = await _db.database;
    final r = await db.query('teams', limit: 1);
    if (r.isEmpty) return null;
    return Team.fromMap(r.first);
  }

  Future<AppSettings?> getSettings(String teamId) async {
    final db = await _db.database;
    final r = await db.query('app_settings', where: 'team_id = ?', whereArgs: [teamId]);
    if (r.isEmpty) return null;
    return AppSettings.fromMap(r.first);
  }

  Future<Member?> getCurrentMember() async {
    final db = await _db.database;
    final r = await db.query('members', where: 'is_current_user = 1', limit: 1);
    if (r.isEmpty) return null;
    return Member.fromMap(r.first);
  }

  Future<List<Member>> getActiveMembers(String teamId) async {
    final db = await _db.database;
    final r = await db.query(
      'members',
      where: 'team_id = ? AND is_active = 1',
      whereArgs: [teamId],
      orderBy: 'joined_at ASC',
    );
    return r.map(Member.fromMap).toList();
  }

  Future<List<Member>> getAllMembers(String teamId) async {
    final db = await _db.database;
    final r = await db.query(
      'members',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'is_active DESC, joined_at ASC',
    );
    return r.map(Member.fromMap).toList();
  }

  Future<Member?> getMemberById(String id) async {
    final db = await _db.database;
    final r = await db.query('members', where: 'id = ?', whereArgs: [id], limit: 1);
    if (r.isEmpty) return null;
    return Member.fromMap(r.first);
  }

  Future<void> createTeam({
    required String teamName,
    required String headName,
    String? pin,
  }) async {
    final db = await _db.database;
    final teamId = _uuid.v4();
    final headId = _uuid.v4();
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.insert('teams', {
        'id': teamId,
        'name': teamName,
        'created_at': now.millisecondsSinceEpoch,
        'theme_mode': 'system',
      });
      await txn.insert('members', {
        'id': headId,
        'team_id': teamId,
        'name': headName,
        'role': MemberRole.head.dbValue,
        'avatar_color': 0xFF0D7377,
        'is_active': 1,
        'joined_at': now.millisecondsSinceEpoch,
        'is_current_user': 1,
      });
      await txn.insert('app_settings', {
        'team_id': teamId,
        'pin_hash': pin != null && pin.isNotEmpty ? _hashPin(pin) : null,
        'lock_enabled': pin != null && pin.isNotEmpty ? 1 : 0,
        'notifications_enabled': 1,
        'self_assign_only': 0,
        'onboarding_done': 0,
        'meeting_reminder_minutes': 15,
      });
      await txn.insert('activity_logs', {
        'id': _uuid.v4(),
        'team_id': teamId,
        'type': ActivityType.teamCreated.name,
        'reference_id': teamId,
        'message': 'Team "$teamName" created',
        'created_at': now.millisecondsSinceEpoch,
        'actor_id': headId,
      });
    });
  }

  Future<void> addMember({
    required String teamId,
    required String name,
    required MemberRole role,
    required String actorId,
    String? email,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final colors = [0xFF0D7377, 0xFFFF6B6B, 0xFF2C3E7A, 0xFFE9C46A, 0xFF9B5DE5];
    final color = colors[now.millisecond % colors.length];

    await db.insert('members', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'role': role.dbValue,
      'avatar_color': color,
      'is_active': 1,
      'joined_at': now.millisecondsSinceEpoch,
      'is_current_user': 0,
      'email': email,
    });
    await logActivity(
      teamId: teamId,
      type: ActivityType.memberAdded,
      message: '$name joined as ${role.label}',
      referenceId: id,
      actorId: actorId,
    );
  }

  Future<void> archiveMember({
    required String memberId,
    required String actorId,
    required String teamId,
  }) async {
    final db = await _db.database;
    final member = await getMemberById(memberId);
    if (member == null) return;
    await db.update('members', {'is_active': 0},
        where: 'id = ?', whereArgs: [memberId]);
    await logActivity(
      teamId: teamId,
      type: ActivityType.memberRemoved,
      message: '${member.name} was removed from active team',
      referenceId: memberId,
      actorId: actorId,
    );
  }

  Future<void> updateMember(Member member, {String? actorId, String? teamId}) async {
    final db = await _db.database;
    await db.update('members', member.toMap(), where: 'id = ?', whereArgs: [member.id]);
    if (teamId != null) {
      await logActivity(
        teamId: teamId,
        type: ActivityType.memberUpdated,
        message: '${member.name} profile updated',
        referenceId: member.id,
        actorId: actorId,
      );
    }
  }

  Future<void> setCurrentUser(String memberId, String teamId) async {
    final db = await _db.database;
    await db.update('members', {'is_current_user': 0},
        where: 'team_id = ?', whereArgs: [teamId]);
    await db.update('members', {'is_current_user': 1},
        where: 'id = ?', whereArgs: [memberId]);
  }

  Future<void> promoteToHead(String memberId, String teamId) async {
    final db = await _db.database;
    final members = await getAllMembers(teamId);
    await db.transaction((txn) async {
      for (final m in members) {
        if (m.role == MemberRole.head) {
          await txn.update(
            'members',
            {'role': MemberRole.coLead.dbValue},
            where: 'id = ?',
            whereArgs: [m.id],
          );
        }
      }
      await txn.update(
        'members',
        {'role': MemberRole.head.dbValue, 'is_current_user': 1},
        where: 'id = ?',
        whereArgs: [memberId],
      );
      await txn.update('members', {'is_current_user': 0},
          where: 'team_id = ? AND id != ?', whereArgs: [teamId, memberId]);
    });
  }

  Future<void> updateTeam(Team team) async {
    final db = await _db.database;
    await db.update('teams', team.toMap(), where: 'id = ?', whereArgs: [team.id]);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await _db.database;
    await db.insert('app_settings', settings.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> completeOnboarding(String teamId) async {
    final settings = await getSettings(teamId);
    if (settings == null) return;
    await updateSettings(settings.copyWith(onboardingDone: true));
  }

  Future<bool> verifyPin(String teamId, String pin) async {
    final settings = await getSettings(teamId);
    if (settings?.pinHash == null) return true;
    return settings!.pinHash == _hashPin(pin);
  }

  Future<void> setPin(String teamId, String? pin) async {
    final settings = await getSettings(teamId);
    if (settings == null) return;
    await updateSettings(settings.copyWith(
      pinHash: pin != null && pin.isNotEmpty ? _hashPin(pin) : null,
      lockEnabled: pin != null && pin.isNotEmpty,
      clearPin: pin == null || pin.isEmpty,
    ));
  }

  Future<void> logActivity({
    required String teamId,
    required ActivityType type,
    required String message,
    String? referenceId,
    String? actorId,
  }) async {
    final db = await _db.database;
    await db.insert('activity_logs', {
      'id': _uuid.v4(),
      'team_id': teamId,
      'type': type.name,
      'reference_id': referenceId,
      'message': message,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'actor_id': actorId,
    });
  }

  Future<List<ActivityLog>> getActivity(String teamId, {int limit = 50}) async {
    final db = await _db.database;
    final r = await db.query(
      'activity_logs',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return r.map(ActivityLog.fromMap).toList();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('krmaazha:$pin');
    return sha256.convert(bytes).toString();
  }
}
