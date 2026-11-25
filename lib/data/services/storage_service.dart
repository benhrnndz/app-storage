// lib/data/services/storage_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Centralized upload size & batch constraints enforced across the app.
class FileUploadLimits {
  /// Minimum file size in bytes (1 byte — rejects empty/0-byte corrupted files
  /// while still allowing small valid text, code, or config files).
  static const int minFileSizeBytes = 1;

  /// Maximum size per single file for Cloud Storage uploads (25 MB).
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  /// Maximum size for inline Base64 data-URI fallback when Cloud Storage is
  /// unavailable (500 KB → ~667 KB Base64, safely below Firestore's 1 MiB doc cap).
  static const int maxInlineFallbackBytes = 500 * 1024;

  /// Maximum number of file/photo attachments per deliverable.
  static const int maxAttachmentsPerDeliverable = 10;

  /// Maximum combined size of all attachments in a single deliverable (50 MB).
  static const int maxTotalBatchBytes = 50 * 1024 * 1024;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Thrown when a file or batch violates [FileUploadLimits] before upload begins.
class FileValidationException implements Exception {
  final String code;
  final String fileName;
  final int byteCount;
  final String message;

  const FileValidationException({
    required this.code,
    required this.fileName,
    required this.byteCount,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Validates individual files and attachment batches against [FileUploadLimits].
class FileUploadValidator {
  /// Validates a single file before staging or uploading.
  /// Throws [FileValidationException] if the file is empty, too large, or unnamed.
  static void validateFile({
    required String fileName,
    required int byteCount,
  }) {
    if (fileName.trim().isEmpty) {
      throw FileValidationException(
        code: 'invalid-filename',
        fileName: fileName,
        byteCount: byteCount,
        message: 'File name cannot be empty.',
      );
    }

    if (byteCount < FileUploadLimits.minFileSizeBytes) {
      throw FileValidationException(
        code: 'empty-file',
        fileName: fileName,
        byteCount: byteCount,
        message: '"$fileName" is empty (0 B). Files must be at least 1 byte to upload.',
      );
    }

    if (byteCount > FileUploadLimits.maxFileSizeBytes) {
      final sizeStr = FileUploadLimits.formatBytes(byteCount);
      final maxStr = FileUploadLimits.formatBytes(FileUploadLimits.maxFileSizeBytes);
      throw FileValidationException(
        code: 'file-too-large',
        fileName: fileName,
        byteCount: byteCount,
        message:
            '"$fileName" ($sizeStr) exceeds the $maxStr per-file upload limit. For large videos or archives, paste a Google Drive, YouTube, or Loom link instead.',
      );
    }
  }

  /// Validates adding one or more new files to an existing attachment list.
  /// Throws [FileValidationException] if count or total byte limits are exceeded.
  static void validateBatch({
    required List<int> newFileSizes,
    int existingCount = 0,
    int existingBytes = 0,
  }) {
    final totalCount = existingCount + newFileSizes.length;
    if (totalCount > FileUploadLimits.maxAttachmentsPerDeliverable) {
      throw FileValidationException(
        code: 'too-many-files',
        fileName: '',
        byteCount: existingBytes,
        message:
            'You can attach up to ${FileUploadLimits.maxAttachmentsPerDeliverable} files per deliverable (attempted $totalCount).',
      );
    }

    final addedBytes = newFileSizes.fold<int>(0, (sum, size) => sum + size);
    final totalBytes = existingBytes + addedBytes;
    if (totalBytes > FileUploadLimits.maxTotalBatchBytes) {
      final totalStr = FileUploadLimits.formatBytes(totalBytes);
      final maxStr = FileUploadLimits.formatBytes(FileUploadLimits.maxTotalBatchBytes);
      throw FileValidationException(
        code: 'total-size-exceeded',
        fileName: '',
        byteCount: totalBytes,
        message:
            'Combined attachment size ($totalStr) exceeds the $maxStr limit per deliverable.',
      );
    }
  }
}

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
      _storage.setMaxUploadRetryTime(const Duration(seconds: 20));
      _storage.setMaxOperationRetryTime(const Duration(seconds: 15));
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

  /// Maximum file size that will be stored inline as a data URI
  /// when Cloud Storage upload fails or is unavailable.
  static const int _dataUriFallbackLimit = FileUploadLimits.maxInlineFallbackBytes;

  @override
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    // Enforce minimum & maximum size and filename rules before hitting the network
    FileUploadValidator.validateFile(
      fileName: fileName,
      byteCount: fileBytes.lengthInBytes,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'users/$userId/courses/$courseId/attachments/${timestamp}_$sanitizedName';
    final ref = _storage.ref().child(path);
    final contentType = detectContentType(fileName);

    // Dynamic timeout: 15s base for small files, scales up for large files (max 300s)
    final int timeoutSeconds = fileBytes.lengthInBytes <= 1024 * 1024
        ? 15
        : (fileBytes.lengthInBytes / (128 * 1024)).ceil().clamp(30, 300);

    try {
      // putData() returns an UploadTask (extends Future<TaskSnapshot>).
      // We await the task snapshot first, then get the download URL.
      final snapshot = await ref
          .putData(fileBytes, SettableMetadata(contentType: contentType))
          .timeout(Duration(seconds: timeoutSeconds));
      return await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Fallback to data URI for files within limit
      if (fileBytes.lengthInBytes <= _dataUriFallbackLimit) {
        return 'data:$contentType;base64,${base64Encode(fileBytes)}';
      }
      throw StorageNotConfiguredException(fileName, fileBytes.lengthInBytes);
    } on FirebaseException catch (fe) {
      if (fileBytes.lengthInBytes <= _dataUriFallbackLimit) {
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
      if (fileBytes.lengthInBytes <= _dataUriFallbackLimit) {
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
    FileUploadValidator.validateFile(
      fileName: fileName,
      byteCount: fileBytes.lengthInBytes,
    );

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
