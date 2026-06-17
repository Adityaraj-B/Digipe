import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';
import '../../../../core/widgets/sun_illustration.dart';

class SignupScreen extends StatefulWidget {
  final bool isModal;
  const SignupScreen({super.key, this.isModal = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    
    if (phone.length < 10) return;
    if (otp.length < 6) return;

    context.read<AuthBloc>().add(AuthLoginRequested(phone: phone, otp: otp));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (widget.isModal) {
            Navigator.pop(context);
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        resizeToAvoidBottomInset: true,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final bool isLocalLoading = state is AuthLoading;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: _HeroSection(isModal: widget.isModal),
                  ),
                  _BottomFormSheet(
                    isLoading: isLocalLoading,
                    phoneController: _phoneController,
                    otpController: _otpController,
                    phoneFocus: _phoneFocus,
                    otpFocus: _otpFocus,
                    onVerify: _onVerify,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isModal;
  const _HeroSection({required this.isModal});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DIGIPE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isModal) {
                      Navigator.pop(context);
                    } else {
                      context.read<AuthBloc>().add(AuthSkipRequested());
                    }
                  },
                  child: const Text('Skip', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                )
              ],
            ),
          ),
          const Spacer(flex: 2),
          const SunIllustration(size: 80),
          const SizedBox(height: 24),
          const Text(
            'Solar Insurance',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Protect your investment with India's most trusted\nsolar insurance platform",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(label: 'Policies', value: '624k', change: '+8.24%'),
              SizedBox(width: 16),
              _StatCard(label: 'Claims Settled', value: '124k', change: '+12.6%'),
            ],
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA1A1A6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF34C759),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomFormSheet extends StatelessWidget {
  final bool isLoading;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final FocusNode phoneFocus;
  final FocusNode otpFocus;
  final VoidCallback onVerify;

  const _BottomFormSheet({
    required this.isLoading,
    required this.phoneController,
    required this.otpController,
    required this.phoneFocus,
    required this.otpFocus,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        24,
        32,
        24,
        bottomInset > 0 ? bottomInset + 24 : bottomPadding + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome to DIGIPe! ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                TextSpan(
                  text: '👋',
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter your phone number to continue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Phone Number',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          _CustomTextField(
            controller: phoneController,
            focusNode: phoneFocus,
            hintText: 'Enter phone number',
            keyboardType: TextInputType.phone,
            nextFocus: otpFocus,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          _CustomTextField(
            controller: otpController,
            focusNode: otpFocus,
            hintText: 'Enter 6-digit OTP',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Verify OTP & Continue',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const _CustomTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.keyboardType,
    this.nextFocus,
    required this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction:
      nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF1C1C1E),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFC7C7CC),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2C2C2E), width: 1.5),
        ),
      ),
    );
  }
}