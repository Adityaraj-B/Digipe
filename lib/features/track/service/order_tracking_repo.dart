import '../../../core/services/api_service.dart';
import 'order_tracking_model.dart';

abstract class OrderTrackingRepository {
  Future<OrderTracking> fetchOrder(String orderId);
}

class OrderTrackingApiRepository implements OrderTrackingRepository {
  final ApiService _apiService;
  const OrderTrackingApiRepository(this._apiService);

  @override
  Future<OrderTracking> fetchOrder(String orderId) async {
    try {
      final dynamic response = await _apiService.getMyApplications();

      List<dynamic> myApps = [];
      if (response is List) {
        myApps = response;
      } else if (response is Map && response['data'] != null) {
        myApps = response['data'] as List<dynamic>;
      } else {
        try {
          myApps = (response as dynamic).data as List<dynamic>;
        } catch (_) {}
      }

      if (myApps.isEmpty) {
        throw const ApiException(statusCode: 404);
      }

      final String targetId = orderId.trim();
      dynamic app;

      if (targetId == 'latest') {
        app = myApps.first;
      } else {
        final matches = myApps.where((a) {
          final id = a is Map ? a['_id'] : (a as dynamic).id;
          final appNum = a is Map ? a['applicationNumber'] : (a as dynamic).applicationNumber;
          return id?.toString() == targetId || appNum?.toString() == targetId;
        }).toList();

        if (matches.isEmpty) {
          // Fail loudly instead of silently showing the wrong (latest) application
          throw const ApiException(statusCode: 404);
        }
        app = matches.first;
      }

      final bool isMap = app is Map;
      final status = (isMap ? app['status'] : (app as dynamic).status)?.toString().toUpperCase() ?? 'SUBMITTED';

      final rawDate = isMap ? app['createdAt'] : (app as dynamic).createdAt;
      final createdAt = DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

      dynamic plan = isMap ? app['plan'] : (app as dynamic).plan;
      dynamic product = isMap ? app['product'] : (app as dynamic).product;

      final double premium = double.tryParse(
          (plan is Map ? plan['premium'] : (plan as dynamic)?.premium)?.toString() ?? '0'
      ) ?? 0.0;

      final int duration = int.tryParse(
          (plan is Map ? plan['duration'] : (plan as dynamic)?.duration)?.toString() ?? '12'
      ) ?? 12;

      final String policyType = (product is Map ? product['name'] : (product as dynamic)?.name)?.toString() ?? 'Insurance Policy';

      // NEW: extract the plan's own id so PaymentPreviewScreen can be built later
      final String? planId = (plan is Map
          ? (plan['_id'] ?? plan['id'])
          : (plan as dynamic)?.id)?.toString();

      final outId = (isMap ? app['applicationNumber'] : (app as dynamic).applicationNumber)?.toString()
          ?? (isMap ? app['_id'] : (app as dynamic).id)?.toString()
          ?? targetId;

      final int yearsVal = (duration ~/ 12) == 0 ? 1 : duration ~/ 12; // NEW

      return OrderTracking(
        orderId: outId,
        status: _mapStatus(status),
        policyType: policyType,
        amountPaid: premium,
        purchaseDate: createdAt,
        coveragePeriod: '$yearsVal Year${yearsVal > 1 ? 's' : ''}',
        planId: planId,     // NEW
        years: yearsVal,    // NEW
        lifecycleSteps: _buildLifecycle(status, createdAt),
      );
    } catch (e, st) {
      print('=== REFRESH ERROR ===');
      print(e);
      print(st);
      print('=====================');
      if (e is ApiException) rethrow;
      throw const ApiException(statusCode: 500);
    }
  }

  OrderStatus _mapStatus(String status) {
    switch (status) {
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return OrderStatus.underReview;
      case 'APPROVED':
        return OrderStatus.paymentEligible;
      case 'REJECTED':
        return OrderStatus.rejected;
      default:
        return OrderStatus.pendingApproval;
    }
  }

  List<LifecycleStep> _buildLifecycle(String status, DateTime created) {
    bool isReview = status == 'UNDER_REVIEW' || status == 'APPROVED' || status == 'REJECTED';
    bool isEligible = status == 'APPROVED';
    bool isRejected = status == 'REJECTED';

    return [
      const LifecycleStep(
        title: 'Application Submitted',
        subtitle: 'We have received your request.',
        state: LifecycleStepState.done,
      ),
      LifecycleStep(
        title: 'Under Review',
        subtitle: isRejected ? 'Verification failed.' : 'Verifying your documents.',
        state: isRejected ? LifecycleStepState.done : (isReview ? LifecycleStepState.active : LifecycleStepState.pending),
      ),
      LifecycleStep(
        title: 'Payment Eligible',
        subtitle: isEligible ? 'Waiting for payment.' : 'Pending approval.',
        state: isEligible ? LifecycleStepState.active : LifecycleStepState.pending,
      ),
      const LifecycleStep(
        title: 'Policy Issued',
        subtitle: 'Final step.',
        state: LifecycleStepState.pending,
      ),
    ];
  }
}

class OrderTrackingMockRepository implements OrderTrackingRepository {
  const OrderTrackingMockRepository();

  @override
  Future<OrderTracking> fetchOrder(String orderId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (orderId == 'ERROR') throw const ApiException(statusCode: 500);

    return OrderTracking(
      orderId: orderId,
      status: OrderStatus.underReview,
      policyType: 'Solar Insurance Plan',
      amountPaid: 499.0,
      purchaseDate: DateTime(2026, 6, 12),
      coveragePeriod: '1 Year',
      planId: 'mock_plan_id', // NEW
      years: 1,               // NEW
      lifecycleSteps: const [
        LifecycleStep(
          title: 'Application Submitted',
          subtitle: 'Jun 12, 2026 • 10:30 AM',
          state: LifecycleStepState.done,
        ),
        LifecycleStep(
          title: 'Under Review',
          subtitle: 'Our team is verifying your documents.',
          state: LifecycleStepState.active,
        ),
        LifecycleStep(
          title: 'Payment Eligible',
          subtitle: 'Waiting for approval.',
          state: LifecycleStepState.pending,
        ),
        LifecycleStep(
          title: 'Policy Issued',
          subtitle: 'Final step.',
          state: LifecycleStepState.pending,
        ),
      ],
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  const ApiException({required this.statusCode});
}