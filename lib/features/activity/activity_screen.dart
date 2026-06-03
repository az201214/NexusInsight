import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../shared/widgets/empty_state.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity feed')),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (team) {
          if (team == null) return const SizedBox.shrink();
          return FutureBuilder(
            future: ref.read(teamRepositoryProvider).getActivity(team.id, limit: 100),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final logs = snap.data!;
              if (logs.isEmpty) {
                return const EmptyState(
                  icon: Icons.timeline_rounded,
                  title: 'No activity yet',
                  subtitle: 'Updates from tasks and meetings appear here',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final log = logs[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(_iconFor(log.type.name), size: 20),
                    ),
                    title: Text(log.message),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(log.createdAt)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('task')) return Icons.task_alt_rounded;
    if (type.contains('meeting')) return Icons.event_rounded;
    if (type.contains('member')) return Icons.person_rounded;
    if (type.contains('backup')) return Icons.backup_rounded;
    return Icons.bolt_rounded;
  }
}
