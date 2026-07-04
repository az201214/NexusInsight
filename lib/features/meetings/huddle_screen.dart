import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/widgets/premium_widgets.dart';

class HuddleScreen extends ConsumerStatefulWidget {
  const HuddleScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<HuddleScreen> createState() => _HuddleScreenState();
}

class _HuddleScreenState extends ConsumerState<HuddleScreen> with SingleTickerProviderStateMixin {
  bool _micMuted = false;
  bool _videoMuted = false;
  bool _chatOpen = true;
  bool _whiteboardOpen = false;
  bool _micListening = false;
  bool _screenSharing = false;

  // Whiteboard drawing points
  List<Offset?> _points = [];
  Color _drawColor = Colors.teal;
  double _strokeWidth = 4.0;

  // Live chat messages
  final List<({String sender, String message, DateTime time})> _chatMessages = [
    (sender: 'Sarah (UX Lead)', message: 'I shared the latest wireframes in the vault.', time: DateTime.now().subtract(const Duration(minutes: 5))),
    (sender: 'Alex (Tech)', message: 'Looks clean. Let\'s review the database model details today.', time: DateTime.now().subtract(const Duration(minutes: 3))),
  ];
  final _messageController = TextEditingController();

  // Keyword detector simulation
  String? _detectedKeyword;
  String? _battleCardContent;
  Timer? _simulatedVoiceTimer;

  // Active video participants
  final List<({String name, String role, Color color, bool speaking})> _participants = [
    (name: 'Sarah Jenkins', role: 'UX Lead', color: Colors.blueAccent, speaking: false),
    (name: 'Alex Chen', role: 'Solutions Arch', color: Colors.indigoAccent, speaking: false),
    (name: 'You', role: 'Client Partner', color: Colors.teal, speaking: false),
  ];

  final _meetingUrlController = TextEditingController(text: 'https://meet.google.com/krm-azha-hub');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _meetingUrlController.dispose();
    _simulatedVoiceTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Launch error: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add((
        sender: 'You',
        message: _messageController.text.trim(),
        time: DateTime.now(),
      ));
      _messageController.clear();
    });
  }

  // Simulates real-time keyword detection
  void _toggleMicListening(bool enabled) {
    setState(() {
      _micListening = enabled;
      _detectedKeyword = null;
      _battleCardContent = null;
    });

    _simulatedVoiceTimer?.cancel();
    if (enabled) {
      // Setup a timer that triggers floating battle cards at intervals simulating voice audio
      _simulatedVoiceTimer = Timer(const Duration(seconds: 4), () {
        setState(() {
          _detectedKeyword = 'DATABASE SCALING';
          _battleCardContent = 'Talking points:\n• Recommend sqflite with local FFI wrapper.\n• Establish index keys on team_id and due_at fields.\n• Keep blobs out of SQLite; store attachments in Cloud Storage.';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Huddle: Sprint Sync & Review'),
          ],
        ),
        actions: [
          Switch.adaptive(
            value: _micListening,
            onChanged: _toggleMicListening,
            activeColor: theme.colorScheme.primary,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('Simulate Voice AI', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Main content area: Video grid or Whiteboard
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: _whiteboardOpen
                            ? _buildWhiteboard(theme, isDark)
                            : _screenSharing
                                ? _buildScreenShareLayout(theme, isDark)
                                : _buildVideoGrid(theme, isDark),
                      ),
                      const SizedBox(height: 16),
                      _buildControlBar(theme, isDark),
                    ],
                  ),
                ),
              ),

              // Chat Sidebar with custom spring curve transition
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(0.175, 0.885, 0.32, 1.275), // Custom spring curve
                width: _chatOpen ? 320.0 : 0.0,
                child: _chatOpen ? _buildChatSidebar(theme, isDark) : const SizedBox.shrink(),
              ),
            ],
          ),

          // Floating Battle Card Overlay (Slides down from top right)
          if (_detectedKeyword != null)
            Positioned(
              top: 20,
              right: _chatOpen ? 340 : 20,
              child: AnimatedOpacity(
                opacity: _detectedKeyword != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: 320,
                  child: GlassmorphicCard(
                    blur: 20.0,
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'AI BATTLE CARD',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => _detectedKeyword = null),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          _detectedKeyword!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _battleCardContent!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _participants.length + 1,
          itemBuilder: (context, i) {
            // 1. Google Meet Link Card (Interactive Action Link Field & Generator)
            if (i == 0) {
              return PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.video_call_rounded, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Google Meet Link',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _meetingUrlController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Session URL',
                        hintText: 'https://meet.google.com/abc-defg-hij',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.autorenew_rounded),
                          tooltip: 'Generate Link',
                          onPressed: () {
                            final r = DateTime.now().millisecondsSinceEpoch.toString();
                            final s1 = r.substring(r.length - 3);
                            final s2 = r.substring(r.length - 7, r.length - 3);
                            final s3 = r.substring(r.length - 10, r.length - 7);
                            setState(() {
                              _meetingUrlController.text = 'https://meet.google.com/$s1-$s2-$s3';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Join Live Meet'),
                        onPressed: () async {
                          final url = _meetingUrlController.text.trim();
                          if (url.isNotEmpty) {
                            await _launchUrl(url);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Launching: $url')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Local User Feed
            if (i == _participants.length) {
              return PremiumCard(
                padding: EdgeInsets.zero,
                backgroundColor: isDark ? Colors.grey[900] : Colors.grey[300],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!_videoMuted)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.tealAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.videocam_rounded, color: Colors.white, size: 48),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 48),
                      ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('You (Active User)', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Remote Participant Feeds
            final p = _participants[i - 1];
            return PremiumCard(
              padding: EdgeInsets.zero,
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[300],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: p.color.withOpacity(0.15),
                    child: Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: p.color,
                        child: Text(
                          p.name.split(' ').map((e) => e[0]).join(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${p.name} (${p.role})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScreenShareLayout(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // 1. Large Main Shared Screen Viewport
        Expanded(
          flex: 3,
          child: PremiumCard(
            padding: EdgeInsets.zero,
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[300],
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.screen_share_rounded,
                          size: 64,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You are presenting your screen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Other participants see your active application layout in real-time.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _screenSharing = false),
                          icon: const Icon(Icons.stop_screen_share_rounded),
                          label: const Text('Stop Presenting'),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'PRESENTING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 2. Small Horizontal List of Peer Feeds at bottom
        Expanded(
          flex: 1,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _participants.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.link_rounded, size: 20),
                        const SizedBox(height: 4),
                        const Text('Session URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            _meetingUrlController.text,
                            style: const TextStyle(fontSize: 8, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (i == _participants.length) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!_videoMuted)
                          Container(
                            color: Colors.teal.withOpacity(0.2),
                            child: const Center(child: Icon(Icons.videocam_rounded, size: 20)),
                          )
                        else
                          const Center(child: Icon(Icons.videocam_off_rounded, size: 20)),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Text('You', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final p = _participants[i - 1];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                child: PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: p.color.withOpacity(0.15),
                        child: Center(
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: p.color,
                            child: Text(
                              p.name.split(' ').map((e) => e[0]).join(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Text(p.name.split(' ')[0], style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteboard(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Whiteboard tools
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => setState(() => _points.clear()),
                tooltip: 'Clear whiteboard',
              ),
              const VerticalDivider(),
              _colorDot(Colors.teal),
              _colorDot(Colors.redAccent),
              _colorDot(Colors.indigo),
              _colorDot(Colors.purple),
              const Spacer(),
              const Text('Shared Board Canvas', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Draw Area
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPos = box.globalToLocal(details.globalPosition);
              setState(() {
                _points.add(localPos);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: Container(
              color: isDark ? Colors.black26 : Colors.white70,
              child: CustomPaint(
                painter: _WhiteboardPainter(
                  points: _points,
                  color: _drawColor,
                  strokeWidth: _strokeWidth,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _drawColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _drawColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic Button
          IconButton(
            icon: Icon(_micMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
            color: _micMuted ? Colors.red : theme.colorScheme.primary,
            onPressed: () => setState(() => _micMuted = !_micMuted),
          ),
          const SizedBox(width: 16),
          // Video Button
          IconButton(
            icon: Icon(_videoMuted ? Icons.videocam_off_rounded : Icons.videocam_rounded),
            color: _videoMuted ? Colors.red : theme.colorScheme.primary,
            onPressed: () => setState(() => _videoMuted = !_videoMuted),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_screenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded),
            color: _screenSharing ? Colors.blueAccent : Colors.grey,
            onPressed: () => setState(() => _screenSharing = !_screenSharing),
            tooltip: _screenSharing ? 'Stop presenting screen' : 'Present screen',
          ),
          // Whiteboard Toggle
          IconButton(
            icon: Icon(_whiteboardOpen ? Icons.video_stable_rounded : Icons.gesture_rounded),
            color: _whiteboardOpen ? Colors.amber : Colors.grey,
            onPressed: () => setState(() => _whiteboardOpen = !_whiteboardOpen),
          ),
          const SizedBox(width: 16),
          // Chat Toggle
          IconButton(
            icon: Icon(_chatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
            color: _chatOpen ? theme.colorScheme.primary : Colors.grey,
            onPressed: () => setState(() => _chatOpen = !_chatOpen),
          ),
          const Spacer(),
          // Leave Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.call_end_rounded),
            label: const Text('Leave'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSidebar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded),
                const SizedBox(width: 8),
                const Text('Live Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _chatOpen = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, i) {
                final msg = _chatMessages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.sender,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg.message, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Bar
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
