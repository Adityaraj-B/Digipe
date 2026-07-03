import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../auth/screens/signup_screen.dart';
import '../bloc/product_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';
import 'insurance_detail_screen.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/api_models.dart';

class ProductScreen extends StatefulWidget {
  final Product? product;

  const ProductScreen({super.key, this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProductBloc>();
    final currentState = bloc.state;

    if (currentState is! ProductLoaded) {
      bloc.add(LoadProducts());
    } else if (widget.product != null &&
        currentState.selectedProduct.id != widget.product!.id) {
      bloc.add(SelectProduct(widget.product!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _ProductView();
  }
}

class _ProductView extends StatefulWidget {
  const _ProductView();

  @override
  State<_ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<_ProductView> {
  String? _selectedCover;
  String? _selectedDuration;
  String? _selectedForProductId;

  String? _extractCover(String name) {
    final match = RegExp(r'(Rs\.\s*\d+\s*Cover)').firstMatch(name);
    return match?.group(1);
  }

  String? _extractDuration(String name) {
    final match = RegExp(r'(\d+\s*Years?)').firstMatch(name);
    return match?.group(1);
  }

  int _extractNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  void _onSelectionChanged(BuildContext context, List<Plan> plans) {
    if (_selectedCover != null && _selectedDuration != null) {
      try {
        final matchingPlan = plans.firstWhere(
              (p) =>
          _extractCover(p.name) == _selectedCover &&
              _extractDuration(p.name) == _selectedDuration,
        );
        context.read<ProductBloc>().add(SelectPlan(matchingPlan));
      } catch (e) {
        // Fallback if combination doesn't exist
      }
    }
  }

  void _onCheckout(BuildContext context, ProductLoaded state) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is AuthIdle) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          pageBuilder: (context, _, __) => const SignupScreen(isModal: true),
          transitionDuration: const Duration(milliseconds: 500),
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
        if (currentAuthState is Authenticated || currentAuthState is AuthSkipped) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InsuranceDetailScreen()),
          );
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsuranceDetailScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            String title = 'Insurance Plan';
            if (state is ProductLoaded) {
              title = state.selectedProduct.name;
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                title,
                key: ValueKey(title),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductLoaded) {
            // Trigger auto-selection only when the product ID changes
            if (_selectedForProductId != state.selectedProduct.id) {

              Plan? targetPlan = state.selectedPlan;

              // If no plan is selected, find the absolute cheapest base plan to auto-select
              if (targetPlan == null && state.availablePlans.isNotEmpty) {
                final sortedPlans = List<Plan>.from(state.availablePlans)
                  ..sort((a, b) => a.premium.compareTo(b.premium));
                targetPlan = sortedPlans.first;
              }

              if (targetPlan != null) {
                setState(() {
                  _selectedForProductId = state.selectedProduct.id;
                  _selectedCover = _extractCover(targetPlan!.name);
                  _selectedDuration = _extractDuration(targetPlan.name);
                });

                // Dispatch event to BLoC so the bottom bar renders
                if (state.selectedPlan?.id != targetPlan.id) {
                  context.read<ProductBloc>().add(SelectPlan(targetPlan));
                }
              } else {
                // Failsafe in case there are no plans at all
                setState(() {
                  _selectedForProductId = state.selectedProduct.id;
                });
              }
            }
          }
        },
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (state is ProductError) {
            return Center(child: Text(state.message));
          }
          if (state is ProductLoaded) {
            return Column(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
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
                    child: _buildScrollableContent(context, state),
                  ),
                ),
                // Only show sticky bar if a plan is actively selected
                if (state.selectedPlan != null)
                  _buildStickyBottomBar(context, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context, ProductLoaded state) {
    final product = state.selectedProduct;

    final uniqueCovers = state.availablePlans
        .map((p) => _extractCover(p.name))
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => _extractNumber(a).compareTo(_extractNumber(b)));

    final uniqueDurations = state.availablePlans
        .map((p) => _extractDuration(p.name))
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => _extractNumber(a).compareTo(_extractNumber(b)));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.image != null) ...[
            Hero(
              tag: 'product_image_${product.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    product.image!,
                    fit: BoxFit.cover,
                    height: 220,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            'DIGIPE PROTECTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildRatingRow(),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE5E5EA), height: 1),
          const SizedBox(height: 15),
          _buildSectionTitle('SELECT VARIANT: SUM INSURED'),
          const SizedBox(height: 16),
          _buildChipGroup(
            items: uniqueCovers,
            selectedValue: _selectedCover,
            onSelected: (value) {
              setState(() => _selectedCover = value);
              _onSelectionChanged(context, state.availablePlans);
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('SELECT DURATION'),
          const SizedBox(height: 15),
          _buildChipGroup(
            items: uniqueDurations,
            selectedValue: _selectedDuration,
            onSelected: (value) {
              setState(() => _selectedDuration = value);
              _onSelectionChanged(context, state.availablePlans);
            },
          ),
          const SizedBox(height: 20),
          _buildInspectionNotice(),
          const SizedBox(height: 20),
          _buildBenefitsCard(product.features),
          const SizedBox(height: 20), // Extra padding for scroll clearance
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8E8E93),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildChipGroup({
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        final isSelected = selectedValue == item;
        return GestureDetector(
          onTap: () {
            NotificationService.lightImpact();
            onSelected(item);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF111111)
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF111111)
                    : const Color(0xFFE8E8ED),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: isSelected ? 18 : 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w600,
                letterSpacing: 0.15,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF3A3A3C),
              ),
              child: Text(item),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '4.7',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.star_rounded, color: Color(0xFF2E7D32), size: 14),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '8,511 Ratings & 1,234 Reviews',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECB3), width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFF57C00), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pre-existing damages are not covered. Subject to visual site review.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE65100),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(List<String> features) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 22, color: Color(0xFF1A1A1A)),
              SizedBox(width: 10),
              Text(
                'Coverage & Benefits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (features.isEmpty) ...[
            _benefit('Accidental damage to solar panels'),
            _benefit('Inverter failure protection'),
            _benefit('Theft and burglary coverage'),
          ] else
            ...features.map((f) => _benefit(f)),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF00BFA5), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF48484A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The new sticky bottom bar containing both the pricing and the action button
  Widget _buildStickyBottomBar(BuildContext context, ProductLoaded state) {
    final plan = state.selectedPlan!;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + safeBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E5EA).withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
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
                const Text(
                  'Total Premium',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${plan.premium.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'Rs. ${(plan.premium * 1.1).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC7C7CC),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            height: 54,
            child: ElevatedButton(
            onPressed: () {
              NotificationService.mediumImpact();
              _onCheckout(context, state);
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 10,
                // Reduced horizontal padding to prevent the 1.2px overflow
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}