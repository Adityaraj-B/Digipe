import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

/// Data returned by the backend's /api/hubble/sdk-token endpoint.
class HubbleSdkConfig {
  final String token;
  final String sdkUrl;
  final String clientId;

  const HubbleSdkConfig({
    required this.token,
    required this.sdkUrl,
    required this.clientId,
  });

  factory HubbleSdkConfig.fromJson(Map<String, dynamic> json) {
    return HubbleSdkConfig(
      token: json['token'] as String,
      sdkUrl: json['sdkUrl'] as String,
      clientId: json['clientId'] as String,
    );
  }
}

/// A single Hubble transaction record stored by the backend webhook.
class HubbleTransaction {
  final String id;
  final String eventType;
  final String? brand;
  final num amount;
  final String currency;
  final String? voucherCode;
  final String status;
  final DateTime createdAt;

  const HubbleTransaction({
    required this.id,
    required this.eventType,
    this.brand,
    required this.amount,
    required this.currency,
    this.voucherCode,
    required this.status,
    required this.createdAt,
  });

  factory HubbleTransaction.fromJson(Map<String, dynamic> json) {
    return HubbleTransaction(
      id: json['_id'] as String,
      eventType: json['eventType'] as String? ?? 'other',
      brand: json['brand'] as String?,
      amount: (json['amount'] as num?) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      voucherCode: json['voucherCode'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get displayLabel {
    switch (eventType) {
      case 'payment_success':
        return 'Payment Successful';
      case 'voucher_generated':
        return 'Voucher Generated';
      case 'voucher_redeemed':
        return 'Voucher Redeemed';
      case 'order_placed':
        return 'Order Placed';
      case 'refund_completed':
        return 'Refund Completed';
      case 'refund_initiated':
        return 'Refund Initiated';
      case 'payment_failed':
        return 'Payment Failed';
      default:
        return 'Transaction';
    }
  }
}

class HubbleSdkService {
  final Dio _dio;

  HubbleSdkService(this._dio);

  /// Calls GET /api/hubble/sdk-token (requires auth token in header — handled by AuthInterceptor).
  /// Returns the Hubble SDK URL to load in the WebView.
  Future<HubbleSdkConfig> fetchSdkConfig() async {
    final response = await _dio.get(ApiConstants.hubbleSdkToken);
    final data = response.data['data'] as Map<String, dynamic>;
    return HubbleSdkConfig.fromJson(data);
  }

  /// Fetches the user's Hubble transaction history.
  /// Returns an empty list if the endpoint is unavailable (e.g. not yet deployed).
  Future<List<HubbleTransaction>> fetchTransactions() async {
    try {
      final response = await _dio.get(ApiConstants.hubbleTransactions);
      final List raw = response.data['data']?['transactions'] ?? [];
      return raw.map((e) => HubbleTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Endpoint may not be available on the server yet — return empty gracefully
      return [];
    }
  }
}

