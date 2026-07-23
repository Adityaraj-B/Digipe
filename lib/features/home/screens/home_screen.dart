import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/widgets/Cards.dart';
import '../../../../core/services/notification_service.dart';
import '../../product/bloc/product_bloc.dart';
import '../../product/screens/product_screen.dart';
import '../../vouchers/bloc/voucher_bloc.dart';
import '../../vouchers/models/voucher_models.dart';
import '../../vouchers/bloc/hubble_bloc.dart';
import '../../main_layout/bloc/bottom_nav_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProducts());
    context.read<VoucherBloc>().add(LoadBrands());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const ScreenHeader(
                  title: 'Offers & Protection',
                  subtitle:
                  'Discover nearby store offers and secure your assets.',
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                  titleFontSize: 25,
                  subtitleFontSize: 15,
                  gap: 4,
                ),
                Expanded(
                  child: PremiumEntrance(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, kNavBarClearance),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCouponsSection(),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Text(
                              'Protection Plans',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          BlocBuilder<ProductBloc, ProductState>(
                            builder: (context, state) {
                              if (state is ProductLoading) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: _buildInsuranceCard(context, state, null),
                                );
                              } else if (state is ProductLoaded && state.products.isNotEmpty) {
                                return Column(
                                  children: state.products
                                      .map(
                                        (product) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                        bottom: 16.0,
                                      ),
                                      child: _buildInsuranceCard(context, state, product),
                                    ),
                                  )
                                      .toList(),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: _buildInsuranceCard(context, state, null),
                              );
                            },
                          ),
                          const SizedBox(height: 56),
                          const Center(
                            child: Text(
                              '© 2026, Made with ❤️ by DIGIPe',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.labelGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // COUPONS / OFFERS SECTION
  // ---------------------------------------------------------------------

  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Store Offers',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Switch to the Hubble gift card tab (index 2)
                  context.read<BottomNavBloc>().add(TabChanged(3));
                  context.read<HubbleBloc>().add(LoadHubbleSDK());
                },
                child: const Text(
                  'Buy Gift Cards',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 164,
          child: BlocBuilder<VoucherBloc, VoucherState>(
            builder: (context, state) {
              if (state is VoucherLoading) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildCouponCardSkeleton(),
                );
              }

              if (state is VoucherLoaded && state.brands.isNotEmpty) {
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.brands.length,
                  itemBuilder: (context, index) {
                    final brand = state.brands[index];
                    return _buildGiftCardOffer(brand);
                  },
                );
              }

              // Fallback to static if no brands or error
              return ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCouponCard(
                    storeName: 'Reliance Smart',
                    offer: '20% OFF',
                    distance: 'Within 200m',
                    icon: Icons.storefront_rounded,
                    accent: const Color(0xFFFF6B6B),
                  ),
                  _buildCouponCard(
                    storeName: 'D-Mart',
                    offer: 'Flat ₹500 OFF',
                    distance: 'Within 500m',
                    icon: Icons.shopping_cart_rounded,
                    accent: const Color(0xFF2BD9C2),
                  ),
                  _buildCouponCard(
                    storeName: 'Star Bazaar',
                    offer: 'Buy 1 Get 1',
                    distance: 'Within 1km',
                    icon: Icons.shopping_bag_rounded,
                    accent: const Color(0xFFFFB648),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGiftCardOffer(GiftCardBrand brand) {
    String priceLabel = '';
    if (brand.isFixed) {
      final min = brand.denominations?.reduce((a, b) => a < b ? a : b);
      priceLabel = 'From ₹$min';
    } else {
      priceLabel = '₹${brand.minVoucherAmount}';
    }

    final accent = brand.category == 'Food & Beverage'
        ? const Color(0xFF2BD9C2)
        : brand.category == 'Fashion'
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFB648);

    return GestureDetector(
      onTap: () {
        // Tapping a gift card brand opens the Hubble store (tab 3)
        context.read<BottomNavBloc>().add(TabChanged(3));
        context.read<HubbleBloc>().add(LoadHubbleSDK());
      },
      child: Container(
        width: 280,
        height: 156,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.9),
            radius: 1.1,
            colors: [
              accent.withValues(alpha: 0.30),
              const Color(0xFF2A2733),
              const Color(0xFF23202B),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          brand.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    brand.category ?? 'Premium',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Redeem Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCardSkeleton() {
    return Container(
      width: 280,
      height: 156,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF2A2733),
      ),
    );
  }

  Widget _buildCouponCard({
    required String storeName,
    required String offer,
    required String distance,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      key: ValueKey('coupon_$storeName'),
      width: 280,
      height: 156,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.9),
          radius: 1.1,
          colors: [
            accent.withValues(alpha: 0.30),
            const Color(0xFF2A2733),
            const Color(0xFF23202B),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withValues(alpha: 0.25)),
                      ),
                      child: Icon(icon, color: accent, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        storeName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white60, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Redeem',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PROTECTION PLAN CARD
  // ---------------------------------------------------------------------

  Widget _buildInsuranceCard(
      BuildContext context,
      ProductState state,
      Product? product,
      ) {
    String productName = '1234 product Plan';
    String rawName = '1234 product';
    String startPrice = '449';
    bool isLoading = state is ProductLoading;
    List<Plan> plansForProduct = [];

    if (state is ProductLoaded && product != null) {
      rawName = product.name
          .replaceAll(RegExp(r'\s*plan\s*', caseSensitive: false), '')
          .trim();
      productName = '$rawName Plan';

      plansForProduct = state.productPlans[product.id] ?? [];

      if (plansForProduct.isNotEmpty) {
        final validPlans = plansForProduct.where((p) => p.premium > 0).toList();
        if (validPlans.isNotEmpty) {
          final minPremium =
          validPlans.map((p) => p.premium).reduce((a, b) => a < b ? a : b);
          startPrice = minPremium.toStringAsFixed(0);
        }
      }
    }

    final productDescription =
        'Protect your $rawName installation against damage, theft, and natural disasters. ';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2733),
            Color(0xFF23202B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white70,
                  size: 12,
                ),
                SizedBox(width: 6),
                Text(
                  'NEW LAUNCH',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isLoading ? 'Loading...' : productName,
                        key: ValueKey(productName),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC3C1CF),
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(text: productDescription),
                          const TextSpan(text: 'Starting at just '),
                          TextSpan(
                            text: '₹$startPrice/year',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              ElevatedButton(
                onPressed: () {
                  NotificationService.mediumImpact();
                  if (product != null) {
                    context.read<ProductBloc>().add(SelectProduct(product));
                  }

                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductScreen(product: product),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).chain(
                              CurveTween(
                                curve: Curves.fastOutSlowIn,
                              ),
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  NotificationService.lightImpact();
                  if (product != null) {
                    context.read<ProductBloc>().add(SelectProduct(product));
                  }
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductScreen(product: product),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).chain(
                              CurveTween(
                                curve: Curves.fastOutSlowIn,
                              ),
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Learn More',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
