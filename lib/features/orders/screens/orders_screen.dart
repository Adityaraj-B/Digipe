import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/amount_modifier.dart';
import '../../../core/utils/date_modifier.dart';
import '../bloc/orders_bloc.dart';
import '../../../core/models/api_models.dart';
import '../../../core/widgets/Cards.dart';
import '../../track/screens/track_screen.dart';

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
    'CONFIRMED',
    'CANCELLED',
    'Pending',
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
      case 'CONFIRMED':
      case 'ACTIVE':
        return (AppColors.successBg, AppColors.successFg);
      case 'CANCELLED':
      case 'REJECTED':
        return (AppColors.dangerBg, AppColors.dangerFg);
      case 'PENDING':
        return (AppColors.warnBg, AppColors.warnFg);
      default:
        return (AppColors.neutralBg, AppColors.neutralFg);
    }
  }

  Future<void> _confirmDeleteOrder(OrderSummary order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order "${order.orderId}"? '
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
      context.read<OrdersBloc>().add(DeleteOrderLocally(order.orderId));
    }
  }

  void _openPolicyDetails(OrderSummary order) {
    final trackingId = (order.applicationId != null && order.applicationId!.isNotEmpty)
        ? order.applicationId!
        : order.orderId; // fallback if backend didn't send it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: trackingId),
      ),
    );
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
    return TextField(
      controller: _searchController,
      onChanged: (_) => _onSearchOrFilterChanged(),
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: 'Search Order ID...',
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.bodyGrey),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.bodyGrey),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.bodyGrey),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedStatus = newValue);
              _onSearchOrFilterChanged();
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrdersBody(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.inkStrong, strokeWidth: 2.5),
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
            onAction: _onSearchOrFilterChanged,
          );
        }

        if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return const PremiumEmptyState(
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.neutralBg,
              iconFg: AppColors.neutralFg,
              message: 'No orders match your search or filter.',
            );
          }
          return Column(
            children: [
              const SizedBox(height: 4),
              ...state.orders.map(
                    (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOrderCard(order),
                ),
              ),
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

  Widget _buildOrderCard(OrderSummary order) {
    final (bg, fg) = _statusColors(order.status);

    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [

          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Builder(
                  builder: (_) {
                    final hasProduct = order.product.trim().isNotEmpty;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        if (hasProduct)
                          Text(
                            order.product,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),

                        if (hasProduct)
                          const SizedBox(height: 3),

                        Text(
                          "Order #${order.orderId}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: hasProduct ? 12 : 15,
                            fontWeight:
                            hasProduct ? FontWeight.w500 : FontWeight.w600,
                            color: AppColors.bodyGrey,
                          ),
                        ),
                      ],
                    );
                  },
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: .8),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      value: formatAmount(order.amount),
                      label: "Amount Paid",
                      isPrimary: true,
                    ),
                  ),

                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),

                  Expanded(
                    child: _buildStatItem(
                      value: formatDate(order.date),
                      label: "Purchased",
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          const FadedDivider(),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openPolicyDetails(order),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 18,
              ),
              child: Row(
                children: [

                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                  ),

                  SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      "View Policy Details",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.bodyGrey,
                  ),
                ],
              ),
            ),
          ),

          const FadedDivider(),

          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [

                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.download_rounded,
                            size: 18,
                          ),

                          SizedBox(width: 8),

                          Text(
                            "Invoice",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: 22,
                  color: AppColors.border,
                ),

                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmDeleteOrder(order),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFB23A3A),
                          ),

                          SizedBox(width: 8),

                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Color(0xFFB23A3A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (order.canClaim) ...[
            const SizedBox(height: 18),
            GradientCtaButton(
              icon: Icons.verified_user_outlined,
              label: "Claim Warranty",
              colors: const [
                Color(0xFF2D2D2D),
                Color(0xFF111111),
              ],
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int currentCount, int totalCount, int currentPage) {
    // Dynamic Pagination: Completely hide if there are 10 or fewer total orders.
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
          Row(
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
        ],
      ),
    );
  }

  Widget _buildPaginationButton(String label, {bool isEnabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isEnabled ? AppColors.ink : const Color(0xFFC7C7CC),
        ),
      ),
    );
  }

  Widget _buildPaginationNumber(String number, {bool isActive = false}) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.inkStrong : Colors.white,
        border: Border.all(color: isActive ? AppColors.inkStrong : AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppColors.ink,
        ),
      ),
    );
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
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPrimary ? 22 : 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.bodyGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}