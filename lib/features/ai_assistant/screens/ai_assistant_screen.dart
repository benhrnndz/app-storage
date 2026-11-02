// lib/features/ai_assistant/screens/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../data/mock_data.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../../../models/schedule.dart';
import '../models/ai_message.dart';
import '../services/academic_context_engine.dart';
import '../services/ai_assistant_service.dart';

/// Screen hosting the AI Academic Assistant study coach, powered by Google Gemini
/// and grounded in real-time courses, deliverables, and timetable constraints.
class AiAssistantScreen extends StatefulWidget {
  final LmsRepository? repository;
  final String? userId;
  final AiAssistantService? aiService;

  const AiAssistantScreen({
    super.key,
    this.repository,
    this.userId,
    this.aiService,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  String get _userId => widget.userId ?? 'local_user';

  late final AiAssistantService _aiService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'What should I focus on today?',
    'Break down my upcoming project',
    'Create a study timetable',
    'Review my course workload',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? GeminiAiAssistantService();

    // Initial greeting message
    _messages.add(
      AiMessage(
        id: 'msg_welcome',
        text: '👋 **Hello! I am your AI Academic Assistant.**\n\nI analyze your enrolled courses, class hours, and upcoming deadlines to help you stay ahead. Tap a quick prompt below or ask me any question about your studies!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSubmitted(
    String text,
    List<Course> courses,
    List<Deliverable> deliverables,
    List<ScheduleSlot> schedules,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();

    final userMessage = AiMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    // Build fresh context from real-time repository state
    final contextPrompt = AcademicContextEngine.buildContextPrompt(
      courses: courses,
      deliverables: deliverables,
      schedules: schedules,
    );

    try {
      final responseText = await _aiService.sendMessage(
        prompt: trimmed,
        contextPrompt: contextPrompt,
      );

      final assistantMessage = AiMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMessage);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            AiMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: '⚠️ I encountered an issue preparing your academic plan. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final coursesStream = widget.repository != null
        ? widget.repository!.watchCourses(_userId)
        : Stream.value(mockCourses);

    final deliverablesStream = widget.repository != null
        ? widget.repository!.watchDeliverables(_userId)
        : Stream.value(mockDeliverables);

    final schedulesStream = widget.repository != null
        ? widget.repository!.watchSchedules(_userId)
        : Stream.value(mockSchedules);

    return StreamBuilder<List<Course>>(
      stream: coursesStream,
      builder: (context, courseSnapshot) {
        final courses = courseSnapshot.data ?? (widget.repository != null ? const <Course>[] : mockCourses);

        return StreamBuilder<List<Deliverable>>(
          stream: deliverablesStream,
          builder: (context, deliverableSnapshot) {
            final deliverables = deliverableSnapshot.data ?? (widget.repository != null ? const <Deliverable>[] : mockDeliverables);

            return StreamBuilder<List<ScheduleSlot>>(
              stream: schedulesStream,
              builder: (context, scheduleSnapshot) {
                final schedules = scheduleSnapshot.data ?? (widget.repository != null ? const <ScheduleSlot>[] : mockSchedules);

                return Scaffold(
                  appBar: FrostedAppBar(
                    title: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'AI Academic Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    gradientColors: [
                      const Color(0xFF0F766E).withOpacity(0.20),
                      const Color(0xFF0D9488).withOpacity(0.14),
                      const Color(0xFF10B981).withOpacity(0.08),
                    ],
                    actions: [
                      const ThemeToggleButton(),
                      IconButton(
                        icon: const Icon(Icons.refresh_outlined, size: 20),
                        tooltip: 'Reset Conversation',
                        onPressed: () {
                          setState(() {
                            _messages.clear();
                            _messages.add(
                              AiMessage(
                                id: 'msg_welcome',
                                text: '👋 **Conversation reset.** How can I assist your study planning?',
                                isUser: false,
                                timestamp: DateTime.now(),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: AmbientMeshBackground(
                    child: Column(
                      children: [
                        // Quick Action Chips Header
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: _quickPrompts.map((prompt) {
                              final isDark = theme.brightness == Brightness.dark;
                              final accentColor = isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: BouncyTap(
                                  scaleDown: 0.95,
                                  onTap: () => _handleSubmitted(prompt, courses, deliverables, schedules),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: (isDark ? const Color(0xFF111E1D) : Colors.white).withOpacity(0.82),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentColor.withOpacity(isDark ? 0.35 : 0.22),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 13, color: accentColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          prompt,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(height: 1),

                        // Message Feed
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                            itemCount: _messages.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return _buildLoadingIndicator();
                              }
                              final msg = _messages[index];
                              return StaggeredEntrance(
                                index: index,
                                child: _buildMessageBubble(msg, theme),
                              );
                            },
                          ),
                        ),

                        // Bottom Input Bar
                        _buildInputBar(theme, courses, deliverables, schedules),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(AiMessage message, ThemeData theme) {
    final isUser = message.isUser;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: GlassContainer(
          borderRadius: 20,
          blur: 16,
          borderColor: isUser
              ? primaryColor.withOpacity(isDark ? 0.40 : 0.28)
              : (isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.85)),
          color: isUser
              ? primaryColor.withOpacity(isDark ? 0.22 : 0.12)
              : (isDark ? const Color(0xFF111E1D).withOpacity(0.75) : Colors.white.withOpacity(0.85)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(isDark ? 0.20 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Syllo AI Coach',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: GlassContainer(
          borderRadius: 18,
          blur: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Analyzing schedule & coursework...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(
    ThemeData theme,
    List<Course> courses,
    List<Deliverable> deliverables,
    List<ScheduleSlot> schedules,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF2DD4BF) : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 94),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: GlassContainer(
            borderRadius: 26,
            blur: 20,
            borderColor: isDark ? primaryColor.withOpacity(0.28) : primaryColor.withOpacity(0.20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome_rounded, size: 19, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _handleSubmitted(val, courses, deliverables, schedules),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask your academic assistant...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                BouncyTap(
                  onTap: () => _handleSubmitted(_textController.text, courses, deliverables, schedules),
                  scaleDown: 0.92,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          const Color(0xFF10B981),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

