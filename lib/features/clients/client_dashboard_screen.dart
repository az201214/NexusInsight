import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../shared/widgets/premium_widgets.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Hardcoded high-fidelity mock data representing B2B client details
    final mockConsultations = [
      (
        title: 'Project Kickoff & Architecture Review',
        date: 'June 28, 2026',
        duration: 45,
        summary: 'Discussed cloud scaling, database choices, and established the development timeline for Phase 1.'
      ),
      (
        title: 'Sprint 2 Demo & Feedback Session',
        date: 'June 15, 2026',
        duration: 60,
        summary: 'Demoed authorization gateways, localized storage layers, and reviewed the onboarding flow UI revisions.'
      ),
      (
        title: 'Initial Discovery & Budgeting Call',
        date: 'May 30, 2026',
        duration: 30,
        summary: 'Gathered core requirements, identified target user segments, and locked in the estimation budget.'
      ),
    ];

    final mockFiles = [
      (fileName: 'Project_Scope_v2.pdf', fileSize: '2.4 MB', type: 'pdf', uploaded: 'Yesterday'),
      (fileName: 'Architecture_Wireframes_Export.zip', fileSize: '18.9 MB', type: 'zip', uploaded: '3 days ago'),
      (fileName: 'Brand_Identity_Assets.png', fileSize: '4.1 MB', type: 'png', uploaded: 'June 12, 2026'),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Client Hub',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 120,
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      bottom: 70,
                      child: Text(
                        'Welcome Back, Partner 👋',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Join Video Huddle Launcher
                PerspectiveWrapper(
                  child: PremiumCard(
                    padding: const EdgeInsets.all(24),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.08),
                        theme.colorScheme.tertiary.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.video_camera_back_rounded,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Consulting Huddle',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to join your private video consulting room with the core team.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PremiumButton(
                          label: 'Join Video Huddle',
                          icon: Icons.forum_rounded,
                          onPressed: () {
                            context.push('/meetings/active-huddle/huddle');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Historical Overview (Consultations)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consultation History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_right_alt_rounded),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: mockConsultations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final item = mockConsultations[i];
                    return PremiumConsultationCard(
                      title: item.title,
                      date: item.date,
                      durationMinutes: item.duration,
                      summary: item.summary,
                    );
                  },
                ),
                const SizedBox(height: 32),

                // 3. Shared File Repository
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shared Documents',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: mockFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final file = mockFiles[i];
                    return PremiumFileCard(
                      fileName: file.fileName,
                      fileSize: file.fileSize,
                      fileType: file.type,
                      uploadedAt: file.uploaded,
                      onDownload: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${file.fileName}...')),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
