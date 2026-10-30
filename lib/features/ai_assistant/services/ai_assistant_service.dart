// lib/features/ai_assistant/services/ai_assistant_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_preferences_service.dart';

/// Abstract contract for AI Academic Assistant backends.
abstract class AiAssistantService {
  Future<String> sendMessage({
    required String prompt,
    required String contextPrompt,
  });
}

/// Fallback and offline-capable assistant that analyzes the injected context
/// and generates structured, intelligent academic coaching recommendations.
class MockAiAssistantService implements AiAssistantService {
  @override
  Future<String> sendMessage({
    required String prompt,
    required String contextPrompt,
  }) async {
    // Simulate slight natural thinking latency (300-600ms)
    await Future.delayed(const Duration(milliseconds: 450));

    final lower = prompt.toLowerCase();

    // 1. "What should I focus on today?" / "Today's priority"
    if (lower.contains('focus') || lower.contains('today') || lower.contains('priority')) {
      final lines = contextPrompt.split('\n');
      final todayClassLines = lines
          .where((l) => l.startsWith('- ') && l.contains('to') && l.contains('->'))
          .toList();
      final pendingTaskLines = lines
          .where((l) => l.startsWith('- [') && l.contains('->'))
          .toList();

      final buffer = StringBuffer();
      buffer.writeln('🎯 **Your Daily Academic Game Plan**\n');

      if (todayClassLines.isNotEmpty) {
        buffer.writeln('**1. Classes to Attend Today:**');
        for (final c in todayClassLines) {
          buffer.writeln('  $c');
        }
        buffer.writeln('');
      } else {
        buffer.writeln('**1. Class Schedule:** No lectures scheduled today! You have open focus hours.\n');
      }

      if (pendingTaskLines.isNotEmpty) {
        buffer.writeln('**2. Top Workload Priority:**');
        buffer.writeln('  👉 ${pendingTaskLines.first.replaceFirst('- ', '')}\n');
        buffer.writeln('**3. Action Strategy:** Block out 45 minutes of focused work using the Pomodoro technique right after class.');
      } else {
        buffer.writeln('**2. Workload Status:** All deliverables are submitted! Use today to review past lecture slides or relax.');
      }

      return buffer.toString();
    }

    // 2. "Break down project" / "Milestones"
    if (lower.contains('break down') || lower.contains('project') || lower.contains('milestone')) {
      return '''📋 **Structured Deliverable Breakdown**

Here is a recommended 4-phase agile breakdown for your academic deliverables:

1. **Phase 1: Requirements & System Architecture (Day 1-2)**
   - Draft entity relationship diagrams (ERD) and component contracts.
   - Outline key inputs, outputs, and external integration points.

2. **Phase 2: Core Implementation & Prototype (Day 3-5)**
   - Scaffold the data model and repository layers.
   - Implement core business logic and primary user interface screens.

3. **Phase 3: Integration & Edge-Case Testing (Day 6-7)**
   - Connect cloud services (Firestore / Storage) and offline fallbacks.
   - Run automated unit and widget test suites.

4. **Phase 4: Polish & Documentation (Day 8)**
   - Capture preview screenshots and record a 2-minute video walkthrough.
   - Document system limitations in your `ARCHITECTURE.md`.

*Pro-tip: Commit changes file-by-file with conventional commit messages to maintain a clean git history!*''';
    }

    // 3. "Study schedule" / "Timetable" / "Exam prep"
    if (lower.contains('study') || lower.contains('schedule') || lower.contains('timetable') || lower.contains('plan')) {
      return '''⏱️ **Optimized Weekly Study Blueprint**

Based on your enrolled courses and upcoming deadlines:

- **Morning Focus Block (08:00 - 10:00 AM)**:
  Tackle deep technical concepts, algorithm design, or code implementations while cognitive energy is peak.
- **Afternoon Review (02:00 - 04:00 PM)**:
  Attend scheduled lectures and immediately jot down summary bullet points within 30 minutes of class dismissal.
- **Evening Wind-down (07:00 - 08:30 PM)**:
  Organize pending deliverables and check off completed coursework items.

*Remember: Consistency beats cramming every single time. Short 25-minute sprints with 5-minute pauses maximize long-term retention.*''';
    }

    // 4. "Workload" / "Summary" / "Progress"
    if (lower.contains('workload') || lower.contains('summary') || lower.contains('progress')) {
      final lines = contextPrompt.split('\n');
      final activeCountLine = lines.where((l) => l.contains('TOTAL ACTIVE COURSES:')).firstOrNull ?? 'Active courses';
      final pendingCountLine = lines.where((l) => l.contains('PENDING DELIVERABLES:')).firstOrNull ?? 'Pending deliverables';
      final completedCountLine = lines.where((l) => l.contains('COMPLETED DELIVERABLES:')).firstOrNull ?? 'Completed deliverables';

      return '''📊 **Academic Workload & Health Check**

- **$activeCountLine**
- **$pendingCountLine**
- **$completedCountLine**

✨ **Recommendation**: Keep deliverables grouped by priority. Prioritize any items due in less than 3 days, and archive past completed courses to keep your active calendar timetable clean.''';
    }

    // Default general response
    return '''💡 **Academic Advisor Note**

I am ready to help you optimize your semester! Here are a few things I can do for you:

- 🎯 **"What should I focus on today?"** — Prioritize your tasks based on today's classes and nearest deadlines.
- 📋 **"Break down my upcoming project"** — Generate an actionable step-by-step roadmap.
- ⏱️ **"Create a study timetable"** — Balance lecture hours with independent study blocks.
- 📊 **"Review my course workload"** — Analyze your current completion velocity.

What would you like to plan right now?''';
  }
}

/// Production assistant connecting directly to Google Gemini API (gemini-1.5-flash).
/// Gracefully falls back to MockAiAssistantService if the API key is not configured
/// or if network connectivity is interrupted.
class GeminiAiAssistantService implements AiAssistantService {
  final http.Client _client;
  final MockAiAssistantService _fallbackService = MockAiAssistantService();

  GeminiAiAssistantService({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<String> sendMessage({
    required String prompt,
    required String contextPrompt,
  }) async {
    final customApiKey = await AiPreferencesService.getCustomApiKey();

    // If no custom API key was supplied, use the intelligent contextual mock assistant
    if (customApiKey == null || customApiKey.isEmpty) {
      return _fallbackService.sendMessage(
        prompt: prompt,
        contextPrompt: contextPrompt,
      );
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$customApiKey',
      );

      final systemInstruction = '''You are an encouraging, pragmatic, and helpful Academic Advisor and Study Coach for university students using a student-first Learning Management System (LMS) and Academic Portfolio.
Your goal is to help the student organize their coursework, break down deliverables into manageable milestones, and maintain a healthy, balanced study routine.
Always ground your answers in the student's actual enrolled courses, schedule slots, and pending deliverables provided in the context.
Keep your responses well-structured with markdown headings, bullet points, and actionable tips. Do not write full assignments for the student; focus on time management, architectural guidance, and learning strategies.''';

      final requestBody = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '$contextPrompt\n\n=== STUDENT QUESTION ===\n$prompt',
              }
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
        }
      });

      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }

      // If non-200 (e.g. invalid key, quota limit), smoothly fallback
      return _fallbackService.sendMessage(
        prompt: prompt,
        contextPrompt: contextPrompt,
      );
    } catch (_) {
      // Offline or network error: return resilient fallback
      return _fallbackService.sendMessage(
        prompt: prompt,
        contextPrompt: contextPrompt,
      );
    }
  }
}

