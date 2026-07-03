import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';
import '../../auth/screens/signup_screen.dart';
import 'debug_settings_screen.dart';
import '../../../../core/models/api_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return TweenAnimationBuilder<double>(
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
          child: state is Authenticated
              ? _buildProfileContent(context, state.user)
              : _buildGuestContent(context),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthUser user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildProfileHeader(user),
          const SizedBox(height: 32),
          _buildSettingsList(context, true),
          const SizedBox(height: 40),
          const Text(
            '© 2026, Made with ❤️ by DIGIPe',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFC7C7CC),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F2F7),
                border: Border.all(color: const Color(0xFFE5E5EA), width: 2),
              ),
              child: const Icon(Icons.person_outline, size: 50, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome, Guest',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login to access your policies, claims, and personalized settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      barrierDismissible: true,
                      pageBuilder: (context, _, __) => const SignupScreen(isModal: true),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutQuart;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF131313),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Login / Sign Up', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 48),
            _buildSettingsList(context, false),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthUser user) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C2C34),
            border: Border.all(color: const Color(0xFF34C759), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.phone,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, bool isAuthenticated) {
    return Column(
      children: [
        if (isAuthenticated) ...[
          _buildSettingItem(Icons.person_outline, 'Personal Information', onTap: () {}),
          _buildSettingItem(Icons.location_on_outlined, 'Saved Addresses', onTap: () {}),
          _buildSettingItem(Icons.payment_outlined, 'Payment Methods', onTap: () {}),
        ],
        _buildSettingItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
        if (kDebugMode)
          _buildSettingItem(Icons.bug_report_outlined, 'Debug Settings', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugSettingsScreen()));
          }),
        _buildSettingItem(Icons.privacy_tip_outlined, 'Privacy & Security', onTap: () {}),
        _buildSettingItem(Icons.help_outline, 'Help & Support', onTap: () {}),
        if (isAuthenticated) ...[
          const SizedBox(height: 16),
          _buildSettingItem(Icons.logout, 'Log Out', isDestructive: true, onTap: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully')),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {bool isDestructive = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF131313).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF131313),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? Colors.red.withValues(alpha: 0.6) : const Color(0xFFC7C7CC),
        ),
        onTap: onTap,
      ),
    );
  }
}
