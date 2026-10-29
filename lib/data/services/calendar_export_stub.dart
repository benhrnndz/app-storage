// lib/data/services/calendar_export_stub.dart
import 'calendar_export_platform.dart';

class PlatformCalendarExportHandler implements CalendarExportPlatformHandler {
  @override
  Future<void> downloadIcsFile({
    required String filename,
    required String icsContent,
  }) async {
    // Stub for unit testing and VM platforms
  }
}

CalendarExportPlatformHandler createCalendarExportHandler() => PlatformCalendarExportHandler();

