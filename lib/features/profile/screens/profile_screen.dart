import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/screens/bloc/auth_bloc.dart';
import '../../../../core/constants/app_colors.dart' as app;
import '../../../../core/models/api_models.dart';
import '../../auth/screens/signup_screen.dart';
import '../../main_layout/bloc/bottom_nav_bloc.dart';
import '../../geofencing/services/geofence_manager.dart';
import 'debug_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: state is Authenticated
                  ? _AuthenticatedProfileView(key: const ValueKey('profile-authenticated'), user: state.user)
                  : const _GuestProfileView(key: ValueKey('profile-guest')),
            );
          },
        ),
      ),
    );
  }
}

class _AuthenticatedProfileView extends StatelessWidget {
  final AuthUser user;

  const _AuthenticatedProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        _ProfileHeroCard(
          user: user,
          onSupportTap: () => _showSupportSheet(context),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Account'),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'View your name, email, phone and account role',
          onTap: () => _showPersonalInfoSheet(context, user),
        ),
        _ActionCard(
          icon: Icons.receipt_long_outlined,
          title: 'My Policies',
          subtitle: 'Open your active and expired policies',
          onTap: () => context.read<BottomNavBloc>().add(TabChanged(1)),
        ),
        _ActionCard(
          icon: Icons.confirmation_number_outlined,
          title: 'My Gift Cards',
          subtitle: 'View your purchased vouchers and pins',
          onTap: () => Navigator.pushNamed(context, '/vouchers/history'),
        ),
        _ActionCard(
          icon: Icons.assignment_outlined,
          title: 'My Claims',
          subtitle: 'Open claim history and claim status',
          onTap: () => context.read<BottomNavBloc>().add(TabChanged(3)),
        ),
        _ActionCard(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          subtitle: 'Manage billing and delivery locations',
          onTap: () => _showAddressSheet(context, user),
        ),
        _ActionCard(
          icon: Icons.payment_outlined,
          title: 'Payment Methods',
          subtitle: 'Review how policy payments are handled',
          onTap: () => _showComingSoonSheet(
            context,
            title: 'Payment Methods',
            message: 'Payment method management is not available in this build yet.',
          ),
        ),
        _ActionCard(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Control claim and policy update alerts',
          onTap: () => _showNotificationsSheet(context),
        ),
        _GeofenceToggleCard(),
        _ActionCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Security',
          subtitle: 'Review login and account security details',
          onTap: () => _showSecuritySheet(context, user),
        ),
        _ActionCard(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with orders, claims and account issues',
          onTap: () => _showSupportSheet(context),
        ),
        if (kDebugMode)
          _ActionCard(
            icon: Icons.bug_report_outlined,
            title: 'Debug Settings',
            subtitle: 'Developer-only auth override',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugSettingsScreen()));
            },
          ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.logout,
          title: 'Log Out',
          subtitle: 'Sign out from this device',
          destructive: true,
          onTap: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully')),
            );
          },
        ),
      ],
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        _GuestHeroCard(
          onLoginTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                barrierDismissible: true,
                transitionDuration: const Duration(milliseconds: 360),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (context, _, __) => const SignupScreen(isModal: true),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return SlideTransition(
                    position: Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(curved),
                    child: FadeTransition(opacity: curved, child: child),
                  );
                },
              ),
            );
          },
          onSupportTap: () => _showSupportSheet(context),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Explore'),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'See how claim and policy updates are delivered',
          onTap: () => _showNotificationsSheet(context),
        ),
        _ActionCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Security',
          subtitle: 'Learn how your account is protected',
          onTap: () => _showSecuritySheet(context, null),
        ),
        _ActionCard(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help before you sign in',
          onTap: () => _showSupportSheet(context),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onSupportTap;

  const _ProfileHeroCard({
    required this.user,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [app.AppColors.heroBackground, app.AppColors.heroDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _initial(user.name),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : 'Account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isNotEmpty ? user.email : user.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: app.AppColors.textOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoleChip(role: user.role                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _HeroButton(
                label: 'Support',
                icon: Icons.support_agent,
                onTap: onSupportTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestHeroCard extends StatelessWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onSupportTap;

  const _GuestHeroCard({required this.onLoginTap, required this.onSupportTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [app.AppColors.heroBackground, app.AppColors.heroDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline, size: 34, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Guest',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sign in to manage policies, claims and account details.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: app.AppColors.textOnDarkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroButton(
                    label: 'Login / Sign Up',
                    icon: Icons.lock_open_rounded,
                    onTap: onLoginTap,
                    filled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroButton(
                    label: 'Support',
                    icon: Icons.support_agent,
                    onTap: onSupportTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: app.AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? const Color(0xFFB91C1C) : app.AppColors.ctaButton;
    final tint = destructive ? const Color(0xFFFEE2E2) : app.AppColors.inputFill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: app.AppColors.inputBorder.withValues(alpha: 0.55)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: destructive ? const Color(0xFFB91C1C) : app.AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: app.AppColors.textSecondary,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: destructive ? const Color(0xFFB91C1C).withValues(alpha: 0.55) : app.AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? app.AppColors.ctaButton : Colors.white.withValues(alpha: 0.08);
    const foreground = Colors.white;
    final borderColor = filled ? Colors.transparent : Colors.white.withValues(alpha: 0.16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role.isEmpty ? 'User' : role[0].toUpperCase() + role.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'U';
  return trimmed.substring(0, 1).toUpperCase();
}

Future<void> _showPersonalInfoSheet(BuildContext context, AuthUser? user) {
  if (user == null) return Future.value();
  final nameController = TextEditingController(text: user.name);
  final emailController = TextEditingController(text: user.email);
  final houseController = TextEditingController(text: user.house ?? '');
  final areaController = TextEditingController(text: user.area ?? '');
  final cityController = TextEditingController(text: user.city ?? '');
  final stateController = TextEditingController(text: user.state ?? '');
  final pinController = TextEditingController(text: user.pin ?? '');

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ProfileSheet(
        title: 'Personal Information',
        icon: Icons.person_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Editable fields
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: houseController,
              decoration: const InputDecoration(labelText: 'House / Shop No.'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: areaController,
              decoration: const InputDecoration(labelText: 'Area / Locality'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stateController,
              decoration: const InputDecoration(labelText: 'State'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(labelText: 'PIN Code'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Persist updates to profile
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final house = houseController.text.trim();
                  final area = areaController.text.trim();
                  final city = cityController.text.trim();
                  final state = stateController.text.trim();
                  final pin = pinController.text.trim();

                  // Dispatch update
                  try {
                    Navigator.pop(sheetContext);
                    // Delay to allow sheet to close before updating
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final bloc = context.read<AuthBloc>();
                      bloc.add(AuthUpdateProfileRequested(
                        name: name.isEmpty ? null : name,
                        email: email.isEmpty ? null : email,
                        house: house.isEmpty ? null : house,
                        area: area.isEmpty ? null : area,
                        city: city.isEmpty ? null : city,
                        state: state.isEmpty ? null : state,
                        pin: pin.isEmpty ? null : pin,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                    });
                  } catch (_) {}
                },
                child: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showAddressSheet(BuildContext context, AuthUser? user) {
  if (user == null) return Future.value();
  final houseController = TextEditingController(text: user.house ?? '');
  final areaController = TextEditingController(text: user.area ?? '');
  final cityController = TextEditingController(text: user.city ?? '');
  final stateController = TextEditingController(text: user.state ?? '');
  final pinController = TextEditingController(text: user.pin ?? '');

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ProfileSheet(
        title: 'Saved Address',
        icon: Icons.location_on_outlined,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: houseController, decoration: const InputDecoration(labelText: 'House / Shop No.')),
            const SizedBox(height: 12),
            TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Area / Locality')),
            const SizedBox(height: 12),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 12),
            TextField(controller: stateController, decoration: const InputDecoration(labelText: 'State')),
            const SizedBox(height: 12),
            TextField(controller: pinController, decoration: const InputDecoration(labelText: 'PIN Code'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final house = houseController.text.trim();
                  final area = areaController.text.trim();
                  final city = cityController.text.trim();
                  final state = stateController.text.trim();
                  final pin = pinController.text.trim();

                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final bloc = context.read<AuthBloc>();
                    bloc.add(AuthUpdateProfileRequested(
                      house: house.isEmpty ? null : house,
                      area: area.isEmpty ? null : area,
                      city: city.isEmpty ? null : city,
                      state: state.isEmpty ? null : state,
                      pin: pin.isEmpty ? null : pin,
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
                  });
                },
                child: const Text('Save Address'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return const _ProfileSheet(
        title: 'Notifications',
        icon: Icons.notifications_none_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetBullet(text: 'Policy updates and payment reminders'),
            _SheetBullet(text: 'Claim status and review notifications'),
            _SheetBullet(text: 'Support and account alerts'),
          ],
        ),
      );
    },
  );
}

Future<void> _showSecuritySheet(BuildContext context, AuthUser? user) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ProfileSheet(
        title: 'Privacy & Security',
        icon: Icons.privacy_tip_outlined,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetBullet(text: 'Your login is protected with OTP-based authentication.'),
            const _SheetBullet(text: 'Account data stays tied to your registered mobile number.'),
            _SheetBullet(
              text: user == null ? 'Sign in to review account security details.' : 'Logged in as ${user.phone}',
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return const _ProfileSheet(
        title: 'Help & Support',
        icon: Icons.help_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetBullet(text: 'Use My Policies to review coverage and order status.'),
            _SheetBullet(text: 'Use My Claims to track existing claims.'),
            _SheetBullet(text: 'If something looks wrong, contact your support team.'),
          ],
        ),
      );
    },
  );
}

Future<void> _showComingSoonSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ProfileSheet(
        title: title,
        icon: Icons.construction_outlined,
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: app.AppColors.textSecondary,
          ),
        ),
      );
    },
  );
}

class _ProfileSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileSheet({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: app.AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: app.AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: app.AppColors.ctaButton),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: app.AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.ctaButton,
                    foregroundColor: app.AppColors.ctaButtonText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SheetInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: app.AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: app.AppColors.textHint,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: app.AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetBullet extends StatelessWidget {
  final String text;

  const _SheetBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: app.AppColors.sunOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: app.AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeofenceToggleCard extends StatefulWidget {
  @override
  State<_GeofenceToggleCard> createState() => _GeofenceToggleCardState();
}

class _GeofenceToggleCardState extends State<_GeofenceToggleCard> {
  bool _enabled = true; // Should ideally come from a dedicated Bloc/Settings service

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: app.AppColors.inputBorder.withValues(alpha: 0.55)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: app.AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_outlined, size: 22, color: app.AppColors.ctaButton),
          ),
          title: const Text(
            'Partner Offer Alerts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: app.AppColors.textPrimary,
            ),
          ),
          subtitle: const Text(
            'Get notified about discounts when near partner stores',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: app.AppColors.textSecondary,
            ),
          ),
          trailing: Switch.adaptive(
            value: _enabled,
            activeColor: app.AppColors.ctaButton,
            onChanged: (val) async {
              setState(() => _enabled = val);
              final manager = context.read<GeofenceManager>();
              if (val) {
                await manager.initializeTracelet();
              } else {
                await manager.stopAll();
              }
            },
          ),
        ),
      ),
    );
  }
}
