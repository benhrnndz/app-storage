// lib/data/services/storage_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Abstract interface for file and photo uploads.
/// Follows Dependency Inversion Principle so presentation logic remains decoupled from Firebase Storage.
abstract class StorageService {
  /// Uploads binary file or photo bytes and returns the public download URL or data URI.
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  });

  /// Deletes a file from storage by its download URL.
  Future<void> deleteFile(String fileUrl);
}

/// Production implementation backed by Google Cloud Storage via Firebase Storage,
/// with fast timeouts and instant base64 data URI fallback if bucket is unprovisioned or network times out.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  static String detectContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

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
    final contentType = detectContentType(fileName);

    try {
      final uploadTask = await ref
          .putData(fileBytes, SettableMetadata(contentType: contentType))
          .timeout(const Duration(seconds: 4));
      return await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 3));
    } catch (_) {
      // If Cloud Storage is unprovisioned (404), offline, or times out,
      // fallback to self-contained data URI for fast persistence (up to 1MB).
      if (fileBytes.lengthInBytes <= 1024 * 1024) {
        return 'data:$contentType;base64,${base64Encode(fileBytes)}';
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    if (fileUrl.startsWith('data:')) return;
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
    if (fileBytes.lengthInBytes <= 256 * 1024) {
      final contentType = FirebaseStorageService.detectContentType(fileName);
      return 'data:$contentType;base64,${base64Encode(fileBytes)}';
    }
    return 'https://firebasestorage.googleapis.com/v0/b/student-lms-app.appspot.com/o/mock_$fileName?alt=media';
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    // No-op for mock service
  }
}
