import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _teamName = TextEditingController();
  final _headName = TextEditingController();
  final _pin = TextEditingController();
  bool _usePin = false;
  bool _loading = false;

  @override
  void dispose() {
    _teamName.dispose();
    _headName.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_teamName.text.trim().isEmpty || _headName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter team and your name')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final hasTeam = await ref.read(teamRepositoryProvider).hasTeam();
      if (!hasTeam) {
        await ref.read(teamRepositoryProvider).createTeam(
              teamName: _teamName.text.trim(),
              headName: _headName.text.trim(),
              pin: _usePin ? _pin.text : null,
            );
      }
      final team = await ref.read(teamRepositoryProvider).getTeam();
      if (team != null) {
        await ref.read(teamRepositoryProvider).completeOnboarding(team.id);
      }
      ref.read(unlockedProvider.notifier).state = true;
      refreshAll(ref);
      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your team')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Krmaazha Team Hub',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'You will be the Team Head with full control.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _teamName,
              decoration: const InputDecoration(
                labelText: 'Team name',
                hintText: 'e.g. Design Squad',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _headName,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'How the team sees you',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Protect with PIN'),
              subtitle: const Text('Optional app lock on launch'),
              value: _usePin,
              onChanged: (v) => setState(() => _usePin = v),
            ),
            if (_usePin)
              TextField(
                controller: _pin,
                decoration: const InputDecoration(labelText: '4–6 digit PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Krmaazha'),
            ),
          ],
        ),
      ),
    );
  }
}
