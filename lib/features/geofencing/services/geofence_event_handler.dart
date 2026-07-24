import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_api_service.dart';
import '../models/geofence_models.dart';
import '../../../core/services/notification_service.dart';


class GeofenceEventHandler {
  final GeofenceApiService _apiService;
  final SharedPreferences _prefs;

  GeofenceEventHandler(this._apiService, this._prefs);

  /// Called by Tracelet on ENTER.
  Future<void> onGeofenceEnter(String identifier, double lat, double lng) async {
    // 1. Persistent Cooldown Check
    final lastEnterKey = 'geofence_last_notified_$identifier';
    final lastEnterTime = _prefs.getInt(lastEnterKey);
    
    final bool isWithinCooldown = lastEnterTime != null && 
        DateTime.now().millisecondsSinceEpoch - lastEnterTime < const Duration(hours: 24).inMilliseconds;

    // 2. Report to backend regardless of cooldown (for analytics)
    Map<String, dynamic>? result;
    try {
      result = await _apiService.reportGeofenceEvent(
        storeId: identifier,
        eventType: GeofenceEventType.enter,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      // Non-critical: log and continue
      debugPrint('Failed to report geofence ENTER to backend: $e');
    }

    if (isWithinCooldown) return;

    // 3. Trigger immediate local notification if not suppressed by backend
    if (result != null && result['notificationSuppressed'] == true) return;

    // Fetch store details to get the name (mocking this here for the local notification)
    // In a real scenario, we might have these cached in GeofenceManager
    final stores = await _apiService.getNearbyStores(lat: lat, lng: lng);
    final store = stores.firstWhere((s) => s.id == identifier, orElse: () => StoreGeofence(
      id: identifier, 
      name: 'Partner Store', 
      latitude: lat, 
      longitude: lng, 
      radiusMeters: 200
    ));

    await NotificationService.showGeofenceNotification(
      storeId: identifier,
      storeName: store.name,
    );

    // 4. Update persistent cooldown
    await _prefs.setInt(lastEnterKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Called by Tracelet on EXIT.
  Future<void> onGeofenceExit(String identifier, double lat, double lng) async {
    try {
      await _apiService.reportGeofenceEvent(
        storeId: identifier,
        eventType: GeofenceEventType.exit,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      debugPrint('Failed to report geofence EXIT to backend: $e');
    }
  }
}
