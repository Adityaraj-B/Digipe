// lib/features/geofencing/models/geofence_models.dart

class StoreGeofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? address;
  final String? logoUrl;

  StoreGeofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.address,
    this.logoUrl,
  });

  factory StoreGeofence.fromJson(Map<String, dynamic> json) => StoreGeofence(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200.0,
    address: json['address'],
    logoUrl: json['logoUrl'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'address': address,
    'logoUrl': logoUrl,
  };
}

class StoreCoupon {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final num discountValue;
  final String discountType; // PERCENTAGE | FLAT
  final DateTime? validUntil;
  final String? deepLinkPath;

  StoreCoupon({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.discountValue,
    required this.discountType,
    this.validUntil,
    this.deepLinkPath,
  });

  factory StoreCoupon.fromJson(Map<String, dynamic> json) => StoreCoupon(
    id: json['_id'] ?? json['id'] ?? '',
    storeId: json['storeId'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    discountValue: json['discountValue'] ?? 0,
    discountType: json['discountType'] ?? 'PERCENTAGE',
    validUntil: json['validUntil'] != null ? DateTime.tryParse(json['validUntil']) : null,
    deepLinkPath: json['deepLinkPath'],
  );

  bool get isExpired => validUntil != null && DateTime.now().isAfter(validUntil!);
}

enum GeofenceEventType { enter, exit }

class GeofenceVisitEvent {
  final String storeId;
  final String storeName;
  final GeofenceEventType eventType;
  final DateTime timestamp;

  GeofenceVisitEvent({
    required this.storeId,
    required this.storeName,
    required this.eventType,
    required this.timestamp,
  });

  factory GeofenceVisitEvent.fromJson(Map<String, dynamic> json) => GeofenceVisitEvent(
    storeId: json['storeId'] ?? '',
    storeName: json['storeName'] ?? '',
    eventType: json['eventType'] == 'ENTER' ? GeofenceEventType.enter : GeofenceEventType.exit,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}
