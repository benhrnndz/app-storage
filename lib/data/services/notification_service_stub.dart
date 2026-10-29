// lib/data/services/notification_service_stub.dart
import 'notification_service_platform.dart';

class PlatformNotificationHandler implements NotificationPlatformHandler {
  String _status = 'default';

  @override
  bool get isSupported => true;

  @override
  Future<String> getPermissionStatus() async => _status;

  @override
  Future<bool> requestPermission() async {
    _status = 'granted';
    return true;
  }

  @override
  Future<void> showNotification({required String title, required String body}) async {
    // Stub implementation for unit tests and VM platforms
  }
}

NotificationPlatformHandler createPlatformHandler() => PlatformNotificationHandler();

