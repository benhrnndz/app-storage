// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/lms_repository.dart';
import 'features/ai_assistant/services/ai_preferences_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/firebase_auth_service.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before calling platform channels
  WidgetsFlutterBinding.ensureInitialized();
  await AiPreferencesService.init();

  AuthService authService;
  LmsRepository repository;

  try {
    // Attempt live Firebase Cloud initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authService = FirebaseAuthService();
    repository = FirestoreLmsRepository();
  } catch (e) {
    // Resilient fallback for local testing or unconfigured environments
    debugPrint('Firebase initialization notice: $e. Falling back to local development engine.');
    authService = MockAuthService(startLoggedIn: true);
    repository = LocalLmsRepository();
  }

  runApp(StudentLmsApp(
    authService: authService,
    repository: repository,
  ));
}

/// The root application widget.
class StudentLmsApp extends StatelessWidget {
  final AuthService authService;
  final LmsRepository? repository;

  const StudentLmsApp({
    super.key,
    required this.authService,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student LMS & Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthGate(
        authService: authService,
        repository: repository,
      ),
    );
  }
}
