import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../viewmodels/paged_list.dart';
import 'state_views.dart';

/// Renders a [PagedList]: skeleton while loading, error with retry, empty
/// state, pull-to-refresh and infinite scroll.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.list,
    required this.itemBuilder,
    required this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_rounded,
    this.padding,
    this.header,
  });

  final PagedList<T> list;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final EdgeInsetsGeometry? padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (list.isLoading && list.items.isEmpty) return const SkeletonList();
    if (list.error != null && list.items.isEmpty) {
      return ErrorState(message: list.error, onRetry: list.refresh);
    }

    final count = list.items.length;
    return RefreshIndicator(
      onRefresh: list.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) list.loadMore();
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? EdgeInsets.all(4.w),
          itemCount: count + 2,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 1.5.h),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                children: [
                  ?header,
                  if (count == 0)
                    SizedBox(
                      height: 55.h,
                      child: EmptyState(title: emptyTitle, message: emptyMessage, icon: emptyIcon),
                    ),
                ],
              );
            }
            if (i == count + 1) return _Footer(list: list);
            return itemBuilder(context, list.items[i - 1]);
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.list});

  final PagedList<dynamic> list;

  @override
  Widget build(BuildContext context) {
    if (list.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (list.error != null && list.items.isNotEmpty) {
      return TextButton(onPressed: list.loadMore, child: const Text(AppStrings.retry));
    }
    if (list.hasMore && list.items.isNotEmpty) {
      return TextButton(onPressed: list.loadMore, child: const Text(AppStrings.loadMore));
    }
    return SizedBox(height: 2.h);
  }
}
