import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_protector/screen_protector.dart';
import '../bloc/redemption_bloc.dart';
import '../models/voucher_models.dart';

class VoucherProcessingScreen extends StatefulWidget {
  final String productId;
  final List<Map<String, dynamic>> denominationDetails;

  const VoucherProcessingScreen({
    super.key,
    required this.productId,
    required this.denominationDetails,
  });

  @override
  State<VoucherProcessingScreen> createState() => _VoucherProcessingScreenState();
}

class _VoucherProcessingScreenState extends State<VoucherProcessingScreen> {
  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    context.read<RedemptionBloc>().add(PlaceVoucherOrder(
      productId: widget.productId,
      denominationDetails: widget.denominationDetails,
    ));
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back navigation during processing
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final state = context.read<RedemptionBloc>().state;
        if (state is RedemptionSuccess || state is RedemptionFailed) {
          context.read<RedemptionBloc>().add(ResetRedemption());
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Redeem Voucher'),
          backgroundColor: const Color(0xFF131313),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            BlocBuilder<RedemptionBloc, RedemptionState>(
              builder: (context, state) {
                if (state is RedemptionSuccess || state is RedemptionFailed) {
                  return IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      context.read<RedemptionBloc>().add(ResetRedemption());
                      Navigator.pop(context);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        body: BlocConsumer<RedemptionBloc, RedemptionState>(
          listener: (context, state) {
            if (state is RedemptionSuccess) {
              // Haptics or sound for success could go here
            }
          },
          builder: (context, state) {
            if (state is RedemptionPlacingOrder || state is RedemptionInitial) {
              return _buildProcessingView('Placing your order...');
            }
            if (state is RedemptionProcessing) {
              return _buildProcessingView(
                'Your voucher is being generated...\nAttempt ${state.attempt + 1} of 5',
                showPollingInfo: true,
              );
            }
            if (state is RedemptionSuccess) {
              return _buildSuccessView(state.result);
            }
            if (state is RedemptionFailed) {
              return _buildFailedView(state.message);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildProcessingView(String message, {bool showPollingInfo = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFF5A623)),
            const SizedBox(height: 32),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (showPollingInfo) ...[
              const SizedBox(height: 16),
              Text(
                'This may take a few minutes as per our partner policy. Please do not close the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(VoucherOrderResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Redemption Successful!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Voucher Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...result.vouchers.map((v) => _VoucherCredentialCard(voucher: v)),
          const SizedBox(height: 24),
          const Text(
            'Note: This screen is protected. Screenshots and screen recording are disabled for your security.',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<RedemptionBloc>().add(ResetRedemption());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF131313),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RedemptionBloc>().add(ResetRedemption());
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherCredentialCard extends StatelessWidget {
  final VoucherCredential voucher;
  const _VoucherCredentialCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  '₹${voucher.amount}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF131313)),
                ),
              ],
            ),
            const Divider(height: 32),
            if (voucher.showCardNumber && voucher.cardNumber != null)
              _CredentialRow(label: 'Card Number', value: voucher.cardNumber!),
            if (voucher.showCardPin && voucher.cardPin != null)
              _CredentialRow(label: 'Voucher PIN', value: voucher.cardPin!),
            if (voucher.validTill != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Valid until: ${voucher.validTill!.day}/${voucher.validTill!.month}/${voucher.validTill!.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredentialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFFF5A623)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
