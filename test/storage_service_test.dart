// test/storage_service_test.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/services/storage_service.dart';

void main() {
  group('StorageService Unit Tests', () {
    test('FirebaseStorageService detects content types accurately', () {
      expect(FirebaseStorageService.detectContentType('diagram.png'), 'image/png');
      expect(FirebaseStorageService.detectContentType('photo.jpg'), 'image/jpeg');
      expect(FirebaseStorageService.detectContentType('photo.jpeg'), 'image/jpeg');
      expect(FirebaseStorageService.detectContentType('banner.webp'), 'image/webp');
      expect(FirebaseStorageService.detectContentType('report.pdf'), 'application/pdf');
      expect(FirebaseStorageService.detectContentType('essay.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      expect(FirebaseStorageService.detectContentType('archive.zip'), 'application/zip');
      expect(FirebaseStorageService.detectContentType('data.bin'), 'application/octet-stream');
      expect(FirebaseStorageService.detectContentType('presentation.mp4'), 'video/mp4');
      expect(FirebaseStorageService.detectContentType('screen_recording.mov'), 'video/quicktime');
      expect(FirebaseStorageService.detectContentType('demo.webm'), 'video/webm');
    });

    test('StorageNotConfiguredException formats human-readable message with guidance', () {
      const ex = StorageNotConfiguredException('walkthrough.mp4', 15728640);
      expect(ex.formattedSize, '15.0 MB');
      expect(ex.toString(), contains('walkthrough.mp4'));
      expect(ex.toString(), contains('15.0 MB'));
      expect(ex.toString(), contains('YouTube'));
    });

    test('MockStorageService returns self-contained data URI for small files', () async {
      final mockStorage = MockStorageService();
      final sampleBytes = Uint8List.fromList(utf8.encode('test image content'));

      final url = await mockStorage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'sample.png',
        fileBytes: sampleBytes,
      );

      expect(url.startsWith('data:image/png;base64,'), isTrue);
    });

    test('MockStorageService returns cloud URL for files above threshold', () async {
      final mockStorage = MockStorageService();
      // 300 KB byte array
      final largeBytes = Uint8List(300 * 1024);

      final url = await mockStorage.uploadDeliverableFile(
        userId: 'u1',
        courseId: 'c1',
        fileName: 'large_archive.zip',
        fileBytes: largeBytes,
      );

      expect(url.startsWith('https://firebasestorage.googleapis.com'), isTrue);
    });
  });
}
