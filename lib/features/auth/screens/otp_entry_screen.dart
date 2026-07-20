import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_protector/screen_protector.dart';
import 'bloc/auth_bloc.dart';
import '../../main_layout/screens/main_layout_screen.dart';


class OtpEntryScreen extends StatefulWidget {
  final bool isModal;
  const OtpEntryScreen({super.key, this.isModal = false});

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  // SECTION 11: OTP Rate Limiting (Cooldown)
  int _secondsLeft = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // SECTION 7: Prevent screen capture
    ScreenProtector.preventScreenshotOn();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _cooldownTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onVerify() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      context.read<AuthBloc>().add(VerifyOtpRequested(code));
    }
  }

  void _onResend() {
    final state = context.read<AuthBloc>().state;
    if (state is AwaitingOtp) {
      context.read<AuthBloc>().add(SendOtpRequested(state.phoneNumber));
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new OTP has been sent.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          if (widget.isModal) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
              (route) => false,
            );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AwaitingOtp && state.attemptsLeft < 5) {
          // If we are back to AwaitingOtp with fewer attempts, it means verification failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid OTP. ${state.attemptsLeft} attempts remaining.'))
          );
        }
      },
      builder: (context, state) {
        final isVerifying = state is Verifying;
        final isSending = state is OtpSending;
        
        String targetIdentifier = 'your mobile number';
        if (state is AwaitingOtp) {
          targetIdentifier = state.verificationIdentifier;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white, 
            elevation: 0, 
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18), 
              onPressed: () => Navigator.pop(context)
            )
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter OTP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('We have sent a 6-digit code to $targetIdentifier.', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _otpBox(index, isVerifying)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isVerifying || isSending ? null : _onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isVerifying 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Verify OTP'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _secondsLeft > 0 || isVerifying || isSending ? null : _onResend,
                    child: Text(
                      _secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend OTP', 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _otpBox(int index, bool disabled) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !disabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty) {
            _onVerify();
          }
        },
      ),
    );
  }
}
