import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// App bar with an optional YouTube-style play-icon logo and a bottom divider.
class AppBarX extends StatelessWidget implements PreferredSizeWidget {
  const AppBarX({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = false,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 1));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: showLogo ? 4.w : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[const AppLogoMark(), SizedBox(width: 2.w)],
          Flexible(
            child: Text(title, style: AppTextStyles.title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: actions,
      bottom:
          bottom ??
          const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.divider),
          ),
    );
  }
}

/// Red rounded rectangle with a white play triangle.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final w = size ?? 9.w;
    return Container(
      width: w,
      height: w * 0.72,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(w * 0.22)),
      child: Icon(Icons.play_arrow_rounded, color: AppColors.white, size: w * 0.6),
    );
  }
}
