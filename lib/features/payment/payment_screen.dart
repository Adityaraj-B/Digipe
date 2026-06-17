import 'package:flutter/material.dart';

class PaymentPreviewScreen extends StatefulWidget {
  final String product;
  final double basePremium;
  final double gstRate;
  final double processingFee;
  final int years;
  final String applicationId;
  final void Function(double finalAmount)? onPayNow;

  const PaymentPreviewScreen({
    super.key,
    required this.product,
    required this.basePremium,
    this.gstRate = 0.18,
    this.processingFee = 50,
    this.years = 1,
    required this.applicationId,
    this.onPayNow,
  });

  @override
  State<PaymentPreviewScreen> createState() => _PaymentPreviewScreenState();
}

class _PaymentPreviewScreenState extends State<PaymentPreviewScreen> {
  final _couponCtrl = TextEditingController();
  double _discount = 0;
  bool _couponApplied = false;
  bool _couponError = false;
  bool _applying = false;

  static const _validCoupon = 'DIGIPE10';
  static const _discountPct = 0.10;

  double get _gstAmount => widget.basePremium * widget.gstRate;
  double get _subtotal => widget.basePremium + _gstAmount + widget.processingFee;
  double get _total => _subtotal - _discount;

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _applying = true;
      _couponError = false;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (code == _validCoupon) {
      setState(() {
        _discount = _subtotal * _discountPct;
        _couponApplied = true;
        _couponError = false;
        _applying = false;
      });
    } else {
      setState(() {
        _discount = 0;
        _couponApplied = false;
        _couponError = true;
        _applying = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponCtrl.clear();
      _couponApplied = false;
      _couponError = false;
      _discount = 0;
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: const Color(0xFF1A1A1A),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Review your order and proceed to payment',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                  ),
                                  child: const Icon(Icons.credit_card_outlined,
                                      size: 22, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payment Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Transparent price breakup',
                                        style: TextStyle(
                                            fontSize: 12, color: Color(0xFF8E8E93)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                  ),
                                  child: const Text(
                                    'Secure',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, color: Color(0xFFF2F2F7)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Selected Plan',
                                    style: TextStyle(
                                        fontSize: 14, color: Color(0xFF8E8E93))),
                                Text(
                                  widget.product,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _PriceRow(
                              label: 'Base Premium (${widget.years} Year)',
                              value: widget.basePremium,
                            ),
                            const SizedBox(height: 16),
                            _PriceRow(
                              label: 'GST (${(widget.gstRate * 100).toStringAsFixed(0)}%)',
                              value: _gstAmount,
                            ),
                            const SizedBox(height: 16),
                            _PriceRow(
                              label: 'Processing Fee',
                              value: widget.processingFee,
                            ),
                            if (_couponApplied) ...[
                              const SizedBox(height: 16),
                              _PriceRow(
                                label: 'Coupon Discount ($_validCoupon)',
                                value: -_discount,
                                isDiscount: true,
                              ),
                            ],
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _couponError
                                            ? const Color(0xFF1A1A1A)
                                            : _couponApplied
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFE5E5EA),
                                        width: _couponApplied || _couponError ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        Icon(
                                          _couponApplied
                                              ? Icons.check_circle_rounded
                                              : Icons.local_offer_outlined,
                                          size: 20,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _couponCtrl,
                                            enabled: !_couponApplied,
                                            textCapitalization:
                                            TextCapitalization.characters,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A)),
                                            decoration: InputDecoration(
                                              hintText: _couponApplied
                                                  ? '$_validCoupon applied'
                                                  : 'Enter Coupon (Try DIGIPE10)',
                                              hintStyle: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF8E8E93),
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                            onSubmitted: (_) => _applyCoupon(),
                                          ),
                                        ),
                                        if (_couponApplied)
                                          GestureDetector(
                                            onTap: _removeCoupon,
                                            child: const Padding(
                                              padding: EdgeInsets.only(right: 16),
                                              child: Icon(Icons.close_rounded,
                                                  size: 20, color: Color(0xFF8E8E93)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _couponApplied ? null : _applyCoupon,
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: _couponApplied
                                          ? const Color(0xFFF5F5F5)
                                          : const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: _couponApplied
                                          ? Border.all(color: const Color(0xFFE5E5EA))
                                          : null,
                                    ),
                                    child: Center(
                                      child: _applying
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                          : Text(
                                        _couponApplied ? 'Applied' : 'Apply',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _couponApplied
                                              ? const Color(0xFF8E8E93)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_couponError) ...[
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  'Invalid coupon code. Please try again.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: _DashedDivider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Payable',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'All taxes included',
                                      style: TextStyle(
                                          fontSize: 12, color: Color(0xFF8E8E93)),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rs. ${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 14, color: Color(0xFF8E8E93)),
                          const SizedBox(width: 6),
                          Text(
                            'Payments are processed securely via SSL encryption.',
                            style: TextStyle(
                                fontSize: 12, color: const Color(0xFF8E8E93).withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE5E5EA))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onPayNow?.call(_total),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 20, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By clicking "Pay Now", you agree to the terms and conditions.',
                      style: TextStyle(fontSize: 11, color: const Color(0xFF8E8E93).withValues(alpha: 0.8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDiscount;

  const _PriceRow(
      {required this.label, required this.value, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    final formatted = isDiscount
        ? '- Rs. ${value.abs().toStringAsFixed(2)}'
        : 'Rs. ${value.toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF48484A),
              fontWeight: FontWeight.w400,
            )),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE5E5EA)),
              ),
            );
          }),
        );
      },
    );
  }
}