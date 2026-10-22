import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Red brand gradient with soft decorative circles, used behind the splash
/// and the auth headers.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, this.child});

  final Widget? child;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3D3D), AppColors.primary, Color(0xFFB30000)],
    stops: [0, 0.45, 1],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned(top: -w * 0.28, right: -w * 0.22, child: _circle(w * 0.75, 0.08)),
                      Positioned(bottom: -w * 0.35, left: -w * 0.3, child: _circle(w * 0.7, 0.06)),
                      Positioned(top: w * 0.18, left: -w * 0.08, child: _ring(w * 0.22, 0.12)),
                      Positioned(bottom: w * 0.12, right: w * 0.1, child: _ring(w * 0.12, 0.14)),
                      Positioned(top: w * 0.1, right: w * 0.3, child: _circle(w * 0.025, 0.35)),
                      Positioned(bottom: w * 0.3, left: w * 0.22, child: _circle(w * 0.018, 0.3)),
                    ],
                  ),
                );
              },
            ),
          ),
          child ?? const SizedBox.expand(),
        ],
      ),
    );
  }

  Widget _circle(double d, double alpha) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white.withValues(alpha: alpha),
    ),
  );

  Widget _ring(double d, double alpha) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.white.withValues(alpha: alpha), width: 1.5),
    ),
  );
}

/// White rounded tile with the red play mark — the logo on brand backgrounds.
class BrandLogoTile extends StatelessWidget {
  const BrandLogoTile({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (r) => BrandBackdrop.gradient.createShader(r),
        child: Icon(Icons.play_arrow_rounded, size: size * 0.62, color: AppColors.white),
      ),
    );
  }
}
