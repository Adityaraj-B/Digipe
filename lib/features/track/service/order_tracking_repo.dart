// ─────────────────────────────────────────────────────────────────────────────
// order_tracking_repository.dart
//
// Abstract interface + two concrete implementations:
//   • OrderTrackingMockRepository  — works today, no API needed
//   • OrderTrackingApiRepository   — drop in when your backend is ready
//
// Inject via constructor or a DI system (get_it, riverpod, etc).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'order_tracking_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class OrderTrackingRepository {
  /// Fetch a single order by its ID.
  Future<OrderTracking> fetchOrder(String orderId);

  /// Fetch all orders for the currently authenticated user.
  Future<List<OrderTracking>> fetchAllOrders();
}

// ---------------------------------------------------------------------------
// Mock implementation  (use this until the API is ready)
// ---------------------------------------------------------------------------

class OrderTrackingMockRepository implements OrderTrackingRepository {
  /// Simulate a short network delay so loading states render properly.
  final Duration delay;

  const OrderTrackingMockRepository({
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Future<OrderTracking> fetchOrder(String orderId) async {
    await Future.delayed(delay);
    // Return the sample mock — swap for a map keyed by orderId if you have
    // multiple mock fixtures.
    return OrderTrackingMock.sample;
  }

  @override
  Future<List<OrderTracking>> fetchAllOrders() async {
    await Future.delayed(delay);
    return [OrderTrackingMock.sample];
  }
}

// ---------------------------------------------------------------------------
// Real API implementation  (uncomment & fill in baseUrl when backend is ready)
// ---------------------------------------------------------------------------

class OrderTrackingApiRepository implements OrderTrackingRepository {
  final String baseUrl;
  final String authToken;
  final http.Client _client;

  OrderTrackingApiRepository({
    required this.baseUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken',
  };

  @override
  Future<OrderTracking> fetchOrder(String orderId) async {
    final uri = Uri.parse('$baseUrl/orders/$orderId');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // Adjust the key if your API wraps it, e.g. json['data']
      return OrderTracking.fromJson(json);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch order $orderId',
    );
  }

  @override
  Future<List<OrderTracking>> fetchAllOrders() async {
    final uri = Uri.parse('$baseUrl/orders');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Adjust if your API wraps in { "data": [...] }
      final list = json as List<dynamic>;
      return list
          .map((e) => OrderTracking.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch orders',
    );
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}