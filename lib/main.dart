// lib/main.dart
import 'package:flutter/material.dart';
import 'features/navigation/main_navigation_screen.dart';

void main() {
  runApp(const StudentLmsApp());
}

/// The root application widget.
class StudentLmsApp extends StatelessWidget {
  const StudentLmsApp({super.key});

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
      home: const MainNavigationScreen(),
    );
  }
}
