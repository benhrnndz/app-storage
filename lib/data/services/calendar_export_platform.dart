// lib/data/services/calendar_export_platform.dart

/// Contract for platform-specific calendar file downloads.
abstract class CalendarExportPlatformHandler {
  Future<void> downloadIcsFile({
    required String filename,
    required String icsContent,
  });
}

