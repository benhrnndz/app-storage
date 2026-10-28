// lib/data/services/storage_service.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Abstract interface for file and photo uploads.
/// Follows Dependency Inversion Principle so presentation logic remains decoupled from Firebase Storage.
abstract class StorageService {
  /// Uploads binary file or photo bytes and returns the public download URL.
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  });

  /// Deletes a file from storage by its download URL.
  Future<void> deleteFile(String fileUrl);
}

/// Production implementation backed by Google Cloud Storage via Firebase Storage.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'users/$userId/courses/$courseId/attachments/${timestamp}_$sanitizedName';
    final ref = _storage.ref().child(path);

    final uploadTask = await ref.putData(fileBytes);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (_) {
      // Best effort cleanup; ignored if file does not exist
    }
  }
}

/// Offline / in-memory mock storage service for unit tests and local development.
class MockStorageService implements StorageService {
  @override
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    return 'https://firebasestorage.googleapis.com/v0/b/student-lms-app.appspot.com/o/mock_$fileName?alt=media';
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    // No-op for mock service
  }
}

