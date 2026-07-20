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
      // 1. Fetch from all three endpoints concurrently (mimicking Next.js Promise.allSettled)
      final results = await Future.wait([
        _apiService.getMyPoliciesRaw().catchError((_) => <Map<String, dynamic>>[]),
        _apiService.getMyClaims().catchError((_) => <Map<String, dynamic>>[]),
        _apiService.getMyApplications().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final List<Map<String, dynamic>> policiesList = results[0].cast<Map<String, dynamic>>();
      final List<Map<String, dynamic>> claimsList = results[1].cast<Map<String, dynamic>>();
      final List<Map<String, dynamic>> applicationsList = results[2].cast<Map<String, dynamic>>();

      final String targetId = orderId.trim();
      Map<String, dynamic>? foundPol;
      Map<String, dynamic>? foundApp;

      // 2. Matching Logic
      if (targetId == 'latest') {
        // Aggregate active items, filter unmapped apps, sort by date
        final allItems = <Map<String, dynamic>>[];

        for (var p in policiesList) {
          p['_type'] = 'policy';
          p['_sortDate'] = DateTime.tryParse(p['startDate'] ?? p['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          allItems.add(p);
        }

        for (var a in applicationsList) {
          final appId = (a['_id'] ?? a['id'])?.toString();
          // Skip applications that have been converted to policies
          final isMappedToPol = policiesList.any((pol) {
            final polApp = pol['application'];
            final polAppId = polApp is Map ? polApp['_id'] : polApp;
            return polAppId?.toString() == appId;
          });

          if (!isMappedToPol) {
            a['_type'] = 'application';
            a['_sortDate'] = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            allItems.add(a);
          }
        }

        allItems.sort((a, b) {
          final dateA = a['_sortDate'] as DateTime;
          final dateB = b['_sortDate'] as DateTime;
          return dateB.compareTo(dateA);
        });
        
        if (allItems.isNotEmpty) {
          final top = allItems.first;
          if (top['_type'] == 'policy') {
            foundPol = top;
          } else {
            foundApp = top;
          }
        }
      } else {
        // Step 2A: Search Policies
        foundPol = policiesList.where((p) {
          final polNo = p['policyNumber']?.toString();
          final id = p['_id']?.toString();
          final app = p['application'];
          final appId = app is Map ? app['_id']?.toString() : app?.toString();
          final appNo = app is Map ? app['applicationNumber']?.toString() : null;

          return polNo == targetId || id == targetId || appId == targetId || appNo == targetId;
        }).firstOrNull;

        // Step 2B: Search Applications if Policy not found
        if (foundPol == null) {
          foundApp = applicationsList.where((a) {
            return a['applicationNumber']?.toString() == targetId ||
                a['_id']?.toString() == targetId ||
                a['id']?.toString() == targetId;
          }).firstOrNull;
        }
      }

      if (foundPol == null && foundApp == null) {
        throw const ApiException(statusCode: 404);
      }

      // 3. Assemble and Return Data (Policy View vs Application View)
      if (foundPol != null) {
        return _buildPolicyTracking(foundPol, claimsList);
      } else {
        return _buildApplicationTracking(foundApp!);
      }

    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException(statusCode: 500);
    }
  }

  OrderTracking _buildPolicyTracking(Map<String, dynamic> pol, List<Map<String, dynamic>> claimsList) {
    // Check for active claims overriding the policy status
    final activeClaim = claimsList.where((c) {
      final cp = c['policy'];
      final cpId = cp is Map ? cp['_id']?.toString() : cp?.toString();
      return cpId == pol['_id']?.toString();
    }).firstOrNull;

    OrderStatus status = OrderStatus.active;
    final rawStatus = pol['status']?.toString().toUpperCase();

    if (rawStatus == 'EXPIRED') status = OrderStatus.expired;
    if (rawStatus == 'CANCELLED') status = OrderStatus.cancelled;

    if (activeClaim != null) {
      final claimStatus = activeClaim['status']?.toString().toUpperCase();
      if (claimStatus == 'SUBMITTED' || claimStatus == 'UNDER_REVIEW') {
        status = OrderStatus.claimRaised;
      } else if (claimStatus == 'APPROVED' || claimStatus == 'SETTLED') {
        status = OrderStatus.claimApproved;
      }
    }

    final plan = pol['plan'];
    final product = plan is Map ? plan['product'] : null;
    final policyType = product is Map ? product['name']?.toString() : 'Solar Insurance';

    final startDate = DateTime.tryParse(pol['startDate']?.toString() ?? '') ?? DateTime.now();
    final endDate = DateTime.tryParse(pol['endDate']?.toString() ?? '') ?? startDate.add(const Duration(days: 365));
    final yearsVal = (endDate.difference(startDate).inDays / 365).round().clamp(1, 10);

    return OrderTracking(
      orderId: pol['policyNumber']?.toString() ?? pol['_id']?.toString() ?? 'Unknown ID',
      dbId: pol['_id']?.toString() ?? '',
      status: status,
      policyType: policyType ?? 'Insurance Policy',
      amountPaid: double.tryParse(pol['premium']?.toString() ?? '0') ?? 0.0,
      purchaseDate: startDate,
      coveragePeriod: '$yearsVal Year${yearsVal > 1 ? 's' : ''}',
      years: yearsVal,
      lifecycleSteps: _buildPolicyLifecycle(status, startDate),
    );
  }

  OrderTracking _buildApplicationTracking(Map<String, dynamic> app) {
    final rawStatus = app['status']?.toString().toUpperCase() ?? 'SUBMITTED';
    OrderStatus status = OrderStatus.pendingApproval;

    if (rawStatus == 'APPROVED') status = OrderStatus.paymentEligible;
    if (rawStatus == 'REJECTED') status = OrderStatus.rejected;
    if (rawStatus == 'UNDER_REVIEW') status = OrderStatus.underReview;

    final plan = app['plan'];
    final product = app['product'] ?? (plan is Map ? plan['product'] : null);
    final policyType = product is Map ? product['name']?.toString() : 'Solar Insurance';

    final double premium = double.tryParse(
        (plan is Map ? plan['premium'] : app['amountPaid'])?.toString() ?? '0'
    ) ?? 0.0;

    final int duration = int.tryParse((plan is Map ? plan['duration'] : '12')?.toString() ?? '12') ?? 12;
    final int yearsVal = (duration ~/ 12) == 0 ? 1 : (duration ~/ 12);

    final createdAt = DateTime.tryParse(app['createdAt']?.toString() ?? '') ?? DateTime.now();
    final planId = plan is Map ? plan['_id']?.toString() : plan?.toString();

    return OrderTracking(
      orderId: app['applicationNumber']?.toString() ?? app['_id']?.toString() ?? 'Unknown ID',
      dbId: app['_id']?.toString() ?? app['id']?.toString() ?? '',
      status: status,
      policyType: policyType ?? 'Insurance Policy',
      amountPaid: premium,
      purchaseDate: createdAt,
      coveragePeriod: '$yearsVal Year${yearsVal > 1 ? 's' : ''}',
      planId: planId,
      years: yearsVal,
      lifecycleSteps: _buildApplicationLifecycle(status, createdAt),
    );
  }

  List<LifecycleStep> _buildApplicationLifecycle(OrderStatus status, DateTime date) {
    if (status == OrderStatus.pendingApproval || status == OrderStatus.underReview) {
      return [
        const LifecycleStep(title: 'Application Submitted', subtitle: 'Completed', state: LifecycleStepState.done),
        const LifecycleStep(title: 'Under Document Review', subtitle: 'In Progress', state: LifecycleStepState.active),
        const LifecycleStep(title: 'Payment Eligibility', subtitle: 'Pending Verification', state: LifecycleStepState.pending),
        const LifecycleStep(title: 'Policy Generation', subtitle: 'Pending Approval', state: LifecycleStepState.pending),
      ];
    } else if (status == OrderStatus.paymentEligible || status == OrderStatus.approved) {
      return [
        const LifecycleStep(title: 'Application Submitted', subtitle: 'Completed', state: LifecycleStepState.done),
        const LifecycleStep(title: 'Documents Verified', subtitle: 'Completed', state: LifecycleStepState.done),
        const LifecycleStep(title: 'Awaiting Payment', subtitle: 'Ready to Pay', state: LifecycleStepState.active),
        const LifecycleStep(title: 'Policy Generation', subtitle: 'Pending Payment', state: LifecycleStepState.pending),
      ];
    } else if (status == OrderStatus.rejected) {
      return [
        const LifecycleStep(title: 'Application Submitted', subtitle: 'Completed', state: LifecycleStepState.done),
        const LifecycleStep(title: 'Application Reviewed', subtitle: 'Failed', state: LifecycleStepState.failed),
        const LifecycleStep(title: 'Rejection Reason', subtitle: 'Does not meet requirements', state: LifecycleStepState.active),
      ];
    }
    return [];
  }

  List<LifecycleStep> _buildPolicyLifecycle(OrderStatus status, DateTime date) {
    String currentTitle = 'Policy Active';
    if (status == OrderStatus.claimRaised) currentTitle = 'Claim Pending Review';
    if (status == OrderStatus.claimApproved) currentTitle = 'Claim Settled';
    if (status == OrderStatus.expired) currentTitle = 'Policy Expired';
    if (status == OrderStatus.cancelled) currentTitle = 'Policy Cancelled';

    return [
      const LifecycleStep(title: 'Order Placed', subtitle: 'Completed', state: LifecycleStepState.done),
      const LifecycleStep(title: 'Payment Successful', subtitle: 'Completed', state: LifecycleStepState.done),
      const LifecycleStep(title: 'Document Verification', subtitle: 'Completed', state: LifecycleStepState.done),
      LifecycleStep(
        title: 'Policy Issued',
        subtitle: status == OrderStatus.cancelled ? 'Failed' : 'Completed',
        state: status == OrderStatus.cancelled ? LifecycleStepState.failed : LifecycleStepState.done,
      ),
      LifecycleStep(
        title: currentTitle,
        subtitle: 'Current Status',
        state: LifecycleStepState.active,
      ),
    ];
  }
}

class ApiException implements Exception {
  final int statusCode;
  const ApiException({required this.statusCode});
}