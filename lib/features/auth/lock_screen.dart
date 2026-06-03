import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPin() async {
    final team = await ref.read(teamProvider.future);
    if (team == null) return;
    final ok = await ref
        .read(teamRepositoryProvider)
        .verifyPin(team.id, _pinController.text);
    if (ok) {
      ref.read(unlockedProvider.notifier).state = true;
      if (mounted) context.go('/dashboard');
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  Future<void> _biometric() async {
    final auth = LocalAuthentication();
    final can = await auth.canCheckBiometrics;
    if (!can) return;
    final ok = await auth.authenticate(
      localizedReason: 'Unlock Krmaazha Team Hub',
    );
    if (ok) {
      ref.read(unlockedProvider.notifier).state = true;
      if (mounted) context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('Krmaazha is locked',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  errorText: _error,
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _unlockWithPin(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _unlockWithPin,
                child: const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _biometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use biometrics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
