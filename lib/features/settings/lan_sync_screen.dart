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

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  Future<void> _fetchIp() async {
    final lan = ref.read(lanSyncServiceProvider);
    final ip = await lan.getLocalIp();
    if (mounted) {
      setState(() {
        _localIp = ip;
      });
    }
  }

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
    final bool isServerRunning = lan.isRunning;
    final String activeCode = lan.pairingCode ?? '------';

    return Scaffold(
      appBar: AppBar(title: const Text('LAN Sync Control Panel')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wifi_tethering_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Local Sync Mesh Network',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sync team data on the same Wi-Fi. No cloud, fully peer-to-peer.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isHead) ...[
            Row(
              children: [
                Text('Server status: ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isServerRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isServerRunning ? Colors.green : Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isServerRunning ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isServerRunning ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isServerRunning ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isServerRunning)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: () async {
                          await lan.startHost();
                          _fetchIp();
                          setState(() {});
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start host sync server'),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Host IP: ${_localIp ?? 'Fetching...'}'),
                              const SizedBox(height: 4),
                              Text('Server Port: ${lan.port}'),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () async {
                              await lan.stopHost();
                              setState(() {});
                            },
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Stop'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pairing PIN Code:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(activeCode, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4)),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              lan.regenerateCode();
                              setState(() {});
                            },
                            icon: const Icon(Icons.autorenew_rounded),
                            label: const Text('Generate PIN'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 48),
          ],
          Text('Join team sync', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _hostIp,
                    decoration: const InputDecoration(
                      labelText: 'Host IP Address',
                      hintText: 'e.g. 192.168.1.10',
                      prefixIcon: Icon(Icons.computer_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: '6-Digit Pairing PIN',
                      hintText: 'e.g. 123456',
                      prefixIcon: Icon(Icons.pin_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      if (_hostIp.text.trim().isEmpty || _code.text.trim().isEmpty) return;
                      try {
                        await lan.syncFromHost(_hostIp.text.trim(), _code.text.trim());
                        refreshAll(ref);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Successfully Synced Data from Host!')),
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
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync with Host Now'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
