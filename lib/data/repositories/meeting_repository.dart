import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/notifications/notification_service.dart';
import '../database/app_database.dart';
import '../models/meeting.dart';

const _uuid = Uuid();

class MeetingRepository {
  MeetingRepository(this._db, this._teamRepo);
  final AppDatabase _db;
  final dynamic _teamRepo;

  Future<List<Meeting>> getMeetings(String teamId) async {
    final db = await _db.database;
    final r = await db.query('meetings',
        where: 'team_id = ?', whereArgs: [teamId], orderBy: 'start_at ASC');
    return r.map(Meeting.fromMap).toList();
  }

  Future<List<Meeting>> getMeetingsOnDay(String teamId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final db = await _db.database;
    final r = await db.query(
      'meetings',
      where: 'team_id = ? AND start_at >= ? AND start_at < ?',
      whereArgs: [teamId, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_at ASC',
    );
    return r.map(Meeting.fromMap).toList();
  }

  Future<List<Meeting>> getUpcoming(String teamId, {int limit = 5}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db.database;
    final r = await db.query(
      'meetings',
      where: 'team_id = ? AND end_at >= ?',
      whereArgs: [teamId, now],
      orderBy: 'start_at ASC',
      limit: limit,
    );
    return r.map(Meeting.fromMap).toList();
  }

  Future<Meeting?> getMeeting(String id) async {
    final db = await _db.database;
    final r = await db.query('meetings', where: 'id = ?', whereArgs: [id], limit: 1);
    if (r.isEmpty) return null;
    return Meeting.fromMap(r.first);
  }

  Future<List<String>> getAttendeeIds(String meetingId) async {
    final db = await _db.database;
    final r = await db.query('meeting_attendees',
        where: 'meeting_id = ?', whereArgs: [meetingId]);
    return r.map((e) => e['member_id'] as String).toList();
  }

  Future<List<Meeting>> search(String teamId, String query) async {
    if (query.trim().isEmpty) return getMeetings(teamId);
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final r = await db.query(
      'meetings',
      where: 'team_id = ? AND (title LIKE ? OR location LIKE ? OR notes LIKE ?)',
      whereArgs: [teamId, q, q, q],
      orderBy: 'start_at ASC',
    );
    return r.map(Meeting.fromMap).toList();
  }

  Future<String> createMeeting({
    required Meeting meeting,
    required List<String> attendeeIds,
    required String actorId,
    int reminderMinutes = 15,
    bool notificationsEnabled = true,
  }) async {
    final db = await _db.database;
    await db.insert('meetings', meeting.toMap());
    for (final mid in attendeeIds) {
      await db.insert('meeting_attendees', {
        'meeting_id': meeting.id,
        'member_id': mid,
      });
    }
    await _teamRepo.logActivity(
      teamId: meeting.teamId,
      type: ActivityType.meetingCreated,
      message: 'Meeting scheduled: ${meeting.title}',
      referenceId: meeting.id,
      actorId: actorId,
    );
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleMeetingReminder(
        meeting,
        minutesBefore: reminderMinutes,
      );
    }
    return meeting.id;
  }

  Future<void> updateMeeting({
    required Meeting meeting,
    required List<String> attendeeIds,
    required String actorId,
    int reminderMinutes = 15,
    bool notificationsEnabled = true,
  }) async {
    final db = await _db.database;
    await db.update('meetings', meeting.toMap(),
        where: 'id = ?', whereArgs: [meeting.id]);
    await db.delete('meeting_attendees',
        where: 'meeting_id = ?', whereArgs: [meeting.id]);
    for (final mid in attendeeIds) {
      await db.insert('meeting_attendees', {
        'meeting_id': meeting.id,
        'member_id': mid,
      });
    }
    await _teamRepo.logActivity(
      teamId: meeting.teamId,
      type: ActivityType.meetingUpdated,
      message: 'Meeting updated: ${meeting.title}',
      referenceId: meeting.id,
      actorId: actorId,
    );
    await NotificationService.instance.cancelMeetingReminder(meeting.id);
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleMeetingReminder(
        meeting,
        minutesBefore: reminderMinutes,
      );
    }
  }

  Future<void> deleteMeeting(String id, String teamId, String actorId) async {
    final db = await _db.database;
    await NotificationService.instance.cancelMeetingReminder(id);
    await db.delete('meeting_attendees', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
    await _teamRepo.logActivity(
      teamId: teamId,
      type: ActivityType.meetingUpdated,
      message: 'Meeting cancelled',
      referenceId: id,
      actorId: actorId,
    );
  }
}
