// test/auth_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/features/auth/screens/login_screen.dart';
import 'package:student_lms/features/auth/services/auth_service.dart';
import 'package:student_lms/models/auth_user.dart';

void main() {
  group('AuthUser Model Tests', () {
    test('AuthUser maps to and from JSON/Map properly', () {
      const user = AuthUser(
        uid: 'u_101',
        displayName: 'Ben Hernandez',
        email: 'ben@example.com',
      );

      final map = user.toMap();
      expect(map['uid'], 'u_101');
      expect(map['displayName'], 'Ben Hernandez');
      expect(map['email'], 'ben@example.com');

      final reconstructed = AuthUser.fromMap(map);
      expect(reconstructed.uid, 'u_101');
      expect(reconstructed.displayName, 'Ben Hernandez');
    });
  });

  group('AuthService State Flow Tests', () {
    test('MockAuthService emits null on logout and user on login', () async {
      final auth = MockAuthService(startLoggedIn: false);
      expect(auth.currentUser, isNull);

      final user = await auth.signInWithGoogle();
      expect(user, isNotNull);
      expect(user!.displayName, 'Ben Hernandez');
      expect(auth.currentUser?.email, 'hernandez.haroldbenedict25@gmail.com');

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  group('LoginScreen UI Tests', () {
    testWidgets('LoginScreen renders brand and Google Sign-In button', (WidgetTester tester) async {
      final auth = MockAuthService(startLoggedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: auth),
        ),
      );

      expect(find.text('Student LMS'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}

