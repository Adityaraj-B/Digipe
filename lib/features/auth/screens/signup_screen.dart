import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/notification_service.dart';
import 'bloc/auth_bloc.dart';
import '../../../../core/widgets/sun_illustration.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../main_layout/screens/main_layout_screen.dart';
import 'otp_entry_screen.dart';

const _kTermsUrl = 'https://digipe.com/about-digipe/terms-and-conditions/';
const _kPrivacyUrl = 'https://digipe.com/about-digipe/privacy-policy/';

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open page. Please try again.')),
      );
    }
  }
}

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
    final identifier = _phoneController.text.trim();

    if (_isRegisterMode) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      if (identifier.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        _showError('Please enter a valid 10-digit mobile number');
        return;
      }
      if (name.length < 2) {
        _showError('Full Name must be at least 2 characters');
        return;
      }
      if (!AuthUtils.isValidEmail(email)) {
        _showError('Please enter a valid email address');
        return;
      }

      context.read<AuthBloc>().add(RegisterRequested(fullName: name, phone: identifier, email: email));
    } else {
      if (identifier.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        _showError('Please enter a valid 10-digit mobile number');
        return;
      }
      context.read<AuthBloc>().add(SendOtpRequested(identifier));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        if (current is AwaitingOtp && previous is Verifying) {
          return false;
        }
        return true;
      },
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
            _userNotFoundMessage = state.message;
            _isRegisterMode = true;
          });
          _showError(state.message);
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final isTablet = width >= 600;
              final isShort = height < 700;

              final scale = (width / 390).clamp(0.85, 1.25);

              final heroMinHeight = (height * (isShort ? 0.30 : 0.38))
                  .clamp(220.0, 380.0);
              final sunSize = (100 * scale).clamp(80.0, 130.0);
              final formMaxWidth = isTablet ? 480.0 : double.infinity;
              final horizontalPadding = isTablet ? 32.0 : 24.0 * scale;

              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is OtpSending;
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: heroMinHeight),
                          child: RepaintBoundary(
                            child: _HeroSection(
                              isModal: widget.isModal,
                              sunSize: sunSize,
                              scale: scale,
                              isTablet: isTablet,
                            ),
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        fillOverscroll: false,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: formMaxWidth),
                            child: RepaintBoundary(
                              child: _buildFormSheet(
                                isLoading,
                                scale: scale,
                                horizontalPadding: horizontalPadding,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormSheet(
      bool isLoading, {
        required double scale,
        required double horizontalPadding,
      }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 24 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRegisterMode ? 'Register Account' : 'Welcome to DIGIPe!',
            style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8 * scale),
          if (_userNotFoundMessage != null && _isRegisterMode)
            Padding(
              padding: EdgeInsets.only(bottom: 8.0 * scale),
              child: Text(
                _userNotFoundMessage!,
                style: TextStyle(color: Colors.red, fontSize: 13 * scale, fontWeight: FontWeight.w500),
              ),
            ),
          Text(
            _isRegisterMode
                ? 'Join India\'s most trusted solar insurance platform'
                : 'Please enter your mobile number to continue',
            style: TextStyle(color: Colors.grey, fontSize: 13 * scale),
          ),
          SizedBox(height: 24 * scale),

          if (_isRegisterMode) ...[
            _label('Full Name', scale),
            _textField(
              controller: _nameController,
              focusNode: _nameFocus,
              hint: 'Enter your full name',
              nextFocus: _phoneFocus,
              scale: scale,
            ),
            SizedBox(height: 16 * scale),
          ],

          _label('Phone Number', scale),
          _textField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            hint: _isRegisterMode ? 'Enter 10-digit number' : 'Enter 10-digit mobile number',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            nextFocus: _isRegisterMode ? _emailFocus : null,
            readOnly: _isRegisterMode,
            scale: scale,
          ),
          SizedBox(height: 16 * scale),

          if (_isRegisterMode) ...[
            _label('Email Address', scale),
            _textField(
              controller: _emailController,
              focusNode: _emailFocus,
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              scale: scale,
            ),
            SizedBox(height: 24 * scale),
          ],

          SizedBox(
            width: double.infinity,
            height: 54 * scale,
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
                  ? SizedBox(
                width: 20 * scale,
                height: 20 * scale,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                _isRegisterMode ? 'Register & Send OTP' : 'Continue',
                style: TextStyle(fontSize: 15 * scale),
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
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
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13 * scale),
              ),
            ),
          ),

          // Terms & Privacy consent — shown on register mode
          if (_isRegisterMode)
            Padding(
              padding: EdgeInsets.only(top: 4 * scale),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'By registering you agree to our ',
                      style: TextStyle(fontSize: 11 * scale, color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => _openUrl(context, _kTermsUrl),
                      child: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: TextStyle(fontSize: 11 * scale, color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => _openUrl(context, _kPrivacyUrl),
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      '.',
                      style: TextStyle(fontSize: 11 * scale, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text, double scale) => Padding(
    padding: EdgeInsets.only(bottom: 8 * scale),
    child: Text(text, style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.bold)),
  );

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required double scale,
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
      style: TextStyle(fontSize: 14 * scale),
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) => nextFocus != null ? FocusScope.of(context).requestFocus(nextFocus) : _onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14 * scale),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 14 * scale),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isModal;
  final double sunSize;
  final double scale;
  final bool isTablet;

  const _HeroSection({
    required this.isModal,
    required this.sunSize,
    required this.scale,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 8 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DIGIPE',
                    style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => isModal ? Navigator.pop(context) : context.read<AuthBloc>().add(AuthSkipRequested()),
                    child: Text('Skip', style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
                  )
                ],
              ),
            ),
            SizedBox(height: 12 * scale),
            SunIllustration(size: sunSize),
            SizedBox(height: 24 * scale),
            Text(
              'Solar Insurance',
              style: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 40 * scale),
              child: Text(
                "Protect your investment with India's most trusted solar insurance platform",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14 * scale),
              ),
            ),
            SizedBox(height: 24 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
              child: HeroStatsRow(scale: scale),
            ),
            SizedBox(height: 12 * scale),
          ],
        ),
      ),
    );
  }
}

class HeroStatsRow extends StatelessWidget {
  final double scale;
  const HeroStatsRow({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Policies',
            value: '624k',
            change: '+8.24%',
            scale: scale,
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: _StatCard(
            label: 'Claims Settled',
            value: '124k',
            change: '+12.6%',
            scale: scale,
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
  final double scale;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
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
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            change,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF4ADE80),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}