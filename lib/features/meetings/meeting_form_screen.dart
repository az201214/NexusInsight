import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/meeting.dart';

const _uuid = Uuid();

class MeetingFormScreen extends ConsumerStatefulWidget {
  const MeetingFormScreen({super.key, this.meetingId});

  final String? meetingId;

  @override
  ConsumerState<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends ConsumerState<MeetingFormScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _agenda = TextEditingController();
  final _notes = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  final Set<String> _attendees = {};
  bool _loading = true;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _agenda.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.meetingId == null) {
      setState(() => _loading = false);
      return;
    }
    final m = await ref.read(meetingRepositoryProvider).getMeeting(widget.meetingId!);
    if (m != null) {
      _title.text = m.title;
      _location.text = m.location ?? '';
      _agenda.text = m.agenda ?? '';
      _notes.text = m.notes ?? '';
      _start = m.startAt;
      _end = m.endAt;
      final ids = await ref.read(meetingRepositoryProvider).getAttendeeIds(m.id);
      _attendees.addAll(ids);
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = dt;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _save() async {
    final team = await ref.read(teamProvider.future);
    final current = await ref.read(currentMemberProvider.future);
    final settings = team != null
        ? await ref.read(teamRepositoryProvider).getSettings(team.id)
        : null;
    if (team == null || current == null || _title.text.trim().isEmpty) return;

    final meeting = Meeting(
      id: widget.meetingId ?? _uuid.v4(),
      teamId: team.id,
      title: _title.text.trim(),
      startAt: _start,
      endAt: _end,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      agenda: _agenda.text.trim().isEmpty ? null : _agenda.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdBy: current.id,
      createdAt: DateTime.now(),
    );

    final repo = ref.read(meetingRepositoryProvider);
    final attendeeIds = _attendees.isEmpty ? [current.id] : _attendees.toList();
    final reminder = settings?.meetingReminderMinutes ?? 15;
    final notif = settings?.notificationsEnabled ?? true;

    if (widget.meetingId == null) {
      await repo.createMeeting(
        meeting: meeting,
        attendeeIds: attendeeIds,
        actorId: current.id,
        reminderMinutes: reminder,
        notificationsEnabled: notif,
      );
    } else {
      await repo.updateMeeting(
        meeting: meeting,
        attendeeIds: attendeeIds,
        actorId: current.id,
        reminderMinutes: reminder,
        notificationsEnabled: notif,
      );
    }
    refreshAll(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingId == null ? 'New meeting' : 'Edit meeting'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Starts'),
            subtitle: Text(_start.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () => _pickDateTime(true),
            ),
          ),
          ListTile(
            title: const Text('Ends'),
            subtitle: Text(_end.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () => _pickDateTime(false),
            ),
          ),
          TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location / link')),
          const SizedBox(height: 16),
          TextField(controller: _agenda, decoration: const InputDecoration(labelText: 'Agenda'), maxLines: 2),
          const SizedBox(height: 16),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          const SizedBox(height: 16),
          Text('Attendees', style: Theme.of(context).textTheme.titleMedium),
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) => Column(
              children: [
                for (final m in members)
                  CheckboxListTile(
                    value: _attendees.contains(m.id),
                    title: Text(m.name),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _attendees.add(m.id);
                        } else {
                          _attendees.remove(m.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
