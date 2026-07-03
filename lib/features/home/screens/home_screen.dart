import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/widgets/Cards.dart';
import '../../../../core/services/notification_service.dart';
import '../../product/bloc/product_bloc.dart';
import '../../product/screens/product_screen.dart';

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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              title: 'Available Protection Plans',
              subtitle:
              'Select an insurance plan to secure your assets with customized rates.',
              padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
              titleFontSize: 25,
              subtitleFontSize: 15,
              gap: 4,
            ),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  return PremiumEntrance(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, kNavBarClearance),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- Multiple banners: one card per product (unchanged) ----
                          if (state is ProductLoading)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInsuranceCard(context, state, null),
                            )
                          else if (state is ProductLoaded && state.products.isNotEmpty)
                            ...state.products.map(
                                  (product) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                ),
                                child: _buildInsuranceCard(context, state, product),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildInsuranceCard(context, state, null),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Unchanged: banner card + its behavior (bloc selection, navigation,
  // pricing calc, description copy). Left exactly as it was.
  // --------------------------------------------------------------------
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

      // Pull plans for THIS specific product from the cached map,
      // not state.availablePlans (which only reflects the currently
      // selected product in the BLoC).
      plansForProduct = state.productPlans[product.id] ?? [];

      if (plansForProduct.isNotEmpty) {
        final validPlans =
        plansForProduct.where((p) => p.premium > 0).toList();
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
          Row(
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
                      transitionDuration:
                      const Duration(milliseconds: 500),
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
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: () {
                  NotificationService.lightImpact();
                  if (product != null) {
                    context.read<ProductBloc>().add(SelectProduct(product));
                  }
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