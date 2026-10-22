import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/snackbars.dart';
import '../../viewmodels/auth/session_view_model.dart';

/// Bottom navigation for users: Home · Wallet · Promote · Profile.
class UserShell extends StatelessWidget {
  const UserShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // Show admin decisions (approved / rejected / bonus) as they arrive.
    if (context.select<SessionViewModel, bool>((s) => s.hasStatusUpdate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final message = context.read<SessionViewModel>().takeStatusUpdate();
        if (message != null) AppSnackbars.info(context, message);
      });
    }
    return _ShellScaffold(
      shell: shell,
      items: const [
        _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppStrings.navHome),
        _NavItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: AppStrings.navWallet,
        ),
        _NavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: AppStrings.navPromote),
        _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: AppStrings.navProfile),
      ],
    );
  }
}

/// Bottom navigation for admins: Dashboard · Users · Subscriptions · Withdrawals · More.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      shell: shell,
      items: const [
        _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: AppStrings.navDashboard),
        _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: AppStrings.navUsers),
        _NavItem(icon: Icons.verified_outlined, activeIcon: Icons.verified_rounded, label: AppStrings.navSubscriptions),
        _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, label: AppStrings.navWithdrawals),
        _NavItem(icon: Icons.more_horiz_rounded, activeIcon: Icons.more_horiz_rounded, label: AppStrings.navMore),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _AppNavBar(
        items: items,
        currentIndex: shell.currentIndex,
        onTap: (i) {
          if (i != shell.currentIndex) HapticFeedback.selectionClick();
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

const _kNavDuration = Duration(milliseconds: 380);

/// Docked bar with a gradient pill that slides to the selected tab.
class _AppNavBar extends StatelessWidget {
  const _AppNavBar({required this.items, required this.currentIndex, required this.onTap});

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final pillHeight = 4.h;
    final topPad = 1.1.h;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.6))),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / items.length;
              final pillWidth = (slot * 0.72).clamp(0.0, 16.w);

              return Stack(
                children: [
                  // Sliding indicator
                  AnimatedPositioned(
                    duration: _kNavDuration,
                    curve: Curves.easeOutBack,
                    top: topPad,
                    left: slot * currentIndex + (slot - pillWidth) / 2,
                    width: pillWidth,
                    height: pillHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF2D2D), AppColors.primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == currentIndex,
                            pillHeight: pillHeight,
                            topPad: topPad,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.pillHeight,
    required this.topPad,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final double pillHeight;
  final double topPad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.caption.copyWith(
      fontSize: 13.5.sp,
      height: 1.2,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? AppColors.primary : AppColors.textSecondary,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(top: topPad, bottom: 1.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: pillHeight,
                child: Center(
                  child: AnimatedScale(
                    duration: _kNavDuration,
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.08 : 1,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        key: ValueKey(selected),
                        size: 6.w,
                        color: selected ? AppColors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: labelStyle,
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(item.label, maxLines: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
