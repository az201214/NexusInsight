import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';

class LanSyncScreen extends ConsumerStatefulWidget {
  const LanSyncScreen({super.key});

  @override
  ConsumerState<LanSyncScreen> createState() => _LanSyncScreenState();
}

class _LanSyncScreenState extends ConsumerState<LanSyncScreen> {
  final _hostIp = TextEditingController();
  final _code = TextEditingController();
  String? _localIp;
  String? _hostCode;
  bool _hosting = false;

  @override
  void dispose() {
    _hostIp.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsync = ref.watch(currentMemberProvider);
    final isHead = currentAsync.valueOrNull?.role == MemberRole.head;
    final lan = ref.watch(lanSyncServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LAN team sync')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sync on the same Wi‑Fi without any cloud server. '
            'Team Head hosts; others pull the latest team data.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (isHead) ...[
            Text('Host session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _hosting
                  ? null
                  : () async {
                      final code = await lan.startHost();
                      final ip = await lan.getLocalIp();
                      setState(() {
                        _hosting = true;
                        _hostCode = code;
                        _localIp = ip;
                      });
                    },
              icon: const Icon(Icons.hub_rounded),
              label: Text(_hosting ? 'Hosting…' : 'Start host'),
            ),
            if (_hosting) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your IP: ${_localIp ?? '…'}'),
                      Text('Port: ${lan.port}'),
                      Text('Pairing code: $_hostCode',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await lan.stopHost();
                  setState(() {
                    _hosting = false;
                    _hostCode = null;
                  });
                },
                child: const Text('Stop hosting'),
              ),
            ],
            const Divider(height: 40),
          ],
          Text('Join session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _hostIp,
            decoration: const InputDecoration(
              labelText: 'Host IP address',
              hintText: 'e.g. 192.168.1.10',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: '6-digit code'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              try {
                await lan.syncFromHost(_hostIp.text.trim(), _code.text.trim());
                refreshAll(ref);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced from host')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: $e')),
                  );
                }
              }
            },
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}
