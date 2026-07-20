import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/voucher_bloc.dart';
import '../models/voucher_models.dart';
import 'voucher_detail_screen.dart';

class VoucherCatalogScreen extends StatefulWidget {
  const VoucherCatalogScreen({super.key});

  @override
  State<VoucherCatalogScreen> createState() => _VoucherCatalogScreenState();
}

class _VoucherCatalogScreenState extends State<VoucherCatalogScreen> {
  static const _ink = Color(0xFF1A1A1A);

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    context.read<VoucherBloc>().add(LoadBrands());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<VoucherBloc>().add(SearchBrands(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Gift Cards',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: _ink,
            fontSize: 19,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.65),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBFCFE),
              Color(0xFFE8EEF6),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildSearchAndFilter(),
                  Expanded(
                    child: BlocBuilder<VoucherBloc, VoucherState>(
                      builder: (context, state) {
                        if (state is VoucherLoading) {
                          return const Center(
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
                        if (state is VoucherError) {
                          return _buildErrorView(state.message);
                        }
                        if (state is VoucherLoaded) {
                          if (state.brands.isEmpty) {
                            return _buildEmptyView();
                          }
                          return _buildBrandGrid(state.brands);
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isFocused = _searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isFocused ? 0.85 : 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFocused ? _ink.withValues(alpha: 0.6) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: isFocused ? 0.08 : 0.04),
                  blurRadius: isFocused ? 22 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search premium brands...',
                hintStyle: TextStyle(
                  color: _ink.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _ink.withValues(alpha: isFocused ? 1 : 0.6),
                  size: 22,
                ),
                suffixIcon: hasText
                    ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: _ink.withValues(alpha: 0.4)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: BlocBuilder<VoucherBloc, VoucherState>(
              builder: (context, state) {
                final selected = state is VoucherLoaded ? state.selectedCategory : 'All';
                final categories = ['All', 'Shopping', 'Food & Beverage', 'Fashion', 'Travel', 'Electronics'];

                return Row(
                  children: categories.map((cat) {
                    final isSelected = selected == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<VoucherBloc>().add(FilterByCategory(cat));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                              colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: _ink.withValues(alpha: 0.24),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              else
                                BoxShadow(
                                  color: _ink.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : _ink.withValues(alpha: 0.65),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandGrid(List<GiftCardBrand> brands) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) => _BrandCard(brand: brands[index], index: index),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
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
              child: const Icon(Icons.error_outline_rounded, size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 22),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.read<VoucherBloc>().add(LoadBrands()),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 42,
              color: _ink.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No premium brands found',
            style: TextStyle(
              color: _ink.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or category',
            style: TextStyle(
              color: _ink.withValues(alpha: 0.35),
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatefulWidget {
  final GiftCardBrand brand;
  final int index;
  const _BrandCard({required this.brand, required this.index});

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  static const _ink = Color(0xFF1A1A1A);
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    String priceLabel = '';
    if (brand.isFixed) {
      final min = brand.denominations?.reduce((a, b) => a < b ? a : b);
      priceLabel = 'From ₹$min';
    } else {
      priceLabel = '₹${brand.minVoucherAmount} - ₹${brand.maxVoucherAmount}';
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VoucherDetailScreen(productId: brand.productId)),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: _pressed ? 0.03 : 0.06),
                blurRadius: _pressed ? 12 : 22,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: brand.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 250),
                          placeholder: (context, url) => Container(
                            color: _ink.withValues(alpha: 0.03),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _ink.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: _ink.withValues(alpha: 0.03),
                            child: Icon(Icons.image_not_supported_outlined, color: _ink.withValues(alpha: 0.2)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 44,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.38),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: _ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                brand.redemptionTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.45),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _ink.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              priceLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: -0.1,
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
          ),
        ),
      ),
    );
  }
}