import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/bloc/auth_bloc.dart';
import '../../../../core/widgets/sun_illustration.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../main_layout/screens/main_layout_screen.dart';
import 'otp_entry_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isModal;
  const SignupScreen({super.key, this.isModal = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _isRegisterMode = false;
  String? _userNotFoundMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }

    if (_isRegisterMode) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      if (name.length < 2) {
        _showError('Full Name must be at least 2 characters');
        return;
      }
      if (!AuthUtils.isValidEmail(email)) {
        _showError('Please enter a valid email address');
        return;
      }

      context.read<AuthBloc>().add(RegisterRequested(fullName: name, phone: phone, email: email));
    } else {
      context.read<AuthBloc>().add(SendOtpRequested(phone));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AwaitingOtp) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  OtpEntryScreen(isModal: widget.isModal),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const curve = Curves.easeOutQuart;
                final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(curvedAnimation),
                  child: child,
                );
              },
            ),
          );
        } else if (state is Authenticated) {
          if (widget.isModal) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
                  (route) => false,
            );
          }
        } else if (state is AuthUserNotFound) {
          setState(() {
            _isRegisterMode = true;
            _userNotFoundMessage = state.message;
          });
          _showError(state.message);
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        resizeToAvoidBottomInset: true,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is OtpSending;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: RepaintBoundary(
                          child: _HeroSection(isModal: widget.isModal),
                        ),
                      ),
                      RepaintBoundary(
                        child: _buildFormSheet(isLoading),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormSheet(bool isLoading) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRegisterMode ? 'Register Account' : 'Welcome to DIGIPe!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_userNotFoundMessage != null && _isRegisterMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _userNotFoundMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          Text(
            _isRegisterMode
                ? 'Join India\'s most trusted solar insurance platform'
                : 'Please enter your phone number to continue',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_isRegisterMode) ...[
            _label('Full Name'),
            _textField(
              controller: _nameController,
              focusNode: _nameFocus,
              hint: 'Enter your full name',
              nextFocus: _phoneFocus,
            ),
            const SizedBox(height: 16),
          ],

          _label('Phone Number'),
          _textField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            hint: 'Enter 10-digit number',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            nextFocus: _isRegisterMode ? _emailFocus : null,
            readOnly: _isRegisterMode,
          ),
          const SizedBox(height: 16),

          if (_isRegisterMode) ...[
            _label('Email Address'),
            _textField(
              controller: _emailController,
              focusNode: _emailFocus,
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : () {
                NotificationService.mediumImpact();
                _onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isRegisterMode ? 'Register & Send OTP' : 'Continue'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                NotificationService.lightImpact();
                setState(() {
                  _isRegisterMode = !_isRegisterMode;
                  _userNotFoundMessage = null;
                });
              },
              child: Text(
                _isRegisterMode ? 'Back to Login' : 'Don\'t have an account? Sign Up',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
  );

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) => nextFocus != null ? FocusScope.of(context).requestFocus(nextFocus) : _onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
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
                const Text('DIGIPE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: () => isModal ? Navigator.pop(context) : context.read<AuthBloc>().add(AuthSkipRequested()),
                  child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                )
              ],
            ),
          ),
          const Spacer(),
          const SunIllustration(size: 100),
          const SizedBox(height: 24),
          const Text('Solar Insurance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Protect your investment with India's most trusted solar insurance platform",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: HeroStatsRow(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class HeroStatsRow extends StatelessWidget {
  const HeroStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Policies',
            value: '624k',
            change: '+8.24%',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Claims Settled',
            value: '124k',
            change: '+12.6%',
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4ADE80),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}