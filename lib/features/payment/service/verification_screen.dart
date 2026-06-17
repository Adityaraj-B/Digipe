// ─────────────────────────────────────────────────────────────────────────────
// payment_verifying_screen.dart
//
// Shown immediately after the payment gateway redirects back.
// Polls / awaits backend verification, then navigates to success or failure.
//
// Usage:
//   Navigator.pushReplacement(context, MaterialPageRoute(
//     builder: (_) => PaymentVerifyingScreen(orderId: 'cf_ORD-...'),
//   ));
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../orders/bloc/orders_bloc.dart';
import '../../track/screens/track_screen.dart';

enum _VerifyStep { verifying, fetchingPolicy, done, failed }

class PaymentVerifyingScreen extends StatefulWidget {
  final String orderId;

  const PaymentVerifyingScreen({super.key, required this.orderId});

  @override
  State<PaymentVerifyingScreen> createState() => _PaymentVerifyingScreenState();
}

class _PaymentVerifyingScreenState extends State<PaymentVerifyingScreen>
    with SingleTickerProviderStateMixin {
  _VerifyStep _step = _VerifyStep.verifying;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _runFlow();
  }

  Future<void> _runFlow() async {
    // Step 1 – verify payment (mock 1.5 s)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _step = _VerifyStep.fetchingPolicy);

    // Step 2 – fetch policy (mock 1.2 s)
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // INTERCONNECTION: Add the order to the OrdersBloc
    // In a real app, this data would come from the verification API
    context.read<OrdersBloc>().add(AddOrder(
      OrderSummary(
        orderId: widget.orderId,
        product: 'Solar Insurance Plan', // Should be dynamic
        amount: 'Rs. 999', // Should be dynamic
        date: 'Jun 13, 2026',
        status: 'Active',
        canClaim: true,
      ),
    ));

    setState(() => _step = _VerifyStep.done);

    // Navigate to success
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(orderId: widget.orderId),
      ),
    );
  }

  String get _statusText => switch (_step) {
    _VerifyStep.verifying => 'Verifying your payment...',
    _VerifyStep.fetchingPolicy => 'Payment verified! Fetching your policy...',
    _VerifyStep.done => 'All done!',
    _VerifyStep.failed => 'Verification failed. Please contact support.',
  };

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Minimal header matching DIGIPe nav
            _DigiPeHeader(),
            const Spacer(),
            // Verification card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 48, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated clock icon
                    RotationTransition(
                      turns: _rotateCtrl,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1A1A1A), width: 2),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          size: 32,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verifying Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusText,
                        key: ValueKey(_step),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '© 2026, Made with ❤ by DIGIPe',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// payment_success_screen.dart  (same file for convenience)
// ─────────────────────────────────────────────────────────────────────────────

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;

  // These would normally come from your API response / route params
  final String policyNumber;
  final double amountPaid;
  final String productName;
  final String status;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    this.policyNumber = 'POL-3B668B7A',
    this.amountPaid = 1110.82,
    this.productName = 'amit yadssv',
    this.status = 'Active',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _DigiPeHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                child: Column(
                  children: [
                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEAF3DE),
                        border: Border.all(
                            color: const Color(0xFF3B6D11), width: 2),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 40, color: Color(0xFF3B6D11)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your $productName policy has been issued successfully.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                          height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // Order summary card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _SummaryRow(
                              label: 'Order ID', value: orderId),
                          const Divider(height: 20, color: Color(0xFFF0F0F0)),
                          _SummaryRow(
                              label: 'Policy Number',
                              value: policyNumber),
                          const Divider(height: 20, color: Color(0xFFF0F0F0)),
                          _SummaryRow(
                              label: 'Amount Paid',
                              value: 'Rs. ${amountPaid.toStringAsFixed(2)}',
                              valueBold: true),
                          const Divider(height: 20, color: Color(0xFFF0F0F0)),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF888888))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4EDDA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF155724),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Next steps card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Steps',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 14),
                          _NextStepItem(
                            number: '1',
                            text:
                            'Our team will review the uploaded documents within 24–48 hours.',
                          ),
                          const SizedBox(height: 12),
                          _NextStepItem(
                            number: '2',
                            text:
                            'You can download the digital copy of your policy below.',
                          ),
                          const SizedBox(height: 12),
                          _NextStepItem(
                            number: '3',
                            text:
                            'In case of damage, you can raise a claim from the order tracking screen.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(
                                orderId: orderId),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'View Order & Track',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_outlined,
                                size: 18, color: Color(0xFF1A1A1A)),
                            SizedBox(width: 8),
                            Text(
                              'Download Policy',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
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

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;

  const _SummaryRow(
      {required this.label,
        required this.value,
        this.valueBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF888888))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
              valueBold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1A1A1A),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _NextStepItem extends StatelessWidget {
  final String number;
  final String text;

  const _NextStepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.5)),
        ),
      ],
    );
  }
}

// ─── DIGIPe shared nav bar ────────────────────────────────────────────────────

class _DigiPeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Text(
            'DIGIPE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFCCCCCC),
          ),
          const Text(
            'Hello, +917206787699',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF1A1A1A),
            child: Text('N',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Verification screen updated to use real OrderTrackingScreen from imports
