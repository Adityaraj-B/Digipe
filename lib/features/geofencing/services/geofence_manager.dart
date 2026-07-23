import 'package:tracelet/tracelet.dart' as tl;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'geofence_api_service.dart';
import 'geofence_event_handler.dart';



class GeofenceManager {
  final GeofenceApiService _apiService;
  final GeofenceEventHandler _eventHandler;

  GeofenceManager(this._apiService, this._eventHandler);

  Future<void> initializeTracelet() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      final requestedLocation = await Permission.locationWhenInUse.request();
      if (!requestedLocation.isGranted) {
        debugPrint('Tracelet initialization skipped: location permission not granted.');
        return;
      }
    }

    final backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      await Permission.locationAlways.request();
    }

    // 1. Setup Callback
    tl.Tracelet.onGeofence((event) async {
      final latitude = event.location.coords.latitude;
      final longitude = event.location.coords.longitude;

      if (event.action == tl.GeofenceAction.enter) {
        await _eventHandler.onGeofenceEnter(
          event.identifier,
          latitude,
          longitude,
        );
      } else if (event.action == tl.GeofenceAction.exit) {
        await _eventHandler.onGeofenceExit(
          event.identifier,
          latitude,
          longitude,
        );
      }
    });

    // 2. Initialize Tracelet
    await tl.Tracelet.ready(
      const tl.Config(
        geo: tl.GeoConfig(
          desiredAccuracy: tl.DesiredAccuracy.high,
          geofenceModeHighAccuracy: true,
        ),
        app: tl.AppConfig(
          stopOnTerminate: false,
          startOnBoot: true,
        ),
      ),
    );

    // 3. Health Check & OEM Power Management
    final health = await tl.Tracelet.getSettingsHealth();
    if (health['isAggressiveOem'] == true) {
      // Prompt user to disable battery optimizations for background reliability
      await tl.Tracelet.openBatterySettings();
    }

    // 4. Start tracking
    await tl.Tracelet.startGeofences();
  }

  /// Fetches stores from API and registers them with Tracelet.
  /// Tracelet handles OS limits (20) and spatial indexing automatically.
  Future<void> registerNearbyStores(double lat, double lng) async {
    final stores = await _apiService.getNearbyStores(lat: lat, lng: lng, limit: 100);

    final geofences = stores.map((store) {
      // RADIUS CLAMPING: Radii under 100m are unreliable for GPS
      double radius = store.radiusMeters;
      if (radius < 100) {
        debugPrint('WARNING: Radius for ${store.name} is ${radius}m. Clamping to 100m for reliability.');
        radius = 100;
      }

      return tl.Geofence(
        identifier: store.id,
        latitude: store.latitude,
        longitude: store.longitude,
        radius: radius,
      );
    }).toList();

    await tl.Tracelet.addGeofences(geofences);
  }

  Future<void> stopAll() async {
    await tl.Tracelet.stop();
    await tl.Tracelet.removeGeofences();
  }
}
