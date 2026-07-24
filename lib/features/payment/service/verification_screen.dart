import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../orders/bloc/orders_bloc.dart';
import '../../track/screens/track_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/payment_resolution_service.dart';

enum _VerifyStep { resolving, verifying, fetchingPolicy, done, failed }

class PaymentVerifyingScreen extends StatefulWidget {
  final String? internalOrderId;
  final String? cashfreeOrderId;

  const PaymentVerifyingScreen({super.key, this.internalOrderId, this.cashfreeOrderId});

  @override
  State<PaymentVerifyingScreen> createState() => _PaymentVerifyingScreenState();
}

class _PaymentVerifyingScreenState extends State<PaymentVerifyingScreen>
    with SingleTickerProviderStateMixin {
  _VerifyStep _step = _VerifyStep.resolving;
  late AnimationController _rotateCtrl;
  Timer? _pollingTimer;
  String? _resolvedId;

  @override
  void initState() {
    super.initState();
    // SECTION 7: Prevent OS-level screen capture
    ScreenProtector.preventScreenshotOn();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initFlow();
  }

  Future<void> _initFlow() async {
    _resolvedId = widget.internalOrderId;
    
    if (_resolvedId == null && widget.cashfreeOrderId != null) {
      final resolutionService = PaymentResolutionService(context.read<ApiService>());
      _resolvedId = await resolutionService.resolveInternalOrderId(widget.cashfreeOrderId!);
    }

    if (!mounted) return;

    if (_resolvedId == null) {
      setState(() => _step = _VerifyStep.failed);
      return;
    }

    setState(() => _step = _VerifyStep.verifying);
    _startPolling();
  }

  void _startPolling() {
    int attempts = 0;
    const maxAttempts = 30; // 30 × 3s = 90s max
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > maxAttempts) {
        timer.cancel();
        if (mounted) setState(() => _step = _VerifyStep.failed);
        return;
      }
      try {
        final status = await context.read<ApiService>().getPaymentStatus(_resolvedId!);
        final normalized = status.toUpperCase();
        
        if (normalized == 'SUCCESS' || normalized == 'PAID' || normalized == 'COMPLETED') {
          timer.cancel();
          _onSuccess();
        } else if (normalized == 'FAILED' || normalized == 'CANCELLED' || normalized == 'EXPIRED') {
          timer.cancel();
          if (mounted) setState(() => _step = _VerifyStep.failed);
        }
      } catch (_) {
        // Continue polling on transient network errors
      }
    });
  }

  Future<void> _onSuccess() async {
    if (!mounted) return;
    setState(() => _step = _VerifyStep.fetchingPolicy);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    context.read<OrdersBloc>().add(FetchOrders());
    setState(() => _step = _VerifyStep.done);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(orderId: _resolvedId!),
      ),
    );
  }

  String get _statusText => switch (_step) {
    _VerifyStep.resolving => 'Resolving your order details...',
    _VerifyStep.verifying => 'Verifying your payment with Cashfree...',
    _VerifyStep.fetchingPolicy => 'Payment confirmed! Issuing your policy...',
    _VerifyStep.done => 'All done! Redirecting...',
    _VerifyStep.failed => 'Payment could not be confirmed.\nPlease check My Policies or contact support.',
  };

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _rotateCtrl.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: _step == _VerifyStep.failed,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _DigiPeHeader(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_step == _VerifyStep.failed) ...[
                      const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
                      const SizedBox(height: 24),
                      Text('Verification Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 10),
                      Text(_statusText, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else ...[
                      RotationTransition(
                        turns: _rotateCtrl,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                          ),
                          child: Icon(Icons.schedule_rounded, size: 32, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Order Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(_statusText, key: ValueKey(_step), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text('© 2026, Made with ❤ by DIGIPe', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _DigiPeHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEAF3DE), border: Border.all(color: const Color(0xFF3B6D11), width: 2)),
                      child: const Icon(Icons.check_rounded, size: 40, color: Color(0xFF3B6D11)),
                    ),
                    const SizedBox(height: 20),
                    Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text('Your insurance policy has been issued successfully.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE))),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Internal Order ID', value: orderId),
                          Divider(height: 20, color: Theme.of(context).dividerColor),
                          const _SummaryRow(label: 'Status', value: 'CONFIRMED', valueBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId))),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_outlined, size: 18, color: isDark ? Colors.black : Colors.white), const SizedBox(width: 8), Text('View Order & Track', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.black : Colors.white))]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;
  const _SummaryRow({required this.label, required this.value, this.valueBold = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'monospace')))]);
  }
}

class _DigiPeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [Text('DIGIPE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface)), const Spacer(), CircleAvatar(radius: 16, backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A), child: Icon(Icons.person, size: 18, color: isDark ? Colors.black : Colors.white))]),
    );
  }
}
