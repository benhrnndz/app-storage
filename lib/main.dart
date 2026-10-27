// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/firebase_auth_service.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before calling async platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with our auto-generated cloud project options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Concrete Google OAuth + Firebase Auth service
  final authService = FirebaseAuthService();

  runApp(StudentLmsApp(authService: authService));
}

/// The root application widget.
class StudentLmsApp extends StatelessWidget {
  final AuthService authService;

  const StudentLmsApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student LMS & Portfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F5F9), // iOS light canvas
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS System Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: AuthGate(authService: authService),
    );
  }
}
