// lib/features/auth/services/auth_service.dart
import 'dart:async';
import '../../../models/auth_user.dart';

/// Abstract contract for authentication services.
/// Adheres to the Dependency Inversion Principle: UI components depend
/// on this abstract contract rather than concrete third-party SDKs.
abstract class AuthService {
  /// Stream emitting the current AuthUser whenever sign-in state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently authenticated user, or null if signed out.
  AuthUser? get currentUser;

  /// Initiates the Google OAuth 2.0 sign-in flow.
  Future<AuthUser?> signInWithGoogle();

  /// Terminates the user session.
  Future<void> signOut();
}

/// A simulated authentication service used for local development and testing
/// before connecting live cloud credentials.
class MockAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  MockAuthService({bool startLoggedIn = false}) {
    if (startLoggedIn) {
      _currentUser = const AuthUser(
        uid: 'user_ben_123',
        displayName: 'Ben Hernandez',
        email: 'hernandez.haroldbenedict25@gmail.com',
        photoUrl: null,
      );
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser?> signInWithGoogle() async {
    // Simulate network latency for authenticating with Google IdP
    await Future.delayed(const Duration(milliseconds: 900));

    _currentUser = const AuthUser(
      uid: 'user_ben_123',
      displayName: 'Ben Hernandez',
      email: 'hernandez.haroldbenedict25@gmail.com',
      photoUrl: null,
    );

    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

