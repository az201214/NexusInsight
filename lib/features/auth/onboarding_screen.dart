import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.hub_rounded,
      'Welcome to Krmaazha Team Hub',
      'Your team workspace — meetings, tasks, and updates in one place. Everything stays on your device.',
    ),
    (
      Icons.groups_rounded,
      'You lead, they join',
      'Create your team as Head. Add co-leads and members. Assign work and track progress together.',
    ),
    (
      Icons.offline_bolt_rounded,
      'Local & private',
      'No cloud servers to set up. Optional backup files and same-Wi‑Fi sync when you need it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/setup'),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.$1, size: 100, color: theme.colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(p.$2, style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(p.$3, style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  } else {
                    context.go('/setup');
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_page < _pages.length - 1 ? 'Next' : 'Create my team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
