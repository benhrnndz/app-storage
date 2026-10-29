// lib/data/services/calendar_export_web.dart
import 'dart:convert';
import 'dart:html' as html;
import 'calendar_export_platform.dart';

class PlatformCalendarExportHandler implements CalendarExportPlatformHandler {
  @override
  Future<void> downloadIcsFile({
    required String filename,
    required String icsContent,
  }) async {
    final bytes = utf8.encode(icsContent);
    final blob = html.Blob([bytes], 'text/calendar;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}

CalendarExportPlatformHandler createCalendarExportHandler() => PlatformCalendarExportHandler();

