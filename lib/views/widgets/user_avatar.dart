import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Photo from URL, falling back to the name's initial.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photoUrl, required this.radius});

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
      style: AppTextStyles.headline.copyWith(color: AppColors.primary),
    );
    if (photoUrl == null) {
      return CircleAvatar(radius: radius, backgroundColor: AppColors.primaryLight, child: initial);
    }
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      imageBuilder: (_, provider) => CircleAvatar(radius: radius, backgroundImage: provider),
      placeholder: (_, _) => CircleAvatar(radius: radius, backgroundColor: AppColors.shimmerBase),
      errorWidget: (_, _, _) => CircleAvatar(radius: radius, backgroundColor: AppColors.primaryLight, child: initial),
    );
  }
}
