// lib/models/auth_user.dart

/// Represents an authenticated student user in the system.
class AuthUser {
  /// The unique identifier issued by Firebase Auth / Identity Provider.
  final String uid;

  /// The student's full name (e.g., "Ben Hernandez").
  final String displayName;

  /// The student's Google email address.
  final String email;

  /// The URL to their Google account profile picture (optional).
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}

