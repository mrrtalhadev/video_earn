import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Animated success dialog: a circle draws itself, then a check mark.
class SuccessDialog extends StatefulWidget {
  const SuccessDialog({super.key, required this.title, required this.message});

  final String title;
  final String message;

  static Future<void> show(BuildContext context, {required String title, required String message}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: AppColors.scrim,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => SuccessDialog(title: title, message: message),
      transitionBuilder: (_, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _circle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _pop = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 25),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 24.w;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 82.w,
          padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 2.5.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(5.w),
            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => Transform.scale(
                  scale: _pop.value,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _CheckPainter(circle: _circle.value, check: _check.value),
                  ),
                ),
              ),
              SizedBox(height: 2.5.h),
              Text(widget.title, style: AppTextStyles.headline, textAlign: TextAlign.center),
              SizedBox(height: 1.h),
              Text(widget.message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.done)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.circle, required this.check});

  final double circle;
  final double check;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final stroke = size.width * 0.075;

    canvas.drawCircle(center, radius * circle, Paint()..color = AppColors.success.withValues(alpha: 0.12 * circle));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      -math.pi / 2,
      2 * math.pi * circle,
      false,
      Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (check <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * check),
      Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.circle != circle || old.check != check;
}
