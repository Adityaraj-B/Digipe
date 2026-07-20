import 'dart:async';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/api_models.dart';

class ApiService {
  final ApiClient _client;

  // TOGGLE: Set to true for live production backend, false for local simulation
  static const bool _useRealApi = true;

  ApiService(this._client);

  // --- Auth ---

  Future<void> sendOtp(String mobileNumber) async {
    if (!_useRealApi) {
      if (mobileNumber == '+910000000000') {
        throw Exception('User not registered. Please register first.');
      }
      return Future.delayed(const Duration(seconds: 1));
    }
    try {
      await _client.dio.post(ApiConstants.sendOtp, data: {'mobileNumber': mobileNumber});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          (e.response?.data is Map && e.response?.data['message']?.toString().contains('not found') == true)) {
        throw Exception('User not registered. Please register first.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({required String fullName, required String phone, required String email}) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(seconds: 1));
      return {'identifier': phone};
    }
    final response = await _client.dio.post(ApiConstants.register, data: {
      'fullName': fullName,
      'mobileNumber': phone, // Changed from 'phone' to 'mobileNumber'
      'email': email,
    });
    return response.data['data'] ?? response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String code) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'token': 'mock_jwt_token',
        'user': {
          '_id': 'u1',
          'name': 'Adityaraj',
          'email': 'adityaraj@surefy.co',
          'mobileNumber': mobileNumber,
          'role': 'admin'
        }
      };
    }
    final response = await _client.dio.post(ApiConstants.verifyOtp, data: {
      'mobileNumber': mobileNumber,
      'code': code,
    });
    return response.data['data'];
  }

  // --- Categories ---
  Future<List<Category>> getCategories() async {
    if (!_useRealApi) return [Category(id: 'c1', name: 'Insurance')];
    final response = await _client.dio.get(ApiConstants.categories);
    final List data = response.data['data'] ?? [];
    return data.map((json) => Category.fromJson(json)).toList();
  }



  // --- Products ---
  Future<List<Product>> getProducts() async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Product(
          id: 'p1',
          category: 'c1',
          name: 'Solar Insurance Plan',
          pricingConfig: {'basePrice': 499, 'amounts': ['500', '1000', '2000'], 'years': ['1', '2']},
          shortDescription: 'Protect your solar installation against damage.',
          features: ['Accidental Damage', 'Fire & Lightning', 'Theft Protection'],
        ),
      ];
    }
    final response = await _client.dio.get(ApiConstants.products);
    final List data = response.data['data'] ?? [];
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(String id) async {
    if (!_useRealApi) return (await getProducts()).first;
    final response = await _client.dio.get('${ApiConstants.products}/$id');
    return Product.fromJson(response.data['data']);
  }

  // --- Plans ---
  Future<List<Plan>> getPlansForProduct(String productId) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        Plan(id: 'pl1', productId: productId, name: '₹500 Cover - 1y', coverageAmount: 500, premium: 499, durationMonths: 12, premiumFrequency: 'YEARLY'),
        Plan(id: 'pl2', productId: productId, name: '₹1000 Cover - 1y', coverageAmount: 1000, premium: 999, durationMonths: 12, premiumFrequency: 'YEARLY'),
        Plan(id: 'pl3', productId: productId, name: '₹2000 Cover - 2y', coverageAmount: 2000, premium: 1799, durationMonths: 24, premiumFrequency: 'YEARLY'),
      ];
    }
    final response = await _client.dio.get('${ApiConstants.productPlans}/$productId', queryParameters: {'limit': 1000});
    final List data = response.data['data'] ?? [];
    return data.map((json) => Plan.fromJson(json)).toList();
  }

  // --- Product Fields ---
  Future<List<ProductField>> getProductFields(String productId) async {
    if (!_useRealApi) {
      return [
        ProductField(id: 'f1', productId: productId, fieldName: 'fullName', fieldLabel: 'Full Name', fieldType: 'TEXT', isRequired: true),
        ProductField(id: 'f2', productId: productId, fieldName: 'mobile', fieldLabel: 'Mobile Number', fieldType: 'TEXT', isRequired: true),
        ProductField(id: 'f3', productId: productId, fieldName: 'invoice', fieldLabel: 'Invoice Copy', fieldType: 'FILE', isRequired: true),
        ProductField(id: 'f4', productId: productId, fieldName: 'consent', fieldLabel: 'I accept terms', fieldType: 'CHECKBOX', isRequired: true),
      ];
    }
    final response = await _client.dio.get('${ApiConstants.productFieldsByProduct}/$productId');
    final List data = response.data['data'] ?? [];
    return data.map((json) => ProductField.fromJson(json)).toList();
  }

  // --- Applications ---
  Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(seconds: 1));
      return {'_id': 'app_mock_123', 'status': 'PENDING'};
    }
    final response = await _client.dio.post(ApiConstants.applications, data: data);
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    if (!_useRealApi) return [];
    final response = await _client.dio.get('/api/applications/my');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }

  Future<void> recordConsent(String applicationId) async {
    if (!_useRealApi) return;
    await _client.dio.post('/api/applications/$applicationId/consent');
  }

  Future<void> updateApplicationStatus(String id, String status, String remarks) async {
    if (!_useRealApi) return;
    await _client.dio.patch('${ApiConstants.applications}/$id/status', data: {
      'status': status,
      'remarks': remarks,
    });
  }

  // --- Admin Price Settings ---
  Future<Map<String, dynamic>> getPriceSettings() async {
    try {
      final response = await _client.dio.get('/api/admin/price-settings');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Regular users can't access admin price settings
        // Return safe defaults matching backend defaults
        return {
          'tax': {'gstPercentage': 18.0},
          'promotionalDiscount': {'percentage': 0.0, 'isActive': false},
        };
      }
      rethrow;
    }
  }

  // --- Orders & Policies ---
  Future<Map<String, dynamic>> createOrder({required String applicationId, required String planId}) async {
    if (!_useRealApi) {
      return {
        '_id': 'mock_internal_id',
        'totalAmount': 1110.82
      };
    }
    final response = await _client.dio.post('/api/orders', data: {
      'items': [{ 'planId': planId, 'applicationId': applicationId }]
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPaymentSession(String internalOrderId) async {
    if (!_useRealApi) {
      return {
        'paymentSessionId': 'mock_session_id',
        'cashfreeOrderId': 'cf_ORD_mock_123'
      };
    }
    final response = await _client.dio.post('/api/payments', data: {
      'orderId': internalOrderId
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<OrderSummary>> getMyOrders() async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        OrderSummary(orderId: 'POL-3B668B7A', product: 'Solar Insurance', amount: '899', date: '2026-06-12', status: 'CONFIRMED', canClaim: true),
      ];
    }
    final response = await _client.dio.get(ApiConstants.consumerOrders);
    final ordersData = response.data['data'];
    final List orders = (ordersData is Map ? ordersData['orders'] : ordersData) ?? [];
    return orders.map((json) => OrderSummary.fromJson(json)).toList();
  }

  Future<List<OrderSummary>> getMyPolicies() async {
    if (!_useRealApi) return await getMyOrders();
    final response = await _client.dio.get(ApiConstants.myPolicies);
    final policiesData = response.data['data'];
    final List policies = (policiesData is Map ? policiesData['policies'] : policiesData) ?? [];
    return policies.map((json) => OrderSummary.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getMyPoliciesRaw() async {
    if (!_useRealApi) return [];
    final response = await _client.dio.get(ApiConstants.myPolicies);
    final policiesData = response.data['data'];
    final List policies = (policiesData is Map ? policiesData['policies'] : policiesData) ?? [];
    return List<Map<String, dynamic>>.from(policies);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    if (!_useRealApi) return;
    await _client.dio.patch('${ApiConstants.adminOrders}/$id/status', data: {'status': status});
  }

  Future<String> getPaymentStatus(String internalOrderId) async {
    if (!_useRealApi) return 'SUCCESS';
    final response = await _client.dio.get('${ApiConstants.paymentStatus}/$internalOrderId');
    final data = response.data['data'];
    return (data['status'] as String? ?? '').toUpperCase();
  }

  // --- Claims ---
  Future<List<Map<String, dynamic>>> getMyClaims() async {
    if (!_useRealApi) {
      return [
        {'_id': 'c1', 'productName': 'Solar Insurance', 'status': 'UNDER_REVIEW', 'createdAt': '2026-06-13'}
      ];
    }
    final response = await _client.dio.get('/api/claims/my');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getClaimById(String id) async {
    if (!_useRealApi) {
      return {'_id': id, 'status': 'UNDER_REVIEW', 'documents': []};
    }
    final response = await _client.dio.get('/api/claims/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> submitClaim({
    required String policyId,
    required String description,
    required num claimAmount,
    String? reason,
    String? incidentDate,
    List<String> imageDocIds = const [],
    List<String> videoDocIds = const [],
  }) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
    await _client.dio.post('/api/claims', data: {
      'policyId': policyId,
      'description': description,
      'claimAmount': claimAmount,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
      if (incidentDate != null) 'incidentDate': incidentDate,
      if (imageDocIds.isNotEmpty) 'images': imageDocIds,
      if (videoDocIds.isNotEmpty) 'videos': videoDocIds,
    });
  }

  Future<void> updateClaimStatus(String id, {required String status, String? remarks, num? settledAmount}) async {
    if (!_useRealApi) return;
    final Map<String, dynamic> body = {
      'status': status,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks,
    };
    if (settledAmount != null) body['settledAmount'] = settledAmount;
    await _client.dio.patch('${ApiConstants.claims}/$id/status', data: body);
  }

  // --- Document Upload ---
  Future<Map<String, dynamic>> uploadDocumentFull(String filePath) async {
    if (!_useRealApi) return {'_id': 'doc_mock_123', 'url': 'https://res.cloudinary.com/demo/image/upload/sample.jpg'};
    final response = await _client.upload(ApiConstants.upload, filePath);
    return response.data['data'] as Map<String, dynamic>;
  }

  // --- Document Downloads ---
  Future<List<int>> downloadPolicyDocument(String policyId) async {
    if (!_useRealApi) {
      await Future.delayed(const Duration(seconds: 1));
      return []; // Return mock bytes
    }

    // Uses ResponseType.bytes to correctly handle the PDF file stream
    final response = await _client.dio.get<List<int>>(
      '/api/policies/$policyId/document',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.data == null) {
      throw Exception('Failed to download document');
    }
    return response.data!;
  }

  // --- Seeding Helpers (Admin Only) ---
  Future<void> seedProductFields(String productId) async {
    if (!_useRealApi) return;
    final existing = await getProductFields(productId);
    if (existing.isNotEmpty) return;

    final standardFields = [
      {'fieldName': 'fullName', 'fieldLabel': 'Full Name', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'mobile', 'fieldLabel': 'Mobile Number', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'email', 'fieldLabel': 'Email Address', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'address', 'fieldLabel': 'Address', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'city', 'fieldLabel': 'City', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'state', 'fieldLabel': 'State', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'pinCode', 'fieldLabel': 'PIN Code', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'capacity', 'fieldLabel': 'Capacity (kW)', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'installDate', 'fieldLabel': 'Installation Date', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'brand', 'fieldLabel': 'Brand', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'installerName', 'fieldLabel': 'Installer Name', 'fieldType': 'TEXT', 'isRequired': true},
      {'fieldName': 'invoice', 'fieldLabel': 'Invoice Copy', 'fieldType': 'FILE', 'isRequired': true},
      {'fieldName': 'sitePhoto1', 'fieldLabel': 'Site Photo 1', 'fieldType': 'FILE', 'isRequired': false},
      {'fieldName': 'sitePhoto2', 'fieldLabel': 'Site Photo 2', 'fieldType': 'FILE', 'isRequired': false},
      {'fieldName': 'sitePhoto3', 'fieldLabel': 'Site Photo 3', 'fieldType': 'FILE', 'isRequired': false},
      {'fieldName': 'sitePhoto4', 'fieldLabel': 'Site Photo 4', 'fieldType': 'FILE', 'isRequired': false},
      {'fieldName': 'siteVideo', 'fieldLabel': 'Site Video', 'fieldType': 'FILE', 'isRequired': false},
      {'fieldName': 'consent', 'fieldLabel': 'I accept terms', 'fieldType': 'CHECKBOX', 'isRequired': true},
      {'fieldName': 'noDamage', 'fieldLabel': 'Product has no damage', 'fieldType': 'CHECKBOX', 'isRequired': true},
    ];

    for (var i = 0; i < standardFields.length; i++) {
      final field = standardFields[i];
      await _client.dio.post(ApiConstants.productFields, data: {
        ...field,
        'product': productId,
        'sortOrder': i,
      });
    }
  }
}