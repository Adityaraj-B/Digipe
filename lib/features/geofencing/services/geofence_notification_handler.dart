import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class GeofenceNotificationHandler {
  final GlobalKey<NavigatorState> _navigatorKey;

  GeofenceNotificationHandler(this._navigatorKey);

  void initialize() {
    NotificationService.onNotificationTap = (Map<String, dynamic> data) {
      _handleDeepLink(data);
    };
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? storeId = data['storeId'];
    final String? couponId = data['couponId'];

    if (type == 'geofence_offer' && storeId != null) {
      _navigatorKey.currentState?.pushNamed(
        '/store-offer',
        arguments: {
          'storeId': storeId,
          'couponId': couponId,
        },
      );
    }
  }
}
