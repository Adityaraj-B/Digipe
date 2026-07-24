import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/screens/bloc/auth_bloc.dart';
import '../../auth/screens/signup_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../track/screens/track_screen.dart';
import '../bloc/bottom_nav_bloc.dart';
import '../../home/screens/home_screen.dart';
import '../../claims/screens/claims_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../vouchers/screens/hubble_store_screen.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavBloc(),
      child: const _MainLayoutView(),
    );
  }
}

class _MainLayoutView extends StatefulWidget {
  const _MainLayoutView();

  @override
  State<_MainLayoutView> createState() => _MainLayoutViewState();
}

class _MainLayoutViewState extends State<_MainLayoutView> {
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, state) {
        final isForward = state.currentIndex >= _previousIndex;
        _previousIndex = state.currentIndex;

        return PopScope(
          canPop: state.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (state.currentIndex != 0) {
              context.read<BottomNavBloc>().add(TabChanged(0));
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              reverseDuration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideDistance = isForward ? 0.04 : -0.04;
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(0.0, slideDistance),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );

                final fadeAnimation = CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
                  reverseCurve: const Interval(0.0, 0.85, curve: Curves.easeIn),
                );

                final scaleAnimation = Tween<double>(
                  begin: 0.985,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                );

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(state.currentIndex),
                child: _buildBody(state.currentIndex),
              ),
            ),
            extendBody: true,
            bottomNavigationBar:
                _buildBottomNavigationBar(context, state.currentIndex),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF131313),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF1C1C1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 24,
      title: Image.asset(
        'assets/images/Logo White.png',
        height: 32,
        fit: BoxFit.contain,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
      ),
      actions: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: state is Authenticated
                    ? _buildAvatarButton(context, state)
                    : _buildLoginButton(context),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatarButton(BuildContext context, Authenticated state) {
    return IconButton(
      key: const ValueKey('avatar'),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF00BFA5),
        child: Text(
          state.user.name.isNotEmpty
              ? state.user.name.substring(0, 1).toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      onPressed: () {
        context.read<BottomNavBloc>().add(TabChanged(5));
      },
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Center(
      key: const ValueKey('login'),
      child: _PressableScale(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: true,
              transitionDuration: const Duration(milliseconds: 360),
              reverseTransitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (context, _, __) =>
                  const SignupScreen(isModal: true),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return SlideTransition(
                  position:
                      Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                          .animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
              },
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1.0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const OrdersScreen();
      case 2:
        return const OrderTrackingScreen();
      case 3:
        return const HubbleStoreScreen();
      case 4:
        return const ClaimsScreen();
      case 5:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding > 0 ? bottomPadding : 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: navBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _AnimatedNavBar(
                    currentIndex: currentIndex,
                    onTap: (index) {
                      context.read<BottomNavBloc>().add(TabChanged(index));
                    },
                    items: const [
                      _NavItemData(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Home'),
                      _NavItemData(
                        icon: Icons.description_outlined,
                        activeIcon: Icons.description,
                        label: 'Orders',
                      ),
                      _NavItemData(
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search,
                          label: 'Track'),
                      _NavItemData(
                        icon: Icons.card_giftcard_outlined,
                        activeIcon: Icons.card_giftcard,
                        label: 'Gift Card',
                      ),
                      _NavItemData(
                          icon: Icons.shield_outlined,
                          activeIcon: Icons.shield,
                          label: 'Claims'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData(
      {required this.icon, required this.activeIcon, required this.label});
}

class _AnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final selectedColor = isDark ? Colors.white : const Color(0xFF000000);
    final unselectedColor =
        isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93);
    return Container(
      color: navBg,
      height: 64,
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          final item = items[index];

          return Expanded(
            child: _PressableScale(
              onTap: () => onTap(index),
              minScale: 0.88,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) {
                        return Transform.scale(
                          scale: 1.0 + (0.12 * t),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 24,
                            color:
                                Color.lerp(unselectedColor, selectedColor, t),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        height: 1.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                      child: Text(item.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double minScale;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.minScale = 0.92,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.minScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
