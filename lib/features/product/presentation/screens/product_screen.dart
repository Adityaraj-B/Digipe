import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';
import '../../../auth/presentation/screens/signup_screen.dart';
import 'insurance_detail_screen.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProductView();
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView();

  void _onCheckout(BuildContext context, ProductLoaded state) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    
    print("Current AuthState: $authState");

    if (authState is AuthInitial || authState is AuthSkipped) {
      print("Showing Signup Modal");
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          pageBuilder: (context, _, __) => const SignupScreen(isModal: true),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ).then((_) {
        if (!context.mounted) return;
        final currentAuthState = authBloc.state;
        print("Auth Modal Closed. New state: $currentAuthState");
        if (currentAuthState is AuthAuthenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InsuranceDetailScreen()),
          );
        }
      });
    } else if (authState is AuthAuthenticated) {
      print("Already authenticated, navigating to details");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsuranceDetailScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solar Insurance',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductError) {
            return Center(child: Text(state.message));
          }
          if (state is ProductLoaded) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildContent(context, state),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.selectedVariant.imageUrl != null) ...[
                    _buildProductImage(state.selectedVariant.imageUrl!),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Digipe Protection',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solar Insurance Plan (Premium Grid Cover)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRatingRow(),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Variant: Sum Insured',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: state.variants.map((variant) {
                      final isSelected = state.selectedVariant.id == variant.id;
                      return GestureDetector(
                        onTap: () => context.read<ProductBloc>().add(SelectVariant(variant)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            variant.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Duration',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: state.durations.map((duration) {
                        final isSelected = state.selectedDuration == duration;
                        return GestureDetector(
                          onTap: () => context.read<ProductBloc>().add(SelectDuration(duration)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2C2C2E) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : [],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              duration,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPriceCard(state),
                  const SizedBox(height: 24),
                  _buildBenefitsCard(),
                ],
              ),
            ),
          ),
          _buildCheckoutButton(context, state),
        ],
      ),
    );
  }

  Widget _buildProductImage(String url) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFFF2F2F7),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF2F2F7),
            child: const Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF34C759),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '4.7',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.star, color: Colors.white, size: 12),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '8,511 Ratings & 1,234 Reviews',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(ProductLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Price Offer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${state.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${(state.totalPrice * 1.5).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  decoration: TextDecoration.lineThrough,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '37% off',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF34C759),
                  height: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Selected variant: ${state.selectedVariant.name} for ${state.selectedDuration}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFFF5A623), size: 16),
              SizedBox(width: 8),
              Text(
                'Coverage & Benefits',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefit('Coverage for accidental damage to solar panels'),
          const SizedBox(height: 12),
          _buildBenefit('Inverter failure and electrical breakdown protection'),
          const SizedBox(height: 12),
          _buildBenefit('Theft and burglary coverage'),
          const SizedBox(height: 12),
          _buildBenefit('Damage due to fire, lightning, and natural disasters'),
          const SizedBox(height: 12),
          _buildBenefit('24/7 customer support & claim assistance'),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(Icons.check, color: Color(0xFF34C759), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF48484A),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, ProductLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            print("Checkout button pressed");
            _onCheckout(context, state);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C2C2E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Insured Now',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_outlined, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}



