// test/ai_assistant_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_lms/data/repositories/lms_repository.dart';
import 'package:student_lms/features/ai_assistant/models/ai_message.dart';
import 'package:student_lms/features/ai_assistant/screens/ai_assistant_screen.dart';
import 'package:student_lms/features/ai_assistant/services/academic_context_engine.dart';
import 'package:student_lms/features/ai_assistant/services/ai_assistant_service.dart';
import 'package:student_lms/features/ai_assistant/services/ai_preferences_service.dart';
import 'package:student_lms/features/auth/services/auth_service.dart';
import 'package:student_lms/features/navigation/main_navigation_screen.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/deliverable.dart';
import 'package:student_lms/models/schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AiPreferencesService.isAiEnabledNotifier.value = false;
  });

  final testCourse = Course(
    id: 'c_test',
    code: 'CS 301',
    title: 'Distributed Systems',
    instructor: 'Dr. Rivera',
    semester: '1st Sem 2026',
    colorValue: 0xFF2196F3,
  );

  final testDeliverable = Deliverable(
    id: 'd_test',
    courseId: 'c_test',
    title: 'Raft Consensus Engine',
    type: DeliverableType.project,
    dueDate: DateTime.now().add(const Duration(days: 3)),
    isCompleted: false,
    createdAt: DateTime.now(),
  );

  final testSchedule = ScheduleSlot(
    id: 's_test',
    courseId: 'c_test',
    dayOfWeek: DateTime.now().weekday,
    startTime: '09:00',
    endTime: '11:00',
    roomOrLink: 'Lab 402',
    isCalendarSyncEnabled: true,
  );

  group('AiMessage Model Tests', () {
    test('AiMessage maps to and from Map accurately', () {
      final now = DateTime.now();
      final msg = AiMessage(
        id: 'msg_1',
        text: 'Study plan created',
        isUser: false,
        timestamp: now,
        suggestedActions: ['Start Timer', 'Review Notes'],
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_1');
      expect(map['text'], 'Study plan created');
      expect(map['isUser'], false);
      expect(map['suggestedActions'], contains('Start Timer'));

      final fromMap = AiMessage.fromMap(map);
      expect(fromMap.id, 'msg_1');
      expect(fromMap.text, 'Study plan created');
      expect(fromMap.isUser, false);
      expect(fromMap.suggestedActions, contains('Review Notes'));
    });
  });

  group('AcademicContextEngine Tests', () {
    test('buildContextPrompt formats active courses, classes today, and pending tasks', () {
      final prompt = AcademicContextEngine.buildContextPrompt(
        courses: [testCourse],
        deliverables: [testDeliverable],
        schedules: [testSchedule],
      );

      expect(prompt, contains('STUDENT ACADEMIC WORKSPACE CONTEXT'));
      expect(prompt, contains('[CS 301] Distributed Systems'));
      expect(prompt, contains('Raft Consensus Engine'));
      expect(prompt, contains('09:00 to 11:00'));
      expect(prompt, contains('Lab 402'));
    });
  });

  group('AiAssistantService Tests', () {
    test('MockAiAssistantService answers focus, break down, and schedule queries', () async {
      final service = MockAiAssistantService();
      final contextPrompt = AcademicContextEngine.buildContextPrompt(
        courses: [testCourse],
        deliverables: [testDeliverable],
        schedules: [testSchedule],
      );

      // Focus query
      final focusResp = await service.sendMessage(
        prompt: 'What should I focus on today?',
        contextPrompt: contextPrompt,
      );
      expect(focusResp, contains('Your Daily Academic Game Plan'));

      // Break down query
      final breakdownResp = await service.sendMessage(
        prompt: 'Break down my project',
        contextPrompt: contextPrompt,
      );
      expect(breakdownResp, contains('Structured Deliverable Breakdown'));

      // Schedule query
      final scheduleResp = await service.sendMessage(
        prompt: 'Create a study schedule',
        contextPrompt: contextPrompt,
      );
      expect(scheduleResp, contains('Optimized Weekly Study Blueprint'));
    });
  });

  group('AiPreferencesService & Navigation Integration Tests', () {
    test('Toggling AiPreferencesService updates notifier and persistent prefs', () async {
      expect(await AiPreferencesService.isAiEnabled(), false);
      expect(AiPreferencesService.isAiEnabledNotifier.value, false);

      await AiPreferencesService.setAiEnabled(true);
      expect(await AiPreferencesService.isAiEnabled(), true);
      expect(AiPreferencesService.isAiEnabledNotifier.value, true);

      await AiPreferencesService.setAiEnabled(false);
      expect(await AiPreferencesService.isAiEnabled(), false);
      expect(AiPreferencesService.isAiEnabledNotifier.value, false);
    });

    testWidgets('MainNavigationScreen dynamically surfaces AI Coach tab when enabled', (WidgetTester tester) async {
      final repository = LocalLmsRepository();
      final authService = MockAuthService(startLoggedIn: true);

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            repository: repository,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By default: AI Coach is disabled and hidden from navigation
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('AI Coach'), findsNothing);

      // Dynamically turn on AI Assistant
      await AiPreferencesService.setAiEnabled(true);
      await tester.pumpAndSettle();

      // AI Coach tab is now visible in the navigation bar!
      expect(find.text('AI Coach'), findsOneWidget);

      // Tap on AI Coach tab
      await tester.tap(find.text('AI Coach'));
      await tester.pumpAndSettle();

      expect(find.text('AI Academic Assistant'), findsOneWidget);
      expect(find.textContaining('I analyze your enrolled courses'), findsOneWidget);

      // Dynamically turn off AI Assistant
      await AiPreferencesService.setAiEnabled(false);
      await tester.pumpAndSettle();

      // AI Coach tab disappears and safely resets
      expect(find.text('AI Coach'), findsNothing);
    });

    testWidgets('AiAssistantScreen allows sending a message and renders response', (WidgetTester tester) async {
      final repository = LocalLmsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AiAssistantScreen(
            repository: repository,
            aiService: MockAiAssistantService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap quick prompt "What should I focus on today?"
      await tester.tap(find.text('What should I focus on today?'));
      await tester.pump();
      expect(find.text('Analyzing schedule & coursework...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.textContaining('Your Daily Academic Game Plan'), findsOneWidget);
    });
  });
}
