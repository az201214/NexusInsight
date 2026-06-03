import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/member.dart';

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _load(ref),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!;
        final meeting = data.meeting;
        if (meeting == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(meeting.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/meetings/$meetingId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final current = await ref.read(currentMemberProvider.future);
                  if (current == null) return;
                  await ref.read(meetingRepositoryProvider).deleteMeeting(
                        meeting.id,
                        meeting.teamId,
                        current.id,
                      );
                  refreshAll(ref);
                  if (context.mounted) context.pop();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('When'),
                subtitle: Text(
                  '${DateFormat.yMMMEd().format(meeting.startAt)}\n'
                  '${DateFormat.jm().format(meeting.startAt)} – ${DateFormat.jm().format(meeting.endAt)}',
                ),
              ),
              if (meeting.location != null)
                ListTile(
                  leading: const Icon(Icons.place_rounded),
                  title: const Text('Location'),
                  subtitle: Text(meeting.location!),
                ),
              if (meeting.agenda != null && meeting.agenda!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Agenda', style: Theme.of(context).textTheme.titleMedium),
                Text(meeting.agenda!),
              ],
              if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                Text(meeting.notes!),
              ],
              const SizedBox(height: 16),
              Text('Attendees', style: Theme.of(context).textTheme.titleMedium),
              ...data.attendeeNames.map((n) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_rounded, size: 20),
                    title: Text(n),
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<_MeetingDetail> _load(WidgetRef ref) async {
    final meeting = await ref.read(meetingRepositoryProvider).getMeeting(meetingId);
    final ids = await ref.read(meetingRepositoryProvider).getAttendeeIds(meetingId);
    final members = await ref.read(membersProvider.future);
    final names = ids
        .map((id) => members.firstWhereOrNull((m) => m.id == id)?.name)
        .whereType<String>()
        .toList();
    return _MeetingDetail(meeting: meeting, attendeeNames: names);
  }
}

class _MeetingDetail {
  _MeetingDetail({required this.meeting, required this.attendeeNames});
  final dynamic meeting;
  final List<String> attendeeNames;
}
