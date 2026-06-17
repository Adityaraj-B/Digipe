import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Bloc/payment_success_bloc.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;

  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      PaymentSuccessBloc()..add(FetchPaymentSuccessDetails(orderId)),
      child: const _PaymentSuccessView(),
    );
  }
}

class _PaymentSuccessView extends StatelessWidget {
  const _PaymentSuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Divider(height: 1, color: Color(0xFFE5E5EA)),
            Expanded(
              child: BlocBuilder<PaymentSuccessBloc, PaymentSuccessState>(
                builder: (context, state) {
                  if (state is PaymentSuccessLoading ||
                      state is PaymentSuccessInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2C2C2E)),
                    );
                  } else if (state is PaymentSuccessError) {
                    return Center(child: Text(state.message));
                  } else if (state is PaymentSuccessLoaded) {
                    return _buildContent(context, state.data);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'DIGIPE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: const Color(0xFFE5E5EA)),
          const SizedBox(width: 16),
          const Text(
            'Hello, +917206787699',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, size: 20),
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

  Widget _buildContent(BuildContext context, PaymentSuccessData data) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F5E9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${data.policyName} policy has been issued successfully.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildCard(
                child: Column(
                  children: [
                    _buildDetailRow('Order ID', data.orderId),
                    const SizedBox(height: 16),
                    _buildDetailRow('Policy Number', data.policyNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow('Amount Paid', data.amountPaid, isBold: true),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status',
                            style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            data.status,
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      '1',
                      'Our team will review the uploaded documents within 24-48 hours.',
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      '2',
                      'You can download the digital copy of your policy below.',
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      '3',
                      'In case of damage, you can raise a claim from the order tracking screen.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description_outlined, size: 20),
                  label: const Text(
                    'View Order & Track',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF5F5F5),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}