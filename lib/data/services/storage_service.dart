// lib/data/services/storage_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Thrown when Cloud Storage is unprovisioned on the Firebase project.
class StorageNotConfiguredException implements Exception {
  final String fileName;
  final int byteCount;

  const StorageNotConfiguredException(this.fileName, this.byteCount);

  String get formattedSize {
    if (byteCount < 1024 * 1024) {
      return '${(byteCount / 1024).toStringAsFixed(1)} KB';
    }
    return '${(byteCount / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'Cloud Storage is not enabled on this Firebase project. Large files like "$fileName" ($formattedSize) cannot be uploaded until Cloud Storage is set up in the Firebase Console.\n\nTip: You can add video links (YouTube, Google Drive, Loom) in the Submission Links section below.';
  }
}

/// Thrown when an upload transfer times out.
class StorageTimeoutException implements Exception {
  final String fileName;
  final int byteCount;

  const StorageTimeoutException(this.fileName, this.byteCount);

  @override
  String toString() {
    final sizeMb = (byteCount / (1024 * 1024)).toStringAsFixed(1);
    return 'Upload timed out while uploading "$fileName" ($sizeMb MB). Please check your internet connection or use a video link (YouTube / Google Drive / Loom).';
  }
}

/// Abstract interface for file and photo uploads.
/// Follows Dependency Inversion Principle so presentation logic remains decoupled from Firebase Storage.
abstract class StorageService {
  /// Uploads binary file, photo, or video bytes and returns the public download URL or data URI.
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
/// with dynamic timeouts, automatic MIME type detection, and safe fallback.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance {
    try {
      _storage.setMaxUploadRetryTime(const Duration(seconds: 8));
      _storage.setMaxOperationRetryTime(const Duration(seconds: 8));
    } catch (_) {}
  }

  static String detectContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      // Images
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
      case 'heic':
        return 'image/heic';
      case 'bmp':
        return 'image/bmp';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'm4v':
        return 'video/x-m4v';

      // Documents & Archives
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'zip':
        return 'application/zip';
      case 'tar':
      case 'gz':
        return 'application/gzip';
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

    // Dynamic timeout: 6 seconds for small files, up to 300s for large video files
    final int timeoutSeconds = fileBytes.lengthInBytes <= 1024 * 1024
        ? 6
        : (fileBytes.lengthInBytes / (256 * 1024)).ceil().clamp(30, 300);

    try {
      final uploadTask = await ref
          .putData(fileBytes, SettableMetadata(contentType: contentType))
          .timeout(Duration(seconds: timeoutSeconds));
      return await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // If file is small, fallback immediately to self-contained data URI
      if (fileBytes.lengthInBytes <= 1024 * 1024) {
        return 'data:$contentType;base64,${base64Encode(fileBytes)}';
      }
      // If large file timed out on unprovisioned storage or slow connection, provide a clean exception
      throw StorageNotConfiguredException(fileName, fileBytes.lengthInBytes);
    } on FirebaseException catch (fe) {
      if (fileBytes.lengthInBytes <= 1024 * 1024) {
        return 'data:$contentType;base64,${base64Encode(fileBytes)}';
      }
      if (fe.code == 'object-not-found' ||
          fe.code == 'bucket-not-found' ||
          fe.code == 'project-not-found' ||
          (fe.message?.contains('404') == true)) {
        throw StorageNotConfiguredException(fileName, fileBytes.lengthInBytes);
      }
      throw Exception('Upload failed for "$fileName": ${fe.message ?? fe.code}');
    } catch (e) {
      if (fileBytes.lengthInBytes <= 1024 * 1024) {
        return 'data:$contentType;base64,${base64Encode(fileBytes)}';
      }
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('404') || msg.contains('bucket')) {
        throw StorageNotConfiguredException(fileName, fileBytes.lengthInBytes);
      }
      throw Exception('Upload failed for "$fileName": $e');
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
