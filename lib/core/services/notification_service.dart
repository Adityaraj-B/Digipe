import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Callback for when a notification is tapped
  static Function(Map<String, dynamic>)? onNotificationTap;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onNotificationTap != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            onNotificationTap!(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isLimited) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'digipe_main',
      'DigiPe Alerts',
      channelDescription: 'Important updates regarding your insurance',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFF5A623),
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  static Future<void> showGeofenceNotification({
    required String storeId,
    required String storeName,
    String? couponId,
  }) async {
    await showNotification(
      id: storeId.hashCode,
      title: 'Nearby Offer at $storeName!',
      body: 'Tap to see exclusive partner discounts available now.',
      payload: {
        'type': 'geofence_offer',
        'storeId': storeId,
        'couponId': couponId,
      },
    );
  }

  // --- Haptics Helpers ---

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void successHaptic() {
    HapticFeedback.vibrate();
  }
}
