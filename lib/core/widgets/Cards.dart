import 'package:flutter/material.dart';

/// Height the floating bottom nav bar occupies from the bottom of the
/// screen (its own height + margins + the largest realistic safe-area
/// inset). Every scrollable screen should add this as bottom padding so
/// content can scroll fully clear of the floating bar instead of being
/// clipped behind it.
const double kNavBarClearance = 130.0;

/// Single source of truth for the "premium" design language used across
/// DIGIPe screens (Order Tracking, My Orders, etc). Keep colors, radii and
/// shadow language here so every screen stays visually consistent — if the
/// brand color or card elevation ever changes, it changes everywhere at once.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF111111);
  static const inkStrong = Color(0xFF1A1A1A);
  static const bodyGrey = Color(0xFF6E6E73);
  static const labelGrey = Color(0xFF8E8E93);
  static const surface = Color(0xFFF9F9FA);
  static const border = Color(0xFFE8E8ED);
  static const hairline = Color(0xFFF0F0F2);
  static const valueDark = Color(0xFF222222);

  static const successBg = Color(0xFFE8F8EE);
  static const successFg = Color(0xFF238643);
  static const infoBg = Color(0xFFF0F6FF);
  static const infoFg = Color(0xFF2B78C5);
  static const warnBg = Color(0xFFFFF9E6);
  static const warnFg = Color(0xFFB5850B);
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerFg = Color(0xFF992727);
  static const neutralBg = Color(0xFFF5F5F5);
  static const neutralFg = Color(0xFF666666);
}

/// The rounded, softly-shadowed card used for every content block.
/// This is the one place that defines "what a card looks like" in the app.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF2F2F2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Generic pill-shaped status chip. Pass a semantic bg/fg pair (success,
/// info, warning, danger, neutral) so every status badge in the app -
/// order tracking, orders list, claims - looks identical.
class StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: foreground.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Small label-over-value pair, e.g. "POLICY TYPE" / "Comprehensive".
class MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const MetaItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.bodyGrey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.valueDark,
          ),
        ),
      ],
    );
  }
}

/// Full-width row action (icon + label + optional chevron), used for
/// "Download Policy", "View Invoice", etc.
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showChevron;

  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: iconColor ?? const Color(0xFF3F3F46),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.valueDark,
                    ),
                  ),
                ),
                if (enabled && showChevron)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFFC5C5C5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact icon-over/beside-label action used when several actions sit
/// side by side in a row (e.g. View / Invoice / Delete on an order card).
class CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const CompactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.valueDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient call-to-action pill, e.g. "Proceed to Payment", "Claim Warranty".
class GradientCtaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  const GradientCtaButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.colors = const [Color(0xFF2ECC71), Color(0xFF27AE60)],
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared screen header (title + subtitle) so typography/spacing at the
/// top of every tab matches exactly.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Optional content rendered below the subtitle inside the same white
  /// header block, e.g. a TabBar (Claims Center uses this).
  final Widget? bottom;

  /// Sizing knobs so an individual screen can render a shorter header
  /// (e.g. Home) without affecting the default used everywhere else.
  final EdgeInsetsGeometry? padding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double gap;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.bottom,
    this.padding,
    this.titleFontSize = 28,
    this.subtitleFontSize = 15,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? EdgeInsets.fromLTRB(24, 28, 24, bottom != null ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: gap),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.bodyGrey,
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: 20),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Standard fade + slide-up entrance used on every screen body, so
/// navigating between tabs feels like one coherent app.
class PremiumEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const PremiumEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, value, c) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

/// A soft hairline divider with a faded gradient edge, matching the one
/// used inside the order tracking info card.
class FadedDivider extends StatelessWidget {
  const FadedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.hairline.withValues(alpha: 0.2),
            AppColors.hairline,
            AppColors.hairline.withValues(alpha: 0.2),
          ],
        ),
      ),
    );
  }
}

/// Circle-icon empty/error state, matching the tracking screen's error view.
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color iconBg;
  final Color iconFg;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconBg = AppColors.neutralBg,
    this.iconFg = AppColors.neutralFg,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: iconFg.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 36, color: iconFg),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: onAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            actionLabel!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}