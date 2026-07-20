import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../claims/bloc/claims_bloc.dart';
import '../../claims/services/raise_claim.dart';
import '../../payment/payment_screen.dart';
import '../bloc/order_tracking_bloc.dart';
import '../service/order_tracking_model.dart';
import '../../../core/services/api_service.dart';
import '../service/order_tracking_repo.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String? orderId;

  const OrderTrackingScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repo = OrderTrackingApiRepository(context.read<ApiService>());
        final bloc = OrderTrackingBloc(repository: repo);

        if (orderId != null && orderId!.isNotEmpty) {
          bloc.add(LoadOrder(orderId!));
        } else {
          bloc.add(LoadLatestOrder());
        }
        return bloc;
      },
      child: _OrderTrackingView(orderId: orderId ?? ''),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  final String orderId;
  const _OrderTrackingView({required this.orderId});

  // Responsive constraint parameter
  static const double _maxScreenWidth = 800.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        // Responsive Wrapper for Main Body
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxScreenWidth),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: BlocConsumer<OrderTrackingBloc, OrderTrackingState>(
                listener: (context, state) {
                  if (state is OrderTrackingError &&
                      context.read<OrderTrackingBloc>().state is OrderTrackingLoaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      _buildScreenHeader(),
                      Expanded(
                        child: _buildBody(context, state),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Tracking',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Monitor your policy status and lifecycle.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderTrackingState state) {
    if (state is OrderTrackingLoading) return const _LoadingView();

    if (state is OrderTrackingError && state is! OrderTrackingRefreshing) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<OrderTrackingBloc>().add(LoadOrder(orderId)),
      );
    }

    final order = state is OrderTrackingLoaded
        ? state.order
        : state is OrderTrackingRefreshing ? state.currentOrder : null;

    if (order == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      backgroundColor: Colors.white,
      onRefresh: () async {
        context.read<OrderTrackingBloc>().add(RefreshOrder(orderId));
        await context.read<OrderTrackingBloc>().stream.firstWhere(
                (s) => s is OrderTrackingLoaded || s is OrderTrackingError);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            _OrderInfoCard(order: order),
            const SizedBox(height: 16),
            _LifecycleCard(steps: order.lifecycleSteps),
            const SizedBox(height: 16),
            _QuickActionsCard(order: order),
            const SizedBox(height: 16),
            const _HelpCard(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final OrderTracking order;
  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFFA0A0A0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEEEEEE).withValues(alpha: 0.2),
                  const Color(0xFFEEEEEE),
                  const Color(0xFFEEEEEE).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _MetaItem(label: 'Policy Type', value: order.policyType)),
              Expanded(child: _MetaItem(label: 'Purchase Date', value: order.formattedPurchaseDate)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MetaItem(label: 'Amount Paid', value: order.formattedAmount)),
              Expanded(child: _MetaItem(label: 'Coverage Period', value: order.coveragePeriod)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.pendingApproval => (const Color(0xFFFFF9E6), const Color(0xFFB5850B)),
      OrderStatus.underReview => (const Color(0xFFF0F6FF), const Color(0xFF2B78C5)),
      OrderStatus.paymentEligible => (const Color(0xFFE8F8EE), const Color(0xFF238643)),
      OrderStatus.approved => (const Color(0xFFE8F8EE), const Color(0xFF238643)),
      OrderStatus.active => (const Color(0xFFE8F8EE), const Color(0xFF238643)),
      OrderStatus.claimRaised => (const Color(0xFFFFF9E6), const Color(0xFFD97706)), // Amber
      OrderStatus.claimApproved => (const Color(0xFF238643), Colors.white), // Solid Emerald
      OrderStatus.rejected => (const Color(0xFFFEF2F2), const Color(0xFF992727)),
      OrderStatus.cancelled => (const Color(0xFFFEF2F2), const Color(0xFF992727)),
      OrderStatus.expired => (const Color(0xFFF5F5F5), const Color(0xFF666666)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: status == OrderStatus.claimApproved
            ? null
            : Border.all(color: fg.withValues(alpha: 0.1)),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LifecycleCard extends StatelessWidget {
  final List<LifecycleStep> steps;
  const _LifecycleCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POLICY LIFECYCLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFA0A0A0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(steps.length, (i) {
            return _LifecycleStepRow(
              step: steps[i],
              isLast: i == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _LifecycleStepRow extends StatelessWidget {
  final LifecycleStep step;
  final bool isLast;

  const _LifecycleStepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDone = step.state == LifecycleStepState.done;
    final isActive = step.state == LifecycleStepState.active;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _StepIcon(state: step.state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF9FE1CB) : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                      color: isDone
                          ? const Color(0xFF111111)
                          : isActive ? const Color(0xFF2B78C5) : const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isActive ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
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

class _StepIcon extends StatelessWidget {
  final LifecycleStepState state;
  const _StepIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      LifecycleStepState.done => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8EE),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF238643).withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF238643)),
      ),
      LifecycleStepState.active => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF111111), // Next.js uses Dark Charcoal for current step
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111111).withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.white),
      ),
      LifecycleStepState.failed => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF992727),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF992727).withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Center(child: Text('!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ),
      LifecycleStepState.pending => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEBEBEB), width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: const Color(0xFFDCDCDC),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    };
  }
}

class _QuickActionsCard extends StatefulWidget {
  final OrderTracking order;
  const _QuickActionsCard({required this.order});

  @override
  State<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends State<_QuickActionsCard> {
  bool _isDownloading = false;

  Future<void> _handleDownloadPolicy() async {
    setState(() => _isDownloading = true);
    try {
      final apiService = context.read<ApiService>();

      // Fetch the raw PDF bytes from the backend
      await apiService.downloadPolicyDocument(widget.order.orderId);

      // TODO: Implement file saving here using path_provider and open_filex
      // Example:
      // final dir = await getApplicationDocumentsDirectory();
      // final file = File('${dir.path}/Policy_${widget.order.orderId}.pdf');
      // await file.writeAsBytes(bytes);
      // await OpenFilex.open(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Policy downloaded successfully!'),
          backgroundColor: const Color(0xFF238643),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download policy: $e'),
          backgroundColor: const Color(0xFF992727),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _proceedToPayment() async {
    if (widget.order.planId == null || widget.order.planId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missing plan details. Please try again.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
      ),
    );

    try {
      final apiService = context.read<ApiService>();

      // MIRROR Orders screen logic: Use DB _id (dbId), not applicationNumber (orderId)
      final createdOrder = await apiService.createOrder(
        applicationId: widget.order.dbId,
        planId: widget.order.planId!,
      );

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPreviewScreen(
            product: widget.order.policyType,
            basePremium: (createdOrder['subtotal'] ?? widget.order.amountPaid).toDouble(),
            years: widget.order.years,
            planId: widget.order.planId!,
            applicationId: widget.order.dbId, // Pass MongoDB ID
            orderData: createdOrder,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      final message = e.response?.data?['message']?.toString() ?? '';

      if (e.response?.statusCode == 400 &&
          message.toLowerCase().contains('approved')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Your application is pending admin approval. You will be notified once approved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message.isNotEmpty ? message : 'Order creation failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFA0A0A0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          _ActionButton(
            icon: _isDownloading ? Icons.hourglass_bottom_rounded : Icons.file_download_outlined,
            label: _isDownloading ? 'Downloading...' : 'Download Policy',
            enabled: widget.order.status.canDownloadPolicy && !_isDownloading,
            onTap: _handleDownloadPolicy,
          ),
          const SizedBox(height: 12),

          _ActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'View Invoice',
            enabled: widget.order.status.canViewInvoice,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice viewer coming soon!')),
              );
            },
          ),

          if (widget.order.status == OrderStatus.paymentEligible || widget.order.status == OrderStatus.approved) ...[
            const SizedBox(height: 12),
            _PayNowButton(onTap: _proceedToPayment),
          ],

          if (widget.order.status == OrderStatus.active) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            _RaiseClaimButton(onTap: () async {
              // Open the RaiseClaimDialog
              final bool? claimSubmitted = await showDialog<bool>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<ClaimsBloc>(),
                  child: RaiseClaimDialog(
                    policyId: widget.order.orderId,
                    policyNumber: widget.order.orderId,
                    coverageAmount: widget.order.amountPaid,
                  ),
                ),
              );

              // If the claim was successfully submitted, trigger a refresh on the tracking screen
              if (claimSubmitted == true && context.mounted) {
                context.read<OrderTrackingBloc>().add(RefreshOrder(widget.order.orderId));
              }
            }),
          ],

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.order.status == OrderStatus.claimRaised ? const Color(0xFFFFF9E6) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: widget.order.status == OrderStatus.claimRaised ? const Color(0xFFF5E4B5) : const Color(0xFFF0F0F0)
              ),
            ),
            child: Row(
              children: [
                Icon(
                    widget.order.status == OrderStatus.claimRaised ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: widget.order.status == OrderStatus.claimRaised ? const Color(0xFFD97706) : const Color(0xFF888888)
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.order.status.policyNotice,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.order.status == OrderStatus.claimRaised ? const Color(0xFFB5850B) : const Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RaiseClaimButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RaiseClaimButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444), // Destructive Red
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Raise Claim',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAEAEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF444444)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const Spacer(),
                if (enabled)
                  const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayNowButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PayNowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2B78C5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reach out to our support team.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B78C5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1A1A1A),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fetching details...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF992727).withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFF992727)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF444444),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF111111).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}