import 'package:dio/dio.dart';
import '../models/voucher_models.dart';

class VoucherService {
  final Dio _dio;

  // TOGGLE: Set to true for live production backend, false for local simulation
  static const bool _useMock = true;

  VoucherService(this._dio);

  Future<List<GiftCardBrand>> getBrands({String? category, String? search, int page = 1, int limit = 20}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      final List<GiftCardBrand> allBrands = [
        GiftCardBrand(
          productId: 'amazon_in',
          name: 'Amazon.in Pay Gift Card',
          thumbnailUrl: 'https://logos-world.net/wp-content/uploads/2020/04/Amazon-Logo.png',
          category: 'Shopping',
          denominationType: DenominationType.fixed,
          denominations: [500, 1000, 2000, 5000],
          cardType: CardType.cardAndPinNoSecured,
          redemptionType: RedemptionType.online,
          redemptionTypeName: 'Online Only',
          howToUseInstructions: '1. Login to Amazon.in\n2. Go to Amazon Pay\n3. Select Add Gift Card\n4. Enter your code.',
          minOrderAmount: 500,
          maxOrderAmount: 10000,
        ),
        GiftCardBrand(
          productId: 'starbucks_in',
          name: 'Starbucks India',
          thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png',
          category: 'Food & Beverage',
          denominationType: DenominationType.flexible,
          minVoucherAmount: 100,
          maxVoucherAmount: 5000,
          cardType: CardType.pinNoSecured,
          redemptionType: RedemptionType.offline,
          redemptionTypeName: 'In-Store Only',
          howToUseInstructions: '1. Visit any Starbucks store in India.\n2. Present this card/PIN at the counter.',
          minOrderAmount: 100,
          maxOrderAmount: 5000,
        ),
        GiftCardBrand(
          productId: 'myntra_in',
          name: 'Myntra Gift Card',
          thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/b/bc/Myntra_Logo.png',
          category: 'Fashion',
          denominationType: DenominationType.fixed,
          denominations: [1000, 2000, 5000],
          cardType: CardType.cardNumberSecured,
          redemptionType: RedemptionType.onlineAndOffline,
          redemptionTypeName: 'Online & In-Store',
          howToUseInstructions: 'Use on Myntra app or at select retail outlets.',
          minOrderAmount: 1000,
          maxOrderAmount: 20000,
        ),
      ];

      return allBrands.where((b) {
        bool match = true;
        if (category != null && category != 'All') match = b.category == category;
        if (search != null && search.isNotEmpty) {
          match = match && b.name.toLowerCase().contains(search.toLowerCase());
        }
        return match;
      }).toList();
    }

    final response = await _dio.get('/api/vouchers/brands', queryParameters: {
      if (category != null) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });
    final List data = response.data['data'] ?? [];
    return data.map((json) => GiftCardBrand.fromJson(json)).toList();
  }

  Future<GiftCardBrand> getBrandDetail(String productId) async {
    if (_useMock) {
      final brands = await getBrands();
      return brands.firstWhere((b) => b.productId == productId);
    }

    final response = await _dio.get('/api/vouchers/brands/$productId');
    return GiftCardBrand.fromJson(response.data['data']);
  }

  Future<VoucherOrderResult> redeemVoucher({
    required String productId,
    required List<Map<String, dynamic>> denominationDetails,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 2));
      return VoucherOrderResult(
        orderId: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        status: VoucherOrderStatus.processing,
        vouchers: [],
      );
    }

    final response = await _dio.post('/api/vouchers/redeem', data: {
      'productId': productId,
      'denominationDetails': denominationDetails,
    });
    return VoucherOrderResult.fromJson(response.data['data']);
  }

  Future<VoucherOrderResult> pollOrderStatus(String orderId) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate success on poll
      return VoucherOrderResult(
        orderId: orderId,
        status: VoucherOrderStatus.success,
        vouchers: [
          VoucherCredential(
            id: 'V123',
            cardType: CardType.cardAndPinNoSecured,
            cardNumber: '4455 6677 8899 0011',
            cardPin: '1234',
            amount: 500,
            validTill: DateTime.now().add(const Duration(days: 365)),
          ),
        ],
      );
    }

    final response = await _dio.get('/api/vouchers/orders/$orderId');
    return VoucherOrderResult.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getMyVoucherHistory() async {
    if (_useMock) {
      return [
        {
          'orderId': 'ORD_12345',
          'brandName': 'Amazon.in',
          'thumbnailUrl': 'https://logos-world.net/wp-content/uploads/2020/04/Amazon-Logo.png',
          'status': 'SUCCESS',
          'amount': 500,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        }
      ];
    }

    final response = await _dio.get('/api/vouchers/my');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }
}
