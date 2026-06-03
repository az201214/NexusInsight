import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  List<dynamic> _tasks = [];
  List<dynamic> _meetings = [];
  List<dynamic> _members = [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final team = await ref.read(teamProvider.future);
    if (team == null) return;
    final tasks = await ref.read(taskRepositoryProvider).search(team.id, q);
    final meetings = await ref.read(meetingRepositoryProvider).search(team.id, q);
    final allMembers = await ref.read(teamRepositoryProvider).getActiveMembers(team.id);
    final members = allMembers
        .where((m) => m.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
    setState(() {
      _tasks = tasks;
      _meetings = meetings;
      _members = members;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          decoration: const InputDecoration(
            hintText: 'Search tasks, meetings, people…',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: (v) {
            if (v.length >= 2) _search(v);
          },
        ),
      ),
      body: ListView(
        children: [
          if (_members.isNotEmpty) ...[
            const ListTile(title: Text('People', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final m in _members)
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(m.name as String),
              ),
          ],
          if (_tasks.isNotEmpty) ...[
            const ListTile(title: Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final t in _tasks)
              ListTile(
                leading: const Icon(Icons.task_alt_rounded),
                title: Text(t.title as String),
                onTap: () => context.push('/tasks/${t.id}'),
              ),
          ],
          if (_meetings.isNotEmpty) ...[
            const ListTile(title: Text('Meetings', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final m in _meetings)
              ListTile(
                leading: const Icon(Icons.event_rounded),
                title: Text(m.title as String),
                onTap: () => context.push('/meetings/${m.id}'),
              ),
          ],
        ],
      ),
    );
  }
}
