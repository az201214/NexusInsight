import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/meeting.dart';
import '../../data/models/task_item.dart';
import '../constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(
      android: android,
    );
    await _plugin.initialize(init);
    _ready = true;
  }

  Future<void> scheduleMeetingReminder(Meeting meeting,
      {int minutesBefore = 15}) async {
    if (!_ready || kIsWeb) return;
    final when = meeting.startAt.subtract(Duration(minutes: minutesBefore));
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        meeting.id.hashCode,
        'Meeting soon',
        '${meeting.title} starts in $minutesBefore min',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meetings',
            'Meetings',
            channelDescription: 'Meeting reminders',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  Future<void> cancelMeetingReminder(String meetingId) async {
    try {
      await _plugin.cancel(meetingId.hashCode);
    } catch (_) {}
  }

  Future<void> scheduleTaskDueReminder(TaskItem task) async {
    if (!_ready || kIsWeb || task.dueAt == null) return;
    final when = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day, 9);
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        task.id.hashCode + 10000,
        'Task due today',
        task.title,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tasks',
            'Tasks',
            channelDescription: 'Task due reminders',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _plugin.cancel(taskId.hashCode + 10000);
    } catch (_) {}
  }
}
