import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class PaymentResolutionService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  PaymentResolutionService(this._apiService);

  /// Tier 1: Local Mapping (Cashfree ID -> Internal ID)
  Future<void> saveMapping(String gatewayOrderId, String internalOrderId) async {
    await _storage.write(key: 'cf_to_internal_$gatewayOrderId', value: internalOrderId);
  }

  /// Tier 2: API Fallback (Scan /api/orders/my for Gateway ID match)
  Future<String?> resolveInternalOrderId(String cashfreeOrderId) async {
    // Tier 1: check local storage first
    final stored = await _storage.read(key: 'cf_to_internal_$cashfreeOrderId');
    if (stored != null) return stored;

    // Tier 2: scan orders list
    try {
      final orders = await _apiService.getMyOrders();
      for (final order in orders) {
        if (order.cashfreeOrderId == cashfreeOrderId) {
          // Store it for next time
          await saveMapping(cashfreeOrderId, order.orderId);
          return order.orderId;
        }
      }
    } catch (_) {}
    
    return null;
  }
}
