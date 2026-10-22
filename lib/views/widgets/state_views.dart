import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Friendly empty-list placeholder: animated illustration, headline,
/// supporting message and an optional call to action.
///
/// Use [compact] when the state sits inline inside a scrolling section
/// (e.g. under a section header) rather than filling a whole screen.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      accent: AppColors.primary,
      accentDark: AppColors.primaryDark,
      title: title,
      message: message,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
      compact: compact,
    );
  }
}

/// Error placeholder with a retry button, styled to match [EmptyState].
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry, this.compact = false});

  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: Icons.cloud_off_rounded,
      accent: AppColors.error,
      accentDark: const Color(0xFFB71C1C),
      title: AppStrings.somethingWentWrong,
      message: message ?? AppStrings.errorGeneric,
      actionLabel: onRetry == null ? null : AppStrings.retry,
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Shared layout for [EmptyState] and [ErrorState] with a staggered entrance.
class _StateLayout extends StatefulWidget {
  const _StateLayout({
    required this.icon,
    required this.accent,
    required this.accentDark,
    required this.title,
    required this.compact,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final Color accent;
  final Color accentDark;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  @override
  State<_StateLayout> createState() => _StateLayoutState();
}

class _StateLayoutState extends State<_StateLayout> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  // Drives the idle float of the icon tile and the slow orbit rotation.
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _idle.dispose();
    super.dispose();
  }

  Widget _stagger(double begin, double end, Widget child, {double offset = 14}) {
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
    final hasAction = widget.actionLabel != null && widget.onAction != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink the artwork when the available height is tight so the
        // headline and button always fit.
        var artSize = widget.compact ? 32.w : 46.w;
        if (constraints.hasBoundedHeight) {
          artSize = math.min(artSize, constraints.maxHeight * (hasAction ? 0.42 : 0.5));
        }

        final illustration = AnimatedBuilder(
          animation: _enter,
          builder: (_, c) {
            final t = Curves.easeOutBack.transform(const Interval(0, 0.6).transform(_enter.value));
            return Opacity(
              opacity: const Interval(0, 0.4).transform(_enter.value),
              child: Transform.scale(scale: 0.8 + 0.2 * t, child: c),
            );
          },
          child: _Illustration(
            size: artSize,
            icon: widget.icon,
            accent: widget.accent,
            accentDark: widget.accentDark,
            idle: _idle,
          ),
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: widget.compact ? 2.h : 3.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 80.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  illustration,
                  SizedBox(height: widget.compact ? 1.5.h : 2.5.h),
                  _stagger(
                    0.25,
                    0.75,
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: (widget.compact ? AppTextStyles.subtitle : AppTextStyles.title).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    SizedBox(height: 0.8.h),
                    _stagger(
                      0.35,
                      0.85,
                      Text(
                        widget.message!,
                        textAlign: TextAlign.center,
                        style: (widget.compact ? AppTextStyles.caption : AppTextStyles.bodySecondary).copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  if (hasAction) ...[
                    SizedBox(height: widget.compact ? 2.h : 3.h),
                    _stagger(0.45, 1, _ActionButton(widget: widget)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.widget});

  final _StateLayout widget;

  @override
  Widget build(BuildContext context) {
    final label = Text(widget.actionLabel!);
    final style = ElevatedButton.styleFrom(
      backgroundColor: widget.accent,
      foregroundColor: AppColors.white,
      minimumSize: Size(42.w, 5.6.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      shape: const StadiumBorder(),
      elevation: 0,
      shadowColor: Colors.transparent,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(color: widget.accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: widget.actionIcon == null
          ? ElevatedButton(style: style, onPressed: widget.onAction, child: label)
          : ElevatedButton.icon(
              style: style,
              onPressed: widget.onAction,
              icon: Icon(widget.actionIcon, size: 5.w),
              label: label,
            ),
    );
  }
}

/// Layered artwork: soft glow, rotating dashed orbit with satellites, a
/// tinted disc and a floating gradient tile holding the icon.
class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.size,
    required this.icon,
    required this.accent,
    required this.accentDark,
    required this.idle,
  });

  final double size;
  final IconData icon;
  final Color accent;
  final Color accentDark;
  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    final s = size;
    final orbit = s * 0.86;
    final tile = s * 0.36;

    return SizedBox.square(
      dimension: s,
      child: AnimatedBuilder(
        animation: idle,
        builder: (context, _) {
          final angle = idle.value * 2 * math.pi;
          // Six float cycles per orbit turn keeps both loops seamless.
          final float = math.sin(angle * 6) * s * 0.025;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accent.withValues(alpha: 0.14), accent.withValues(alpha: 0.0)],
                    stops: const [0.35, 1],
                  ),
                ),
              ),

              // Orbit with satellites (counter-rotated so icons stay upright)
              Transform.rotate(
                angle: angle,
                child: SizedBox.square(
                  dimension: orbit,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _DashedRingPainter(color: accent.withValues(alpha: 0.28))),
                      ),
                      _satellite(orbit, -math.pi / 4, angle, _chip(s, Icons.auto_awesome_rounded)),
                      _satellite(orbit, math.pi * 0.8, angle, _dot(s * 0.05, accent)),
                      _satellite(orbit, math.pi * 0.25, angle, _dot(s * 0.035, accent.withValues(alpha: 0.45))),
                    ],
                  ),
                ),
              ),

              // Tinted disc
              Container(
                width: s * 0.62,
                height: s * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0.04)],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.12)),
                ),
              ),

              // Floating icon tile
              Transform.translate(
                offset: Offset(0, float),
                child: Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    width: tile,
                    height: tile,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(tile * 0.3),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(accent, AppColors.white, 0.12)!, accentDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: tile * 0.4,
                          offset: Offset(0, tile * 0.18 - float * 0.5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Glossy highlight
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: tile * 0.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(tile * 0.3)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.white.withValues(alpha: 0.22), AppColors.white.withValues(alpha: 0)],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Transform.rotate(
                            angle: 0.08,
                            child: Icon(icon, size: tile * 0.5, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _satellite(double orbit, double at, double rotation, Widget child) {
    final r = orbit / 2;
    return Positioned(
      left: r + r * math.cos(at),
      top: r + r * math.sin(at),
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(angle: -rotation, child: child),
      ),
    );
  }

  Widget _chip(double s, IconData glyph) {
    final d = s * 0.14;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: d * 0.5, offset: Offset(0, d * 0.12))],
      ),
      child: Icon(glyph, size: d * 0.55, color: accent),
    );
  }

  Widget _dot(double d, Color color) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    const dashes = 36;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.7), i * sweep, sweep * 0.45, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

/// Simple pulsing skeleton block (no shimmer package).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, required this.height, this.width, this.radius});

  final double height;
  final double? width;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.shimmerBase, AppColors.shimmerHighlight, _c.value),
          borderRadius: BorderRadius.circular(widget.radius ?? 2.w),
        ),
      ),
    );
  }
}

/// A vertical list of skeleton cards used while lists load.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5, this.itemHeight});

  final int count;
  final double? itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(4.w),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: 1.5.h),
      itemBuilder: (_, _) => SkeletonBox(height: itemHeight ?? 10.h),
    );
  }
}
