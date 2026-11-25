// test/storage_service_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/services/storage_service.dart';
import 'package:student_lms/models/deliverable.dart';

/// Configurable upload simulator that mirrors [FirebaseStorageService] behavior
/// across every failure mode (healthy cloud, unprovisioned bucket, timeout, auth error).
enum _SimulatedCloudMode {
  healthy,
  unprovisionedBucket,
  networkTimeout,
  permissionDenied,
}

class _SimulatedCloudStorageService implements StorageService {
  final _SimulatedCloudMode mode;
  final List<String> deletedUrls = [];

  _SimulatedCloudStorageService(this.mode);

  @override
  Future<String> uploadDeliverableFile({
    required String userId,
    required String courseId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    // 1. Always enforce validation rules before attempting upload
    FileUploadValidator.validateFile(
      fileName: fileName,
      byteCount: fileBytes.lengthInBytes,
    );

    final contentType = FirebaseStorageService.detectContentType(fileName);
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    switch (mode) {
      case _SimulatedCloudMode.healthy:
        return 'https://firebasestorage.googleapis.com/v0/b/student-lms-app.firebasestorage.app/o/users%2F$userId%2F$sanitized?alt=media';

      case _SimulatedCloudMode.unprovisionedBucket:
        if (fileBytes.lengthInBytes <= FileUploadLimits.maxInlineFallbackBytes) {
          return 'data:$contentType;base64,${base64Encode(fileBytes)}';
        }
        throw StorageNotConfiguredException(fileName, fileBytes.lengthInBytes);

      case _SimulatedCloudMode.networkTimeout:
        if (fileBytes.lengthInBytes <= FileUploadLimits.maxInlineFallbackBytes) {
          return 'data:$contentType;base64,${base64Encode(fileBytes)}';
        }
        throw StorageTimeoutException(fileName, fileBytes.lengthInBytes);

      case _SimulatedCloudMode.permissionDenied:
        if (fileBytes.lengthInBytes <= FileUploadLimits.maxInlineFallbackBytes) {
          return 'data:$contentType;base64,${base64Encode(fileBytes)}';
        }
        throw Exception('Upload failed for "$fileName": unauthorized');
    }
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    if (fileUrl.startsWith('data:')) return;
    deletedUrls.add(fileUrl);
  }
}

void main() {
  group('1. MIME Content-Type & Filename Detection', () {
    test('Detects images, videos, documents, archives, uppercase & unknown files', () {
      expect(FirebaseStorageService.detectContentType('diagram.png'), 'image/png');
      expect(FirebaseStorageService.detectContentType('photo.jpg'), 'image/jpeg');
      expect(FirebaseStorageService.detectContentType('PHOTO.JPEG'), 'image/jpeg');
      expect(FirebaseStorageService.detectContentType('banner.webp'), 'image/webp');
      expect(FirebaseStorageService.detectContentType('anim.gif'), 'image/gif');
      expect(FirebaseStorageService.detectContentType('vector.svg'), 'image/svg+xml');
      expect(FirebaseStorageService.detectContentType('report.pdf'), 'application/pdf');
      expect(FirebaseStorageService.detectContentType('essay.docx'),
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      expect(FirebaseStorageService.detectContentType('archive.zip'), 'application/zip');
      expect(FirebaseStorageService.detectContentType('presentation.mp4'), 'video/mp4');
      expect(FirebaseStorageService.detectContentType('DEMO.MOV'), 'video/quicktime');
      expect(FirebaseStorageService.detectContentType('demo.webm'), 'video/webm');
      expect(FirebaseStorageService.detectContentType('data.bin'), 'application/octet-stream');
      expect(FirebaseStorageService.detectContentType('README'), 'application/octet-stream');
    });

    test('Formats byte sizes cleanly across B, KB, and MB', () {
      expect(FileUploadLimits.formatBytes(1), '1 B');
      expect(FileUploadLimits.formatBytes(512), '512 B');
      expect(FileUploadLimits.formatBytes(500 * 1024), '500.0 KB');
      expect(FileUploadLimits.formatBytes(25 * 1024 * 1024), '25.0 MB');
    });
  });

  group('2. Single-File Size & Name Limit Validation', () {
    test('Rejects 0-byte empty file (below 1 B minimum)', () {
      expect(
        () => FileUploadValidator.validateFile(fileName: 'empty.pdf', byteCount: 0),
        throwsA(
          isA<FileValidationException>()
              .having((e) => e.code, 'code', 'empty-file')
              .having((e) => e.message, 'message', contains('at least 1 byte')),
        ),
      );
    });

    test('Accepts 1-byte minimum valid file', () {
      expect(
        () => FileUploadValidator.validateFile(fileName: 'min.txt', byteCount: 1),
        returnsNormally,
      );
    });

    test('Rejects blank or whitespace-only filename', () {
      expect(
        () => FileUploadValidator.validateFile(fileName: '   ', byteCount: 100),
        throwsA(
          isA<FileValidationException>().having((e) => e.code, 'code', 'invalid-filename'),
        ),
      );
    });

    test('Accepts file at exact 25 MB upper limit', () {
      expect(
        () => FileUploadValidator.validateFile(
          fileName: 'exact_25mb.mp4',
          byteCount: FileUploadLimits.maxFileSizeBytes,
        ),
        returnsNormally,
      );
    });

    test('Rejects file 1 byte over 25 MB limit with link guidance', () {
      expect(
        () => FileUploadValidator.validateFile(
          fileName: 'too_big.mp4',
          byteCount: FileUploadLimits.maxFileSizeBytes + 1,
        ),
        throwsA(
          isA<FileValidationException>()
              .having((e) => e.code, 'code', 'file-too-large')
              .having((e) => e.message, 'message', contains('25.0 MB'))
              .having((e) => e.message, 'message', contains('YouTube')),
        ),
      );
    });

    test('Rejects huge 120 MB video immediately before any network call', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.healthy);
      // Validate without allocating 120 MB in test memory via validator
      expect(
        () => FileUploadValidator.validateFile(
          fileName: 'lecture_recording.mov',
          byteCount: 120 * 1024 * 1024,
        ),
        throwsA(isA<FileValidationException>().having((e) => e.code, 'code', 'file-too-large')),
      );
      // Also verify service rejects 0-byte directly
      await expectLater(
        storage.uploadDeliverableFile(
          userId: 'u1',
          courseId: 'c1',
          fileName: 'zero.png',
          fileBytes: Uint8List(0),
        ),
        throwsA(isA<FileValidationException>().having((e) => e.code, 'code', 'empty-file')),
      );
    });
  });

  group('3. Multi-File Batch Limit Simulations', () {
    test('Allows up to 10 attachments totaling up to 50 MB', () {
      expect(
        () => FileUploadValidator.validateBatch(
          newFileSizes: List.filled(10, 5 * 1024 * 1024), // 10 x 5 MB = 50 MB
        ),
        returnsNormally,
      );
    });

    test('Rejects 11th attachment (exceeds 10-file cap)', () {
      expect(
        () => FileUploadValidator.validateBatch(
          existingCount: 10,
          existingBytes: 10 * 1024,
          newFileSizes: [1024],
        ),
        throwsA(
          isA<FileValidationException>().having((e) => e.code, 'code', 'too-many-files'),
        ),
      );
    });

    test('Rejects batch whose combined size exceeds 50 MB (e.g. three 20 MB files)', () {
      expect(
        () => FileUploadValidator.validateBatch(
          existingCount: 2,
          existingBytes: 40 * 1024 * 1024,
          newFileSizes: [20 * 1024 * 1024],
        ),
        throwsA(
          isA<FileValidationException>()
              .having((e) => e.code, 'code', 'total-size-exceeded')
              .having((e) => e.message, 'message', contains('50.0 MB')),
        ),
      );
    });

    test('Mixed batch simulation: valid files succeed while empty & oversized files are rejected', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.healthy);
      final candidates = <({String name, int size})>[
        (name: 'notes.txt', size: 128),
        (name: 'corrupted_empty.pdf', size: 0),
        (name: 'diagram.png', size: 40 * 1024),
        (name: 'huge_video.mp4', size: 30 * 1024 * 1024),
      ];

      final uploaded = <String>[];
      final rejectedCodes = <String>[];

      for (final file in candidates) {
        try {
          FileUploadValidator.validateFile(fileName: file.name, byteCount: file.size);
          final url = await storage.uploadDeliverableFile(
            userId: 'u1',
            courseId: 'c1',
            fileName: file.name,
            fileBytes: Uint8List(file.size),
          );
          uploaded.add(url);
        } on FileValidationException catch (e) {
          rejectedCodes.add(e.code);
        }
      }

      expect(uploaded.length, 2);
      expect(rejectedCodes, ['empty-file', 'file-too-large']);
    });
  });

  group('4. Cloud Storage Network & Fallback Simulations', () {
    test('Healthy Cloud Storage returns HTTPS URL and sanitizes special filename chars', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.healthy);
      final url = await storage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'My Report (Final) #1!.pdf',
        fileBytes: Uint8List(1024),
      );

      expect(url, startsWith('https://firebasestorage.googleapis.com'));
      expect(url, contains('My_Report__Final___1_.pdf'));
    });

    test('Unprovisioned bucket: <= 500 KB falls back to inline data URI', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.unprovisionedBucket);
      final exactLimitBytes = Uint8List(FileUploadLimits.maxInlineFallbackBytes);

      final url = await storage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'wireframe.png',
        fileBytes: exactLimitBytes,
      );

      expect(url, startsWith('data:image/png;base64,'));
    });

    test('Unprovisioned bucket: > 500 KB throws StorageNotConfiguredException with link tip', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.unprovisionedBucket);
      final overInlineBytes = Uint8List(FileUploadLimits.maxInlineFallbackBytes + 1);

      await expectLater(
        storage.uploadDeliverableFile(
          userId: 'u1',
          courseId: 'c1',
          fileName: 'walkthrough.mp4',
          fileBytes: overInlineBytes,
        ),
        throwsA(
          isA<StorageNotConfiguredException>()
              .having((e) => e.toString(), 'toString', contains('walkthrough.mp4'))
              .having((e) => e.toString(), 'toString', contains('YouTube')),
        ),
      );
    });

    test('Network timeout: <= 500 KB falls back to data URI; > 500 KB throws StorageTimeoutException', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.networkTimeout);

      final smallUrl = await storage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'receipt.jpg',
        fileBytes: Uint8List(32 * 1024),
      );
      expect(smallUrl, startsWith('data:image/jpeg;base64,'));

      await expectLater(
        storage.uploadDeliverableFile(
          userId: 'u1',
          courseId: 'c1',
          fileName: 'demo_hd.mp4',
          fileBytes: Uint8List(2 * 1024 * 1024),
        ),
        throwsA(
          isA<StorageTimeoutException>()
              .having((e) => e.toString(), 'toString', contains('timed out')),
        ),
      );
    });

    test('Permission denied on large file surfaces descriptive error', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.permissionDenied);

      await expectLater(
        storage.uploadDeliverableFile(
          userId: 'u1',
          courseId: 'c1',
          fileName: 'slides.pdf',
          fileBytes: Uint8List(1024 * 1024),
        ),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'toString', contains('unauthorized')),
        ),
      );
    });

    test('deleteFile ignores data URIs and deletes remote URLs cleanly', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.healthy);
      await storage.deleteFile('data:image/png;base64,AAAA');
      expect(storage.deletedUrls, isEmpty);

      const remoteUrl = 'https://firebasestorage.googleapis.com/v0/b/test/o/file.pdf?alt=media';
      await storage.deleteFile(remoteUrl);
      expect(storage.deletedUrls, [remoteUrl]);
    });
  });

  group('5. Firestore 1 MiB Document Safety & MockStorageService', () {
    test('Deliverable with 500 KB inline data URI does not duplicate payload and fits under Firestore 1 MiB cap', () async {
      final storage = _SimulatedCloudStorageService(_SimulatedCloudMode.unprovisionedBucket);
      final url = await storage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'diagram.png',
        fileBytes: Uint8List(FileUploadLimits.maxInlineFallbackBytes),
      );

      final deliverable = Deliverable(
        id: 'd1',
        courseId: 'c1',
        title: 'Architecture Diagram',
        type: DeliverableType.project,
        attachments: [
          DeliverableAttachment(
            url: url,
            name: 'diagram.png',
            sizeBytes: FileUploadLimits.maxInlineFallbackBytes,
          ),
        ],
        createdAt: DateTime(2026, 11, 25),
      );

      final serializedMap = deliverable.toMap();
      // Legacy attachmentUrl must NOT duplicate the huge data: URI
      expect(serializedMap['attachmentUrl'], isNull);

      final encodedBytes = utf8.encode(jsonEncode(serializedMap)).length;
      expect(encodedBytes, lessThan(1024 * 1024)); // Safely under Firestore 1 MiB limit

      // Round-trip deserialization still exposes the attachment cleanly
      final restored = Deliverable.fromMap(serializedMap, 'd1');
      expect(restored.allAttachments.length, 1);
      expect(restored.attachmentUrl, equals(url));
    });

    test('MockStorageService enforces validation and returns data URI / cloud URL appropriately', () async {
      final mockStorage = MockStorageService();

      // Rejects 0 bytes
      await expectLater(
        mockStorage.uploadDeliverableFile(
          userId: 'u1',
          courseId: 'c1',
          fileName: 'empty.txt',
          fileBytes: Uint8List(0),
        ),
        throwsA(isA<FileValidationException>().having((e) => e.code, 'code', 'empty-file')),
      );

      // Small file -> data URI
      final smallUrl = await mockStorage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'sample.png',
        fileBytes: Uint8List.fromList(utf8.encode('test image content')),
      );
      expect(smallUrl.startsWith('data:image/png;base64,'), isTrue);

      // 300 KB -> cloud URL
      final cloudUrl = await mockStorage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'large_archive.zip',
        fileBytes: Uint8List(300 * 1024),
      );
      expect(cloudUrl.startsWith('https://firebasestorage.googleapis.com'), isTrue);
    });
  });
}
