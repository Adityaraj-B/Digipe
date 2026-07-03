import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;

import '../../../core/services/api_service.dart';
import '../../../core/services/payment_service.dart';
import 'service/verification_screen.dart';

class PaymentPreviewScreen extends StatefulWidget {
  final String product;
  final double basePremium;
  final int years;
  final String planId;          // ← ADD this
  final String applicationId;
  final Map<String, dynamic> orderData;

  const PaymentPreviewScreen({
    super.key,
    required this.product,
    required this.basePremium,
    required this.years,
    required this.planId,       // ← ADD this
    required this.applicationId,
    required this.orderData,
  });

  @override
  State<PaymentPreviewScreen> createState() => _PaymentPreviewScreenState();
}

class _PaymentPreviewScreenState extends State<PaymentPreviewScreen> {
  final _couponCtrl = TextEditingController();
  
  // SECTION 4: Payment Amount Security (Use Server Values)
  late double _subtotal;
  late double _taxAmount;
  late double _discountAmount;
  late double _totalAmount;
  
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // SECTION 7: Prevent screen capture
    ScreenProtector.preventScreenshotOn();
    
    _subtotal = (widget.orderData['subtotal'] ?? widget.basePremium).toDouble();
    _taxAmount = (widget.orderData['taxAmount'] ?? 0).toDouble();
    _discountAmount = (widget.orderData['discountAmount'] ?? 0).toDouble();
    _totalAmount = (widget.orderData['totalAmount'] ?? (_subtotal + _taxAmount)).toDouble();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _couponCtrl.dispose();
    super.dispose();
  }

  // SECTION 8: Biometric Lock for Payment
  Future<bool> _authenticateForPayment() async {
    final auth = LocalAuthentication();
    try {
      final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) return true; 

      return await auth.authenticate(
        localizedReason: 'Confirm identity to pay ₹${_totalAmount.toStringAsFixed(0)}',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback
          stickyAuth: true,
        ),
      );
    } catch (e) {
      dev.log('Biometric error: $e');
      return true; // Fallback
    }
  }

  Future<void> _initiatePayment() async {
    final confirmed = await _authenticateForPayment();
    if (!confirmed) return;

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final apiService = context.read<ApiService>();
      final paymentService = PaymentService(
        apiService,
        const FlutterSecureStorage(),
      );

      await paymentService.startPayment(
        context: context,
        planId: widget.planId,              // ← use widget.planId directly
        applicationId: widget.applicationId,
        // NO preCreatedOrder — removed entirely
        onSuccess: () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                orderId: widget.orderData['_id'] ??
                    widget.orderData['id'] ?? '',
              ),
            ),
          );
        },
        onFailure: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed or cancelled. Please try again.'),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Payment Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE5E5EA))),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.credit_card_outlined, size: 22),
                          SizedBox(width: 12),
                          Expanded(child: Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                        ]),
                        const Divider(height: 48),
                        _PriceRow(label: 'Product', valueText: widget.product, isBold: true),
                        _PriceRow(label: 'Base Premium', value: _subtotal),
                        _PriceRow(label: 'GST', value: _taxAmount),
                        if (_discountAmount > 0) _PriceRow(label: 'Discount', value: -_discountAmount, isDiscount: true),
                        const Divider(height: 48),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('Rs. ${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E5EA)))),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueText;
  final bool isBold;
  final bool isDiscount;

  const _PriceRow({required this.label, this.value, this.valueText, this.isBold = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
        Text(valueText ?? 'Rs. ${value?.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: isDiscount ? Colors.green : Colors.black)),
      ]),
    );
  }
}
