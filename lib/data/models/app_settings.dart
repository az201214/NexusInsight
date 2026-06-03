class AppSettings {
  const AppSettings({
    required this.teamId,
    this.pinHash,
    this.lockEnabled = false,
    this.notificationsEnabled = true,
    this.selfAssignOnly = false,
    this.onboardingDone = false,
    this.meetingReminderMinutes = 15,
  });

  final String teamId;
  final String? pinHash;
  final bool lockEnabled;
  final bool notificationsEnabled;
  final bool selfAssignOnly;
  final bool onboardingDone;
  final int meetingReminderMinutes;

  Map<String, dynamic> toMap() => {
        'team_id': teamId,
        'pin_hash': pinHash,
        'lock_enabled': lockEnabled ? 1 : 0,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'self_assign_only': selfAssignOnly ? 1 : 0,
        'onboarding_done': onboardingDone ? 1 : 0,
        'meeting_reminder_minutes': meetingReminderMinutes,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        teamId: m['team_id'] as String,
        pinHash: m['pin_hash'] as String?,
        lockEnabled: (m['lock_enabled'] as int? ?? 0) == 1,
        notificationsEnabled: (m['notifications_enabled'] as int? ?? 1) == 1,
        selfAssignOnly: (m['self_assign_only'] as int? ?? 0) == 1,
        onboardingDone: (m['onboarding_done'] as int? ?? 0) == 1,
        meetingReminderMinutes: m['meeting_reminder_minutes'] as int? ?? 15,
      );

  AppSettings copyWith({
    String? pinHash,
    bool? lockEnabled,
    bool? notificationsEnabled,
    bool? selfAssignOnly,
    bool? onboardingDone,
    int? meetingReminderMinutes,
    bool clearPin = false,
  }) =>
      AppSettings(
        teamId: teamId,
        pinHash: clearPin ? null : (pinHash ?? this.pinHash),
        lockEnabled: lockEnabled ?? this.lockEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        selfAssignOnly: selfAssignOnly ?? this.selfAssignOnly,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        meetingReminderMinutes:
            meetingReminderMinutes ?? this.meetingReminderMinutes,
      );
}
