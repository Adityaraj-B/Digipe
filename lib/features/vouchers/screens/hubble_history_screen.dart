import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/hubble_bloc.dart';
import '../services/hubble_sdk_service.dart';

/// Shows the user's Hubble gift card transaction history fetched from the backend.
class HubbleHistoryScreen extends StatefulWidget {
  const HubbleHistoryScreen({super.key});

  @override
  State<HubbleHistoryScreen> createState() => _HubbleHistoryScreenState();
}

class _HubbleHistoryScreenState extends State<HubbleHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HubbleBloc>().add(LoadHubbleHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocBuilder<HubbleBloc, HubbleState>(
              builder: (context, state) {
                if (state is HubbleHistoryLoading) return _buildLoader();
                if (state is HubbleHistoryError) return _buildError(state.message);
                if (state is HubbleHistoryLoaded) {
                  if (state.transactions.isEmpty) return _buildEmpty();
                  return _buildList(state.transactions);
                }
                return _buildLoader();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'My Transactions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 22),
                    onPressed: () => context.read<HubbleBloc>().add(LoadHubbleHistory()),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // List
  // ─────────────────────────────────────────

  Widget _buildList(List<HubbleTransaction> txns) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TransactionCard(transaction: txns[i]),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFF5A623)),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.read<HubbleBloc>().add(LoadHubbleHistory()),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 40, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 18),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your gift card purchases will appear here.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Transaction Card
// ─────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final HubbleTransaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transaction.status);
    final dateStr = DateFormat('dd MMM yyyy, h:mm a').format(transaction.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_eventIcon(transaction.eventType), color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.brand ?? transaction.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.displayLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Amount + status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${transaction.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel(transaction.status),
                  style: TextStyle(
                    color: statusColor,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF34C759);
      case 'failed':
        return Colors.redAccent;
      case 'refunded':
        return const Color(0xFF007AFF);
      default:
        return const Color(0xFFF5A623);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'COMPLETED';
      case 'failed':
        return 'FAILED';
      case 'refunded':
        return 'REFUNDED';
      default:
        return 'PENDING';
    }
  }

  IconData _eventIcon(String eventType) {
    switch (eventType) {
      case 'payment_success':
      case 'order_placed':
        return Icons.check_circle_outline_rounded;
      case 'voucher_generated':
        return Icons.card_giftcard_rounded;
      case 'voucher_redeemed':
        return Icons.redeem_rounded;
      case 'refund_completed':
      case 'refund_initiated':
        return Icons.keyboard_return_rounded;
      case 'payment_failed':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
