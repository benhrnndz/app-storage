// lib/features/auth/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/auth_user.dart';
import '../../landing/screens/landing_screen.dart';
import '../../navigation/main_navigation_screen.dart';
import '../services/auth_service.dart';

/// The reactive gateway widget controlling screen access based on authentication state.
/// Listens to authStateChanges and automatically swaps between LandingScreen
/// and MainNavigationScreen without manual imperative navigation calls.
class AuthGate extends StatefulWidget {
  final AuthService authService;
  final LmsRepository? repository;

  const AuthGate({
    super.key,
    required this.authService,
    this.repository,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<AuthUser?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = widget.authService.authStateChanges;
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService != widget.authService) {
      _authStream = widget.authService.authStateChanges;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: _authStream,
      initialData: widget.authService.currentUser,
      builder: (context, snapshot) {
        // While checking existing session cache (only when truly waiting without any data)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
            authService: widget.authService,
            currentUser: user,
            repository: widget.repository,
          );
        }

        // If unauthenticated -> present the cinematic landing screen
        return LandingScreen(authService: widget.authService);
      },
    );
  }
}

