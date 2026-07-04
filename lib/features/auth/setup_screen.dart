import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../shared/widgets/premium_widgets.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _loading = false;

  // Step 1: Workspace details
  final _teamNameController = TextEditingController();
  String _industry = 'Development';
  final List<String> _industries = ['Development', 'Design Agency', 'Marketing', 'Consulting', 'Other'];

  // Step 2: Admin details
  final _adminNameController = TextEditingController();
  final _roleController = TextEditingController(text: 'Founder & CEO');
  int _selectedColor = 0xFF0D7377;
  final List<int> _avatarColors = [
    0xFF0D7377, // Deep Emerald Teal
    0xFFFF6B6B, // Coral Red
    0xFF2C3E7A, // Premium Indigo
    0xFFE9C46A, // Sunset Yellow
    0xFF9B5DE5, // Royal Purple
    0xFF00B4D8, // Bright Cerulean
  ];

  // Step 3: Security & Preferences
  bool _usePin = false;
  final _pinController = TextEditingController();
  ThemeMode _defaultTheme = ThemeMode.system;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill Admin Name if authenticated user's name is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = await ref.read(currentUserProvider.future);
      if (user != null && mounted) {
        _adminNameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _teamNameController.dispose();
    _adminNameController.dispose();
    _roleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_formKey2.currentState!.validate()) return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey3.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      
      // 1. Create base team with pin settings
      await teamRepo.createTeam(
        teamName: _teamNameController.text.trim(),
        headName: _adminNameController.text.trim(),
        pin: _usePin ? _pinController.text : null,
      );

      // 2. Load the created team & update customization preferences
      final team = await teamRepo.getTeam();
      if (team != null) {
        // Update industry/theme metadata on the team entry
        final String dbTheme = switch (_defaultTheme) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        };
        await teamRepo.updateTeam(team.copyWith(themeMode: dbTheme));
        
        // Update admin user profile (role, custom avatar color)
        final headMember = await teamRepo.getCurrentMember();
        if (headMember != null) {
          final updatedAdmin = headMember.copyWith(
            isActive: true,
          );
          // Manually update role & avatar details in database
          final db = await ref.read(databaseProvider).database;
          await db.update(
            'members',
            {
              'role': MemberRole.head.dbValue,
              'avatar_color': _selectedColor,
            },
            where: 'id = ?',
            whereArgs: [headMember.id],
          );
        }

        // Mark onboarding/initialization flow complete
        await teamRepo.completeOnboarding(team.id);
      }

      // Log the user in past the PIN screen automatically upon setup
      ref.read(unlockedProvider.notifier).state = true;
      refreshAll(ref);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Initialization failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Step Indicator Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ]
                ],
              ),
            ),

            // 2. Active Screen Content View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme, isDark),
                ],
              ),
            ),

            // 3. Bottom Controls Panel
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  _loading
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          onPressed: _currentStep == 2 ? _submit : _nextStep,
                          icon: Icon(_currentStep == 2 ? Icons.done_all_rounded : Icons.arrow_forward_rounded),
                          label: Text(_currentStep == 2 ? 'Deploy Workspace' : 'Continue'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Workspace & Agency Name Details
  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workspace Setup', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Establish the central hub for your team and clients.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Workspace / Agency Name',
                hintText: 'e.g. Acme Studio',
                prefixIcon: Icon(Icons.business_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your workspace name' : null,
            ),
            const SizedBox(height: 24),
            Text('Workspace Industry / Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _industries.map((ind) {
                final isSelected = _industry == ind;
                return ChoiceChip(
                  label: Text(ind),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _industry = ind);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Administrator Profile details
  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Profile Details', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Define how you will appear inside notifications, tasks, and reports.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _adminNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'How the team sees you',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your profile name' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Professional Designation / Role',
                hintText: 'e.g. Founder & Lead Designer',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please specify your role' : null,
            ),
            const SizedBox(height: 24),
            Text('Profile Theme Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarColors.length,
                itemBuilder: (context, idx) {
                  final colorVal = _avatarColors[idx];
                  final isSelected = _selectedColor == colorVal;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorVal),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(colorVal).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.done, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: SaaS Security PIN & Display theme preferences
  Widget _buildStep3(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workspace Preferences', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Set your security locks and default UI display mode.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Protect Workspace with PIN'),
              subtitle: const Text('Asks for passcode authentication on launch'),
              value: _usePin,
              onChanged: (v) => setState(() => _usePin = v),
            ),
            if (_usePin) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Security PIN',
                  hintText: '4 to 6 digit numeric code',
                  prefixIcon: Icon(Icons.lock_person_rounded),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                validator: (v) {
                  if (_usePin) {
                    if (v == null || v.isEmpty) return 'Please set a security PIN';
                    if (v.length < 4) return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
            ],
            const Divider(height: 40),
            Text('Preferred Interface Theme', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.hdr_auto_rounded), label: Text('System')),
              ],
              selected: {_defaultTheme},
              onSelectionChanged: (val) {
                setState(() => _defaultTheme = val.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
