// ─────────────────────────────────────────────────────────────────────────────
// order_tracking_screen.dart
//
// Full reactive screen wired to OrderTrackingBloc.
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => OrderTrackingScreen(orderId: 'APP-90058A02'),
//   ));
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_tracking_bloc.dart';
import '../service/order_tracking_model.dart';
import '../service/order_tracking_repo.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderTrackingBloc(
        repository: const OrderTrackingMockRepository(),
        // Swap ↑ for OrderTrackingApiRepository(...) when API is live
      )..add(LoadOrder(orderId)),
      child: _OrderTrackingView(orderId: orderId),
    );
  }
}

// ─── Internal view ────────────────────────────────────────────────────────────

class _OrderTrackingView extends StatelessWidget {
  final String orderId;
  const _OrderTrackingView({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: BlocConsumer<OrderTrackingBloc, OrderTrackingState>(
            listener: (context, state) {
              if (state is OrderTrackingError &&
                  context.read<OrderTrackingBloc>().state
                      is OrderTrackingLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1A1A1A),
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
    );
  }

  Widget _buildScreenHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Tracking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Monitor your policy status and lifecycle.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderTrackingState state) {
    if (state is OrderTrackingLoading) {
      return const _LoadingView();
    }
    if (state is OrderTrackingError && state is! OrderTrackingRefreshing) {
      return _ErrorView(
        message: state.message,
        onRetry: () =>
            context.read<OrderTrackingBloc>().add(LoadOrder(orderId)),
      );
    }

    final order = state is OrderTrackingLoaded
        ? state.order
        : state is OrderTrackingRefreshing
            ? state.currentOrder
            : null;

    if (order == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async {
        context.read<OrderTrackingBloc>().add(RefreshOrder(orderId));
        await context.read<OrderTrackingBloc>().stream.firstWhere(
            (s) => s is OrderTrackingLoaded || s is OrderTrackingError);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            _OrderInfoCard(order: order),
            const SizedBox(height: 12),
            _LifecycleCard(steps: order.lifecycleSteps),
            const SizedBox(height: 12),
            _QuickActionsCard(order: order),
            const SizedBox(height: 12),
            const _HelpCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Order Info Card ──────────────────────────────────────────────────────────

class _OrderInfoCard extends StatelessWidget {
  final OrderTracking order;
  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
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
                      'Order ID',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetaItem(
                    label: 'Policy Type', value: order.policyType),
              ),
              Expanded(
                child: _MetaItem(
                    label: 'Purchase Date',
                    value: order.formattedPurchaseDate),
              ),
              Expanded(
                child: _MetaItem(
                    label: 'Amount Paid',
                    value: order.formattedAmount),
              ),
              Expanded(
                child: _MetaItem(
                    label: 'Coverage Period',
                    value: order.coveragePeriod),
              ),
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
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.pendingApproval => (
      const Color(0xFFFFF3CD),
      const Color(0xFF856404)
      ),
      OrderStatus.underReview => (
      const Color(0xFFE6F1FB),
      const Color(0xFF185FA5)
      ),
      OrderStatus.paymentEligible => (
      const Color(0xFFD4EDDA),
      const Color(0xFF155724)
      ),
      OrderStatus.active => (
      const Color(0xFFD4EDDA),
      const Color(0xFF155724)
      ),
      OrderStatus.rejected => (
      const Color(0xFFFCEBEB),
      const Color(0xFF791F1F)
      ),
      OrderStatus.expired => (
      const Color(0xFFF0F0F0),
      const Color(0xFF555555)
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Lifecycle Card ───────────────────────────────────────────────────────────

class _LifecycleCard extends StatelessWidget {
  final List<LifecycleStep> steps;
  const _LifecycleCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POLICY LIFECYCLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return _LifecycleStepRow(
                step: step, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _LifecycleStepRow extends StatelessWidget {
  final LifecycleStep step;
  final bool isLast;

  const _LifecycleStepRow(
      {required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDone = step.state == LifecycleStepState.done;
    final isActive = step.state == LifecycleStepState.active;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + vertical line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _StepIcon(state: step.state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDone
                          ? const Color(0xFF9FE1CB)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? const Color(0xFF1A1A1A)
                          : isActive
                          ? const Color(0xFF185FA5)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFAAAAAA)),
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
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF3DE),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            size: 16, color: Color(0xFF3B6D11)),
      ),
      LifecycleStepState.active => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F1FB),
          shape: BoxShape.circle,
          border:
          Border.all(color: const Color(0xFF378ADD), width: 2),
        ),
        child: const Icon(Icons.access_time_rounded,
            size: 15, color: Color(0xFF185FA5)),
      ),
      LifecycleStepState.pending => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFCCCCCC),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    };
  }
}

// ─── Quick Actions Card ───────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  final OrderTracking order;
  const _QuickActionsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            icon: Icons.download_outlined,
            label: 'Download Policy',
            enabled: order.status.canDownloadPolicy,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'View Invoice',
            enabled: order.status.canViewInvoice,
            onTap: () {},
          ),
          if (order.status == OrderStatus.paymentEligible) ...[
            const SizedBox(height: 8),
            _PayNowButton(onTap: () {}),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order.status.policyNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF666666), height: 1.5),
            ),
          ),
        ],
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
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF555555)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A1A)),
              ),
            ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Pay Now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Help Card ────────────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'If you face any issues with your policy or have questions, contact our support team.',
            style: TextStyle(
                fontSize: 13, color: Color(0xFF888888), height: 1.5),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF185FA5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Color(0xFF185FA5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF1A1A1A),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFCEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 32, color: Color(0xFFA32D2D)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF1A1A1A), height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}