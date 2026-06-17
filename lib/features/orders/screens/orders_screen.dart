import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/orders_bloc.dart';

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
    'Claim Approved',
    'Pending',
    'Cancelled'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScreenHeader(context),
                          const SizedBox(height: 24),
                          _buildFilterRow(),
                          const SizedBox(height: 24),
                          _buildOrdersTable(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'DIGIPE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: const Color(0xFFE5E5EA)),
          const SizedBox(width: 16),
          const Text(
            'Hello, +917206787699',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined,
                size: 20, color: Color(0xFF48484A)),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E5EA),
            child: Icon(Icons.person, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Orders',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A)),
        ),
        SizedBox(height: 2),
        Text(
          'View and manage your insurance policies.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
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
      decoration: InputDecoration(
        hintText: 'Search Order ID...',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
        prefixIcon:
        const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8E8E93)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8E8E93)),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status,
                  style:
                  const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
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

  Widget _buildOrdersTable(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                color: Color(0xFF1A1A1A),
              ),
            ),
          );
        }

        if (state is OrdersError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                state.message,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        }

        if (state is OrdersLoaded) {
          return Column(
            children: [
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),

          const SizedBox(height: 20),

          _buildDetailRow(Icons.shopping_bag_outlined, order.product),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.currency_rupee, order.amount, isBold: true),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_outlined, order.date),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'View',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.file_download_outlined,
                  label: 'Invoice',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  onTap: () {},
                ),
              ),
            ],
          ),

          if (order.canClaim) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Claim Warranty', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? const Color(0xFF1A1A1A) : const Color(0xFF48484A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        side: const BorderSide(color: Color(0xFFE5E5EA)),
        foregroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 44),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int currentCount, int totalCount, int currentPage) {
    // Dynamic Pagination: Completely hide if there are 10 or fewer total orders.
    if (totalCount <= 10) {
      return const SizedBox.shrink();
    }

    final int itemsPerPage = 10;
    final int totalPages = (totalCount / itemsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Text(
            'Showing 1 to $currentCount of $totalCount entries',
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaginationButton('Previous', isEnabled: currentPage > 1),
              const SizedBox(width: 8),

              // Dynamically build page numbers based on the total items
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
        color: isEnabled ? Colors.white : const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isEnabled ? const Color(0xFF1A1A1A) : const Color(0xFFC7C7CC),
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
        color: isActive ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}