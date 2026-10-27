// lib/features/auth/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/auth_user.dart';
import 'auth_service.dart';

/// Concrete implementation of AuthService utilizing Google Identity (OAuth 2.0)
/// and Firebase Authentication.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Converts a native Firebase User into our domain AuthUser entity.
  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      displayName: user.displayName ?? 'Student',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser?> signInWithGoogle() async {
    // 1. On Web: Use Firebase's native popup provider (no extra client IDs needed)
    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await _firebaseAuth.signInWithPopup(googleProvider);
      return _mapFirebaseUser(userCredential.user);
    }

    // 2. On Mobile (iOS / Android): Use GoogleSignIn dialog
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the account picker
      return null;
    }

    // Obtain OAuth authentication tokens
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Build the credential for Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    return _mapFirebaseUser(userCredential.user);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
    ]);
  }
}

