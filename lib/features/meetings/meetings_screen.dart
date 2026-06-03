import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/permissions.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/meeting.dart';
import '../shared/widgets/empty_state.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider);
    final currentAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          if (Permissions.canCreateMeeting(currentAsync.valueOrNull))
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push('/meetings/new'),
            ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (team) {
          if (team == null) return const SizedBox.shrink();
          final day = _selected ?? _focused;
          return FutureBuilder<List<Meeting>>(
            future: ref.read(meetingRepositoryProvider).getMeetingsOnDay(team.id, day),
            builder: (context, snap) {
              final dayMeetings = snap.data ?? [];
              return Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(_selected, d),
                    onDaySelected: (s, f) => setState(() {
                      _selected = s;
                      _focused = f;
                    }),
                    onPageChanged: (f) => _focused = f,
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat.yMMMEd().format(day),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : dayMeetings.isEmpty
                            ? const EmptyState(
                                icon: Icons.event_available_rounded,
                                title: 'No meetings this day',
                                subtitle: 'Schedule one with +',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: dayMeetings.length,
                                itemBuilder: (context, i) {
                                  final m = dayMeetings[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.event_rounded),
                                      title: Text(m.title),
                                      subtitle: Text(
                                        '${DateFormat.jm().format(m.startAt)} – ${DateFormat.jm().format(m.endAt)}',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => context.push('/meetings/${m.id}'),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
