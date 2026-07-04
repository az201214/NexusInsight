import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/meeting.dart';
import '../../data/models/shared_file.dart';
import '../shared/widgets/premium_widgets.dart';
import '../shared/widgets/empty_state.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  Future<void> _pickAndUploadFile(WidgetRef ref, BuildContext context) async {
    final team = await ref.read(teamProvider.future);
    final member = await ref.read(currentMemberProvider.future);
    if (team == null || member == null) return;

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final extension = pickedFile.extension ?? 'unknown';
    
    // Formatting size
    final double sizeInMb = pickedFile.size / (1024 * 1024);
    final sizeStr = sizeInMb < 0.1 
        ? '${(pickedFile.size / 1024).toStringAsFixed(1)} KB' 
        : '${sizeInMb.toStringAsFixed(1)} MB';

    final id = const Uuid().v4();
    final sharedFile = SharedFile(
      id: id,
      teamId: team.id,
      fileName: pickedFile.name,
      filePath: pickedFile.path ?? pickedFile.name,
      fileSize: sizeStr,
      fileType: extension,
      uploadedAt: DateTime.now(),
      uploadedBy: member.id,
    );

    await ref.read(sharedFileRepositoryProvider).addFile(sharedFile);
    ref.invalidate(clientFilesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully uploaded ${pickedFile.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final meetingsAsync = ref.watch(clientMeetingsProvider);
    final filesAsync = ref.watch(clientFilesProvider);

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
                                    'Tap to join your private video consulting room (Demo & AI Preview).',
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
                          label: 'Join Huddle (Demo & AI Preview)',
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
                      onPressed: () => context.push('/meetings'),
                      icon: const Icon(Icons.arrow_right_alt_rounded),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                meetingsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, st) => Center(
                    child: Text('Error loading consultations: $e'),
                  ),
                  data: (meetings) {
                    if (meetings.isEmpty) {
                      return const EmptyState(
                        icon: Icons.forum_rounded,
                        title: 'No consultations yet',
                        subtitle: 'Scheduled consultations and review meetings will appear here.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: meetings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final m = meetings[i];
                        final dateStr = DateFormat.yMMMMd().format(m.startAt);
                        final duration = m.endAt.difference(m.startAt).inMinutes;
                        return PremiumConsultationCard(
                          title: m.title,
                          date: dateStr,
                          durationMinutes: duration,
                          summary: m.notes ?? m.agenda ?? 'No summary available.',
                        );
                      },
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
                      onPressed: () => _pickAndUploadFile(ref, context),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                filesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, st) => Center(
                    child: Text('Error loading documents: $e'),
                  ),
                  data: (files) {
                    if (files.isEmpty) {
                      return const EmptyState(
                        icon: Icons.insert_drive_file_outlined,
                        title: 'No shared documents yet',
                        subtitle: 'Upload scoping docs, wireframes, or assets to share them with the team.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final file = files[i];
                        return PremiumFileCard(
                          fileName: file.fileName,
                          fileSize: file.fileSize,
                          fileType: file.fileType,
                          uploadedAt: DateFormat.yMMMMd().format(file.uploadedAt),
                          onDownload: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Downloading ${file.fileName}...')),
                            );
                          },
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
