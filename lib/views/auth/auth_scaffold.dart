import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/brand_backdrop.dart';

/// Shared layout for login / signup / reset: gradient hero header with the
/// title, and the form on a white sheet that overlaps it.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))
    ..forward();

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Widget _reveal(double begin, double end, Widget child, {double offset = 18}) {
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, (1 - anim.value) * offset), child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlap = 5.h;
    final onBrand = AppColors.white.withValues(alpha: 0.86);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrandBackdrop(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, widget.showBack ? 0.5.h : 3.h, 6.w, 4.h + overlap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showBack)
                          Padding(
                            padding: EdgeInsets.only(bottom: 1.5.h),
                            child: Transform.translate(
                              offset: Offset(-3.w, 0),
                              child: const BackButton(color: AppColors.white),
                            ),
                          ),
                        _reveal(
                          0,
                          0.5,
                          Row(
                            children: [
                              BrandLogoTile(size: 11.w),
                              SizedBox(width: 3.w),
                              Text(
                                AppStrings.appName,
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: widget.showBack ? 3.h : 4.5.h),
                        _reveal(
                          0.15,
                          0.65,
                          Text(
                            widget.title,
                            style: AppTextStyles.display.copyWith(
                              color: AppColors.white,
                              fontSize: 24.sp,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        _reveal(
                          0.25,
                          0.75,
                          Text(widget.subtitle, style: AppTextStyles.body.copyWith(color: onBrand, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Form sheet
              _reveal(
                0.3,
                1,
                offset: 40,
                Container(
                  transform: Matrix4.translationValues(0, -overlap, 0),
                  padding: EdgeInsets.fromLTRB(6.w, 1.4.h, 6.w, 2.h + MediaQuery.paddingOf(context).bottom),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 10.w,
                          height: 0.5.h,
                          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label that groups related form fields.
class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.4.h, top: 0.4.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(1.2.w),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2.w)),
              child: Icon(icon, size: 4.w, color: AppColors.primary),
            ),
            SizedBox(width: 2.5.w),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 3.w),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// Centered "text — divider — text" separator, e.g. above a secondary action.
class AuthDivider extends StatelessWidget {
  const AuthDivider(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Text(text, style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
