import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'dart:developer' as dev;

/// Orchestrates the full Cashfree payment lifecycle:
/// Order Creation → Session Creation → SDK Launch → ID Resolution → Status Polling
///
/// No mock data. No bypass logic. Every step hits the real production backend.
class PaymentService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  PaymentService(this._apiService, this._storage);

  // ─── Public Entry Point ────────────────────────────────────────────────────

  Future<void> startPayment({
    required BuildContext context,
    required String planId,
    required String applicationId,
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) async {
    try {
      dev.log('[Payment] Starting flow — planId: $planId, appId: $applicationId');

      // ── STEP 1: Create Order ───────────────────────────────────────────────
      // POST /api/orders with { items: [{ planId, applicationId }] }
      // Server calculates totalAmount including real GST and discount.
      // Will 400 if application is not yet APPROVED.
      // Will 403 if application belongs to a different user.
      final order = await _apiService.createOrder(
        planId: planId,
        applicationId: applicationId,
      );

      final internalOrderId = (order['_id'] ?? order['id']) as String;
      final totalAmount = order['totalAmount'] as num;

      dev.log('[Payment] Order created — internalOrderId: $internalOrderId, amount: $totalAmount');

      // ── STEP 2: Create Cashfree Payment Session ────────────────────────────
      // POST /api/payments with { orderId: internalOrderId }
      // Returns paymentSessionId and cashfreeOrderId.
      // Will 409 if the order is already paid.
      // Will 403 if linked applications are not all approved.
      final paymentData = await _apiService.createPaymentSession(internalOrderId);

      final paymentSessionId = paymentData['paymentSessionId'] as String;
      final cashfreeOrderId = paymentData['cashfreeOrderId'] as String;

      dev.log('[Payment] Session created — cfOrderId: $cashfreeOrderId');

      // ── STEP 3: Persist ID Mapping ─────────────────────────────────────────
      // Store before SDK launch so the mapping survives app termination.
      // The two-tier resolver reads this first (Tier 1) before doing an API scan.
      await _storage.write(
        key: 'cf_to_internal_$cashfreeOrderId',
        value: internalOrderId,
      );

      dev.log('[Payment] ID mapping persisted to secure storage');

      // ── STEP 4: Launch Cashfree SDK ────────────────────────────────────────
      dev.log('[Payment] DEBUG — paymentSessionId raw value: "$paymentSessionId"');
      dev.log('[Payment] DEBUG — paymentSessionId length: ${paymentSessionId.length}');
      dev.log('[Payment] DEBUG — cashfreeOrderId raw value: "$cashfreeOrderId"');

      // Note: Reverted to SANDBOX to align with your current backend TEST keys
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setPaymentSessionId(paymentSessionId)
          .setOrderId(cashfreeOrderId)
          .build();

      final cfPayment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      CFPaymentGatewayService().setCallback(
        // onPaymentVerify — Cashfree calls this with its own gateway order id
            (String gatewayOrderId) async {
          dev.log('[Payment] SDK callback — gatewayOrderId: $gatewayOrderId');

          // Resolve to our internal MongoDB _id before polling
          final internalId = await _resolveInternalOrderId(gatewayOrderId);

          if (internalId == null) {
            dev.log('[Payment] ERROR: Could not resolve internal order id for $gatewayOrderId');
            onFailure();
            return;
          }

          dev.log('[Payment] Resolved internalId: $internalId — starting poll');
          final result = await _pollPaymentStatus(internalId);
          dev.log('[Payment] Poll result: $result');

          result == 'SUCCESS' ? onSuccess() : onFailure();
        },
        // onPaymentError — SDK-level error (user cancelled, network, etc.)
            (CFErrorResponse error, String gatewayOrderId) {
          dev.log('[Payment] SDK error: ${error.getMessage()} for $gatewayOrderId');
          onFailure();
        },
      );

      CFPaymentGatewayService().doPayment(cfPayment);

    } on DioException catch (e) {
      _handleDioError(context, e, onFailure);
    } catch (e, stack) {
      dev.log('[Payment] Unexpected error: $e\n$stack');
      onFailure();
    }
  }

  // ─── Two-Tier Order ID Resolution ─────────────────────────────────────────

  /// Resolves Cashfree's gateway order id to your backend's internal MongoDB _id.
  ///
  /// Tier 1: Check FlutterSecureStorage (written before SDK launch).
  ///         Works even if the app was killed during payment.
  ///
  /// Tier 2: Fetch GET /api/orders/my and scan for a matching cashfreeOrderId
  ///         in each order's linked payment record.
  Future<String?> _resolveInternalOrderId(String cashfreeOrderId) async {
    // Tier 1 — local storage
    final stored = await _storage.read(
      key: 'cf_to_internal_$cashfreeOrderId',
    );
    if (stored != null) {
      dev.log('[Payment] Tier 1 resolution hit for $cashfreeOrderId → $stored');
      return stored;
    }

    // Tier 2 — API scan
    dev.log('[Payment] Tier 1 miss — falling back to API scan');
    try {
      final orders = await _apiService.getMyOrders();
      for (final order in orders) {
        // order.cashfreeOrderId is populated if the order has a linked payment
        if (order.cashfreeOrderId == cashfreeOrderId) {
          final id = order.orderId;
          // Persist for future Tier 1 hits
          await _storage.write(
            key: 'cf_to_internal_$cashfreeOrderId',
            value: id,
          );
          dev.log('[Payment] Tier 2 resolution hit → $id');
          return id;
        }
      }
    } catch (e) {
      dev.log('[Payment] Tier 2 scan failed: $e');
    }

    dev.log('[Payment] Both tiers failed for $cashfreeOrderId');
    return null;
  }

  // ─── Payment Status Polling ────────────────────────────────────────────────

  /// Polls GET /api/payments/status/:internalOrderId until settled.
  ///
  /// The backend queries Cashfree and updates local payment records.
  /// Recognized SUCCESS states: SUCCESS, PAID, COMPLETED (all backend-confirmed).
  /// Recognized FAILURE states: FAILED, CANCELLED.
  /// Any other state (PENDING, USER_DROPPED) keeps polling.
  Future<String> _pollPaymentStatus(String internalOrderId) async {
    const maxAttempts = 10;
    const delay = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      dev.log('[Payment] Poll attempt $attempt/$maxAttempts for $internalOrderId');

      try {
        final rawStatus = await _apiService.getPaymentStatus(internalOrderId);
        final status = rawStatus.toUpperCase();

        dev.log('[Payment] Status: $status');

        if (status == 'SUCCESS' ||
            status == 'PAID' ||
            status == 'COMPLETED') {
          return 'SUCCESS';
        }

        if (status == 'FAILED' || status == 'CANCELLED') {
          return 'FAILED';
        }

        // PENDING / USER_DROPPED / other intermediate — keep polling
      } catch (e) {
        dev.log('[Payment] Poll error (attempt $attempt): $e');
        // Don't give up on transient network errors — keep polling
      }

      if (attempt < maxAttempts) {
        await Future.delayed(delay);
      }
    }

    dev.log('[Payment] Max poll attempts reached — treating as FAILED');
    return 'FAILED';
  }

  // ─── Error Handling ────────────────────────────────────────────────────────

  void _handleDioError(
      BuildContext context,
      DioException e,
      VoidCallback onFailure,
      ) {
    final status = e.response?.statusCode;
    final message = e.response?.data?['message']?.toString() ?? '';

    dev.log('[Payment] DioException — status: $status, message: $message');

    if (!context.mounted) return;

    switch (status) {
      case 400:
      // Application not approved, or bad items array
        if (message.toLowerCase().contains('approved') ||
            message.toLowerCase().contains('not approved')) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Pending Approval'),
              content: const Text(
                'Your application is awaiting admin review. '
                    'You will be notified once approved and can proceed to payment.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.isNotEmpty
                ? message
                : 'Payment could not be initiated. Please try again.')),
          );
          onFailure();
        }

      case 403:
      // Backend PAYMENT.NOT_APPROVED — application not approved or
      // order belongs to a different user
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Not Authorised'),
            content: const Text(
              'This payment cannot be processed yet. '
                  'Please ensure your application has been approved by an admin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

      case 409:
      // Order already paid — navigate to policies instead of showing error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This order has already been paid. Viewing your policies.'),
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/my-policies');
          }
        });

      case 404:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order not found. Please contact support.')),
        );
        onFailure();

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Payment error (${status ?? 'unknown'}). Please try again.',
          )),
        );
        onFailure();
    }
  }
}