import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/voucher_service.dart';
import '../models/voucher_models.dart';
import 'voucher_processing_screen.dart';

class VoucherDetailScreen extends StatefulWidget {
  final String productId;
  const VoucherDetailScreen({super.key, required this.productId});

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  static const _ink = Color(0xFF1A1A1A);
  static const _bg = Color(0xFFF4F6FB);

  GiftCardBrand? _brand;
  bool _isLoading = true;
  String? _error;

  num? _selectedDenomination;
  int _quantity = 1;
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    _loadBrand();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBrand() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final brand = await context.read<VoucherService>().getBrandDetail(widget.productId);
      setState(() {
        _brand = brand;
        _isLoading = false;
        if (brand.isFixed && brand.denominations != null && brand.denominations!.isNotEmpty) {
          _selectedDenomination = brand.denominations!.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load brand details.';
        _isLoading = false;
      });
    }
  }

  void _onAmountChanged(String value) {
    if (_brand == null) return;
    final amount = num.tryParse(value);
    setState(() {
      _selectedDenomination = amount;
      if (amount == null) {
        _amountError = value.isEmpty ? null : 'Please enter a valid amount';
      } else if (!_brand!.isValidAmount(amount)) {
        _amountError = 'Amount must be between ₹${_brand!.minVoucherAmount} and ₹${_brand!.maxVoucherAmount}';
      } else {
        _amountError = null;
      }
    });
  }

  bool get _isSelectionValid {
    if (_brand == null || _selectedDenomination == null) return false;
    if (!_brand!.isValidAmount(_selectedDenomination!)) return false;

    final total = _selectedDenomination! * _quantity;
    if (_brand!.minOrderAmount != null && total < _brand!.minOrderAmount!) return false;
    if (_brand!.maxOrderAmount != null && total > _brand!.maxOrderAmount!) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFBFCFE), Color(0xFFE8EEF6)],
                ),
              ),
            ),
          ),
          // Soft decorative glow, purely tonal — keeps the existing palette.
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isLoading
                ? _buildLoadingView()
                : _error != null
                ? _buildErrorView()
                : _buildContent(),
          ),

          if (_brand != null && !_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      key: ValueKey('loading'),
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: _ink,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      key: const ValueKey('content'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Select amount', subtitle: 'Choose or enter a value'),
                const SizedBox(height: 20),
                _brand!.isFixed ? _buildFixedDenominations() : _buildFlexibleInput(),
                const SizedBox(height: 40),
                _buildQuantityStepper(),
                const SizedBox(height: 40),
                _buildInstructions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _ink),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8),
        child: _buildGlassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 128,
                      height: 128,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.10),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: CachedNetworkImage(
                          imageUrl: _brand!.thumbnailUrl ?? '',
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 250),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _brand!.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: _ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            _brand!.redemptionTypeName,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.55),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 17, color: _ink),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedDenominations() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _brand!.denominations!.map((d) {
        final isSelected = _selectedDenomination == d;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDenomination = d);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? _ink : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _ink : Colors.white,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                else
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: isSelected
                      ? const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  )
                      : const SizedBox.shrink(),
                ),
                Text(
                  '₹$d',
                  style: TextStyle(
                    color: isSelected ? Colors.white : _ink,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlexibleInput() {
    final isFocused = _amountFocusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isFocused ? 0.85 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFocused ? _ink.withValues(alpha: 0.7) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: isFocused ? 0.08 : 0.04),
            blurRadius: isFocused ? 26 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _amountController,
        focusNode: _amountFocusNode,
        onChanged: _onAmountChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: _ink,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        decoration: InputDecoration(
          prefixText: '₹  ',
          prefixStyle: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
          hintText: 'Enter amount',
          hintStyle: TextStyle(
            color: _ink.withValues(alpha: 0.28),
            fontWeight: FontWeight.w500,
          ),
          errorText: _amountError,
          errorStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          helperText: 'Min ₹${_brand!.minVoucherAmount}   ·   Max ₹${_brand!.maxVoucherAmount}',
          helperStyle: TextStyle(
            color: _ink.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildStepperButton(
                  icon: Icons.remove_rounded,
                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                SizedBox(
                  width: 40,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_quantity',
                      key: ValueKey(_quantity),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ),
                _buildStepperButton(
                  icon: Icons.add_rounded,
                  onTap: (_brand!.maxVouchersPerOrder == null || _quantity < _brand!.maxVouchersPerOrder!)
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: onTap == null ? Colors.transparent : _bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? _ink.withValues(alpha: 0.2) : _ink,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    if (_brand!.howToUseInstructions == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('How to redeem'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 14, top: 2),
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 17, color: _ink),
              ),
              Expanded(
                child: Text(
                  _brand!.howToUseInstructions!,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.7),
                    height: 1.65,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 22,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _ink.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final total = (_selectedDenomination ?? 0) * _quantity;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 22, 24, MediaQuery.paddingOf(context).bottom + 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.06),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        color: _ink.withValues(alpha: 0.45),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '₹$total',
                        key: ValueKey(total),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSelectionValid
                      ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoucherProcessingScreen(
                          productId: _brand!.productId,
                          denominationDetails: [
                            {'denomination': _selectedDenomination!.toInt(), 'quantity': _quantity}
                          ],
                        ),
                      ),
                    );
                  }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _ink.withValues(alpha: 0.1),
                    disabledForegroundColor: _ink.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ).copyWith(
                    shadowColor: WidgetStateProperty.all(_ink.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Redeem Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline_rounded, size: 40, color: _ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _loadBrand,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}