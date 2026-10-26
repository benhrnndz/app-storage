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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Academic Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
