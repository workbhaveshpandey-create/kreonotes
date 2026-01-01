import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'update_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions on Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> showUpdateNotification({
    required String newVersion,
    required String downloadUrl,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1, // Notification ID
      '🚀 Update Available!',
      'Kreo Notes $newVersion is ready to download. Tap to update.',
      notificationDetails,
      payload: downloadUrl,
    );

    debugPrint('Update notification shown for version $newVersion');
  }

  /// Check for updates and show notification if available
  Future<void> checkAndNotify() async {
    try {
      final updateService = UpdateService();
      final result = await updateService.checkForUpdates();

      debugPrint('Background update check: available=${result.available}');

      if (result.available && result.downloadUrl != null) {
        await showUpdateNotification(
          newVersion: result.latestVersion,
          downloadUrl: result.downloadUrl!,
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }
}
