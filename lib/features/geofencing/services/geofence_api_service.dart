import 'package:dio/dio.dart';
import '../models/geofence_models.dart';

class GeofenceApiService {
  final Dio _dio;

  // TOGGLE: Set to true for live production backend, false for local simulation
  static const bool _useRealApi = false;

  GeofenceApiService(this._dio);

  Future<List<StoreGeofence>> getNearbyStores({
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        StoreGeofence(
          id: 'store_1',
          name: 'Reliance Digital - Koramangala',
          latitude: lat + 0.001,
          longitude: lng + 0.001,
          radiusMeters: 150,
          address: 'Koramangala 5th Block, Bengaluru',
        ),
        StoreGeofence(
          id: 'store_2',
          name: 'Croma - HSR Layout',
          latitude: lat - 0.001,
          longitude: lng - 0.001,
          radiusMeters: 200,
          address: 'HSR Layout Sector 6, Bengaluru',
        ),
        StoreGeofence(
          id: 'store_3',
          name: 'Tata Power Solar - Indiranagar',
          latitude: lat + 0.002,
          longitude: lng - 0.002,
          radiusMeters: 100, // Will be clamped to 100 by manager
          address: 'Indiranagar 100 Feet Rd, Bengaluru',
        ),
      ];
    }

    final response = await _dio.get('/api/geofences/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'limit': limit,
    });
    final List data = response.data['data'] ?? [];
    return data.map((json) => StoreGeofence.fromJson(json)).toList();
  }

  Future<StoreCoupon?> getActiveCoupon(String storeId) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (storeId == 'store_1') {
        return StoreCoupon(
          id: 'coupon_1',
          storeId: storeId,
          title: 'Flat 10% Off on Solar Panels',
          description: 'Get an exclusive discount at Reliance Digital.',
          discountValue: 10,
          discountType: 'PERCENTAGE',
          validUntil: DateTime.now().add(const Duration(days: 7)),
          deepLinkPath: '/store-offer?storeId=$storeId&couponId=coupon_1',
        );
      }
      return null;
    }

    try {
      final response = await _dio.get('/api/stores/$storeId/active-coupon');
      final data = response.data['data'];
      if (data == null) return null;
      return StoreCoupon.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reportGeofenceEvent({
    required String storeId,
    required GeofenceEventType eventType,
    required double latitude,
    required double longitude,
  }) async {
    if (!_useRealApi) {
      return {
        'eventId': 'evt_${DateTime.now().millisecondsSinceEpoch}',
        'notificationSuppressed': false,
        'cooldownRemainingSeconds': null,
      };
    }

    final response = await _dio.post('/api/geofences/events', data: {
      'storeId': storeId,
      'eventType': eventType == GeofenceEventType.enter ? 'ENTER' : 'EXIT',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<GeofenceVisitEvent>> getMyVisitHistory({int limit = 50}) async {
    if (!_useRealApi) return [];

    final response = await _dio.get('/api/geofences/events/my', queryParameters: {'limit': limit});
    final List data = response.data['data'] ?? [];
    return data.map((json) => GeofenceVisitEvent.fromJson(json)).toList();
  }

  Future<void> registerDeviceToken(String fcmToken, String platform) async {
    if (!_useRealApi) return;

    await _dio.post('/api/geofences/register-device', data: {
      'fcmToken': fcmToken,
      'platform': platform,
    });
  }
}
