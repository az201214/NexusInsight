class Meeting {
  const Meeting({
    required this.id,
    required this.teamId,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.location,
    this.notes,
    this.agenda,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String teamId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final String? notes;
  final String? agenda;
  final String createdBy;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'title': title,
        'start_at': startAt.millisecondsSinceEpoch,
        'end_at': endAt.millisecondsSinceEpoch,
        'location': location,
        'notes': notes,
        'agenda': agenda,
        'created_by': createdBy,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Meeting.fromMap(Map<String, dynamic> m) => Meeting(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        title: m['title'] as String,
        startAt: DateTime.fromMillisecondsSinceEpoch(m['start_at'] as int),
        endAt: DateTime.fromMillisecondsSinceEpoch(m['end_at'] as int),
        location: m['location'] as String?,
        notes: m['notes'] as String?,
        agenda: m['agenda'] as String?,
        createdBy: m['created_by'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class MeetingAttendee {
  const MeetingAttendee({
    required this.meetingId,
    required this.memberId,
  });

  final String meetingId;
  final String memberId;

  Map<String, dynamic> toMap() => {
        'meeting_id': meetingId,
        'member_id': memberId,
      };

  factory MeetingAttendee.fromMap(Map<String, dynamic> m) => MeetingAttendee(
        meetingId: m['meeting_id'] as String,
        memberId: m['member_id'] as String,
      );
}
