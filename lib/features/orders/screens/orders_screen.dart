import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/amount_modifier.dart';
import '../../../core/utils/date_modifier.dart';
import '../../payment/payment_screen.dart';
import '../bloc/orders_bloc.dart';
import '../../../core/widgets/Cards.dart';
import '../../track/screens/track_screen.dart';
import '../../claims/screens/claims_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<OrdersBloc>()..add(FetchOrders()),
      child: const _MyOrdersView(),
    );
  }
}

class _MyOrdersView extends StatefulWidget {
  const _MyOrdersView();

  @override
  State<_MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<_MyOrdersView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';

  final List<String> _statusOptions = [
    'All Status',
    'Active',
    'Claim Raised',
    'Claim Approved',
    'Pending Approval',
    'Approved - Pay Now',
    'Rejected',
    'Expired',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchOrFilterChanged() {
    context.read<OrdersBloc>().add(
      FetchOrders(
        searchQuery: _searchController.text,
        statusFilter: _selectedStatus,
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return (AppColors.successBg, AppColors.successFg);
      case 'CLAIM RAISED':
        return (const Color(0xFFFFF3CD), const Color(0xFFD97706));
      case 'CLAIM APPROVED':
        return (const Color(0xFF059669), Colors.white);
      case 'PENDING APPROVAL':
        return (const Color(0xFFFFF3CD), const Color(0xFFF59E0B));
      case 'APPROVED - PAY NOW':
      case 'APPROVED':
        return (const Color(0xFFD1FAE5), const Color(0xFF059669));
      case 'REJECTED':
      case 'CANCELLED':
        return (AppColors.dangerBg, AppColors.dangerFg);
      case 'EXPIRED':
        return (const Color(0xFFFFF3CD), const Color(0xFFF59E0B));
      default:
        return (AppColors.neutralBg, AppColors.neutralFg);
    }
  }

  Future<void> _confirmDeleteOrder(UnifiedOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order "${order.id}"? '
              'This will remove it from your dashboard view.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete Order',
              style: TextStyle(color: Color(0xFFB23A3A)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<OrdersBloc>().add(DeleteOrderLocally(order.id, order.dbId));
    }
  }

  void _openPolicyDetails(UnifiedOrder order) {
    final trackingId = (order.applicationId != null && order.applicationId!.isNotEmpty)
        ? order.applicationId!
        : order.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: trackingId),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, UnifiedOrder order) async {
    if (order.planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing plan details. Cannot proceed.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.inkStrong),
      ),
    );

    try {
      final apiService = context.read<ApiService>();
      final createdOrder = await apiService.createOrder(
        applicationId: order.dbId,
        planId: order.planId!,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPreviewScreen(
            product: order.product,
            basePremium: (createdOrder['subtotal'] ?? 0).toDouble(),
            years: int.tryParse(order.years) ?? 1,
            planId: order.planId!,
            applicationId: order.dbId,
            orderData: createdOrder,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      final message = e.response?.data?['message']?.toString() ?? '';

      if (e.response?.statusCode == 400 && message.toLowerCase().contains('approved')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your application is pending admin approval. You will be notified once approved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isNotEmpty ? message : 'Order creation failed.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              title: 'My Orders',
              subtitle: 'View and manage your insurance policies.',
            ),
            Expanded(
              child: PremiumEntrance(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, kNavBarClearance),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterCard(),
                          const SizedBox(height: 16),
                          _buildOrdersBody(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildStatusDropdown(),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: _buildSearchBar()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildStatusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return TextField(
        controller: _searchController,
        onChanged: (_) => _onSearchOrFilterChanged(),
        style: TextStyle(fontSize: 14, color: AppColors.adaptiveInk(context)),
        decoration: InputDecoration(
          hintText: 'Search Order ID...',
          hintStyle: TextStyle(fontSize: 14, color: AppColors.adaptiveBodyGrey(context)),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.adaptiveBodyGrey(context)),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? Colors.white : const Color(0xFF111111),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );
    });
  }

  Widget _buildStatusDropdown() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStatus,
            isExpanded: true,
            dropdownColor: Theme.of(context).cardColor,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.adaptiveBodyGrey(context)),
            items: _statusOptions.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status, style: TextStyle(fontSize: 14, color: AppColors.adaptiveInk(context))),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;
                });
                _onSearchOrFilterChanged();
              }
            },
          ),
        ),
      );
    });
  }

  Widget _buildOrdersBody(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.inkStrong, strokeWidth: 2.5),
            ),
          );
        }

        if (state is OrdersError) {
          return PremiumEmptyState(
            icon: Icons.error_outline_rounded,
            iconBg: AppColors.dangerBg,
            iconFg: AppColors.dangerFg,
            message: state.message,
            actionLabel: 'Try Again',
            onAction: () => _onSearchOrFilterChanged(),
          );
        }

        if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: PremiumEmptyState(
                icon: Icons.inventory_2_outlined,
                iconBg: AppColors.neutralBg,
                iconFg: AppColors.neutralFg,
                message: 'No orders match your search or filter.',
              ),
            );
          }
          return Column(
            children: [
              const SizedBox(height: 4),
              ...state.orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOrderCard(context, order),
                ),
              ),
              if (state.totalEntries > 10)
                _buildPaginationFooter(
                  state.orders.length,
                  state.totalEntries,
                  state.currentPage,
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, UnifiedOrder order) {
    final (bg, fg) = _statusColors(order.status);
    final hasProduct = order.product.trim().isNotEmpty;
    final isPayNow = order.status == 'Approved - Pay Now';
    final isActive = order.status == 'Active';
    final isDownloadable = isActive || order.status == 'Claim Approved';

      return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.adaptiveSurface(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.adaptiveInk(context).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: AppColors.adaptiveInk(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasProduct)
                      Text(
                        order.product,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppColors.adaptiveInk(context),
                        ),
                      ),
                    if (hasProduct) const SizedBox(height: 4),
                    Text(
                      "Order #${order.id}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: hasProduct ? 13 : 15,
                        fontWeight: hasProduct ? FontWeight.w500 : FontWeight.w600,
                        color: AppColors.adaptiveBodyGrey(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(
                label: order.status,
                background: bg,
                foreground: fg,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: AppColors.adaptiveSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.adaptiveBorder(context).withValues(alpha: 0.5),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _buildStatItem(
                        value: formatAmount(order.amount),
                        label: "Amount Paid",
                        isPrimary: true,
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.adaptiveBorder(context).withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _buildStatItem(
                        value: formatDate(order.date),
                        label: "Purchased",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          FadedDivider(),
          const SizedBox(height: 16),

          if (isPayNow)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _processPayment(context, order),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.adaptiveInk(context),
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Pay Now",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _confirmDeleteOrder(order),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFB23A3A).withValues(alpha: 0.08),
                    foregroundColor: const Color(0xFFB23A3A),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _openPolicyDetails(order),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adaptiveInk(context),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "Track",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.adaptiveBorder(context).withValues(alpha: 0.5)),
                Expanded(
                  child: TextButton(
                    onPressed: isDownloadable ? () {} : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adaptiveInk(context),
                      disabledForegroundColor: AppColors.adaptiveBodyGrey(context),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "Download",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.border.withValues(alpha: 0.5)),
                Expanded(
                  child: TextButton(
                    onPressed: () => _confirmDeleteOrder(order),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB23A3A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "Delete",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              const SizedBox(height: 16),
              GradientCtaButton(
                icon: Icons.warning_amber_rounded,
                label: "Raise Claim",
                colors: const [Color(0xFFD32F2F), Color(0xFF8B0000)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClaimsScreen()),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int currentCount, int totalCount, int currentPage) {
    if (totalCount <= 10) {
      return const SizedBox.shrink();
    }

    const int itemsPerPage = 10;
    final int totalPages = (totalCount / itemsPerPage).ceil();

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Text(
            'Showing 1 to $currentCount of $totalCount entries',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bodyGrey),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaginationButton('Previous', isEnabled: currentPage > 1),
                const SizedBox(width: 8),
                for (int i = 1; i <= totalPages; i++) ...[
                  _buildPaginationNumber('$i', isActive: i == currentPage),
                  const SizedBox(width: 8),
                ],
                _buildPaginationButton('Next', isEnabled: currentPage < totalPages),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton(String label, {bool isEnabled = true}) {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface(context),
          border: Border.all(color: AppColors.adaptiveBorder(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isEnabled
                ? AppColors.adaptiveInk(context)
                : AppColors.adaptiveBodyGrey(context),
          ),
        ),
      );
    });
  }

  Widget _buildPaginationNumber(String number, {bool isActive = false}) {
    return Builder(builder: (context) {
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.adaptiveInk(context) : AppColors.adaptiveSurface(context),
          border: Border.all(
            color: isActive ? AppColors.adaptiveInk(context) : AppColors.adaptiveBorder(context),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          number,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                : AppColors.adaptiveInk(context),
          ),
        ),
      );
    });
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    bool isPrimary = false,
  }) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isPrimary ? 22 : 17,
                fontWeight: FontWeight.w700,
                color: AppColors.adaptiveInk(context),
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.adaptiveBodyGrey(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}