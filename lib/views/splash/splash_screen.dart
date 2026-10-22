import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../viewmodels/auth/session_view_model.dart';
import '../widgets/brand_backdrop.dart';

/// In-app splash (first route). Shows for at least 2 seconds, then the router
/// redirects based on the session (auth, role, maintenance, blocked).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  // Drives the logo ripples and the loading dots.
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(AppConstants.splashMinDuration, () {
      if (mounted) context.read<SessionViewModel>().markSplashDone();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _enter,
    curve: Interval(begin, end, curve: curve),
  );

  Widget _reveal(double begin, double end, Widget child) {
    final anim = _interval(begin, end);
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, (1 - anim.value) * 16), child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    final logo = 26.w;
    final logoScale = _interval(0, 0.55, Curves.elasticOut);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: BrandBackdrop(
          child: SafeArea(
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo with ripples
                  SizedBox.square(
                    dimension: logo * 2.1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, _) => Stack(
                            alignment: Alignment.center,
                            children: [
                              for (final phase in const [0.0, 0.5]) _ripple(logo, (_pulse.value + phase) % 1),
                            ],
                          ),
                        ),
                        ScaleTransition(
                          scale: logoScale,
                          child: BrandLogoTile(size: logo),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.h),

                  _reveal(
                    0.3,
                    0.7,
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.white,
                        fontSize: 26.sp,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  _reveal(
                    0.4,
                    0.8,
                    Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.88)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  _reveal(
                    0.5,
                    0.95,
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeatureChip(icon: Icons.play_circle_fill_rounded, label: AppStrings.splashWatch),
                        _FeatureChip(icon: Icons.monetization_on_rounded, label: AppStrings.splashEarn),
                        _FeatureChip(icon: Icons.account_balance_rounded, label: AppStrings.splashWithdraw),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  if (session.loadError != null)
                    _SplashError(session: session)
                  else
                    _reveal(0.6, 1, _LoadingDots(animation: _pulse)),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ripple(double logo, double p) {
    final size = logo * (1 + 1.1 * Curves.easeOut.transform(p));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: AppColors.white.withValues(alpha: 0.12 * (1 - p)),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3 * (1 - p)), width: 1.2),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.2.w, color: AppColors.white),
          SizedBox(width: 1.5.w),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.white)),
        ],
      ),
    );
  }
}

/// Three white dots bouncing in sequence.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final d = 2.2.w;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                // Two bounces per pulse cycle, staggered per dot.
                final t = (animation.value * 2 - i * 0.15) % 1;
                final lift = math.max(0.0, math.sin(t * 2 * math.pi));
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  width: d,
                  height: d,
                  transform: Matrix4.translationValues(0, -lift * d * 0.9, 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.55 + 0.45 * lift),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.session});

  final SessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4.w),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.white, size: 8.w),
            SizedBox(height: 1.h),
            Text(
              session.loadError!,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                minimumSize: Size(44.w, 5.5.h),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.button,
              ),
              onPressed: session.retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.retry),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
              onPressed: session.signOut,
              child: const Text(AppStrings.signOut),
            ),
          ],
        ),
      ),
    );
  }
}
