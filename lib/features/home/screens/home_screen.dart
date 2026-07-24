import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/widgets/Cards.dart';
import '../../../../core/services/notification_service.dart';
import '../../product/bloc/product_bloc.dart';
import '../../product/screens/product_screen.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          _buildGiftCardBanner(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Text(
                              'Protection Plans',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
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
                          Center(
                            child: Text(
                              '© 2026, Made with ❤️ by DIGIPe',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
  // GIFT CARD BANNER
  // ---------------------------------------------------------------------

  Widget _buildGiftCardBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.white : Colors.black;
    final accentBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final accentBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: () {
          context.read<BottomNavBloc>().add(TabChanged(3));
          context.read<HubbleBloc>().add(LoadHubbleSDK());
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF2A2733),
                      Color(0xFF23202B),
                    ]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFF3F4F6),
                    ],
            ),
          ),
          child: Row(
            children: [
              // Icon box — white in dark mode, black in light mode
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accentBorder),
                ),
                child: Center(
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Gift Cards',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '400+ brands · Up to 5% off instantly',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.60)
                            : Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // CTA chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Shop',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF2A2733),
                  Color(0xFF23202B),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF3F4F6),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.06),
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
              color: isDark
                  ? Colors.white.withValues(alpha: .06)
                  : Colors.black.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: .08)
                    : Colors.black.withValues(alpha: .10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  'NEW LAUNCH',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
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
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFFC3C1CF)
                              : const Color(0xFF555555),
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(text: productDescription),
                          const TextSpan(text: 'Starting at just '),
                          TextSpan(
                            text: '₹$startPrice/year',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
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
                  color: isDark
                      ? Colors.white.withValues(alpha: .04)
                      : Colors.black.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: .12)
                        : Colors.black.withValues(alpha: .10),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    color: isDark ? Colors.white : Colors.black,
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
                  backgroundColor: isDark ? Colors.white : const Color(0xFF0D0D0D),
                  foregroundColor: isDark ? Colors.black : Colors.white,
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
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0D0D0D),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: .18)
                        : Colors.black.withValues(alpha: .20),
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
