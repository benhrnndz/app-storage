// lib/features/auth/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/auth_user.dart';
import '../../navigation/main_navigation_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

/// The reactive gateway widget controlling screen access based on authentication state.
/// Listens to authStateChanges and automatically swaps between LoginScreen
/// and MainNavigationScreen without manual imperative navigation calls.
class AuthGate extends StatelessWidget {
  final AuthService authService;
  final LmsRepository? repository;

  const AuthGate({
    super.key,
    required this.authService,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // While checking existing session cache
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        // If authenticated -> present the full LMS and portfolio hub
        if (user != null) {
          return MainNavigationScreen(
            authService: authService,
            currentUser: user,
            repository: repository,
          );
        }

        // If unauthenticated -> present the Google Sign-In onboarding screen
        return LoginScreen(authService: authService);
      },
    );
  }
}

