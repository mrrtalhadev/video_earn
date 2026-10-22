import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_status.dart';
import '../../../viewmodels/admin/review_support.dart';
import '../../../viewmodels/paged_list.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/zoomable_image_viewer.dart';

/// Pending / Approved / Rejected tabs, each a lazily loaded [PagedList].
class StatusTabsScaffold<T> extends StatelessWidget {
  const StatusTabsScaffold({
    super.key,
    required this.title,
    required this.lists,
    required this.itemBuilder,
    this.showBack = true,
  });

  final String title;
  final Map<OrderStatus, PagedList<T>> lists;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBarX(
          title: title,
          automaticallyImplyLeading: showBack,
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.tabPending),
              Tab(text: AppStrings.tabApproved),
              Tab(text: AppStrings.tabRejected),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: OrderStatus.values
                .map((s) => _StatusTab<T>(list: lists[s]!, itemBuilder: itemBuilder, status: s))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusTab<T> extends StatefulWidget {
  const _StatusTab({required this.list, required this.itemBuilder, required this.status});

  final PagedList<T> list;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final OrderStatus status;

  @override
  State<_StatusTab<T>> createState() => _StatusTabState<T>();
}

class _StatusTabState<T> extends State<_StatusTab<T>> {
  @override
  Widget build(BuildContext context) {
    // Lists are invalidated after a review moves items between tabs; reload
    // lazily when the tab is shown (after the frame, never during build).
    if (!widget.list.loaded && !widget.list.isLoading && widget.list.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.list.ensureLoaded());
    }
    return PagedListView<T>(
      list: widget.list,
      itemBuilder: widget.itemBuilder,
      emptyTitle: widget.status == OrderStatus.pending ? AppStrings.noPendingItems : AppStrings.noItems,
      emptyMessage: widget.status == OrderStatus.pending ? AppStrings.noPendingItemsMessage : AppStrings.noItemsMessage,
      emptyIcon: Icons.task_alt_rounded,
    );
  }
}

/// "View screenshot" — loads the proof on demand (1 read) then opens a zoom view.
class ProofButton extends StatelessWidget {
  const ProofButton({super.key, required this.proofId, required this.vm});

  final String proofId;
  final ReviewSupport vm;

  @override
  Widget build(BuildContext context) {
    final loading = vm.isProofLoading(proofId);
    final loaded = vm.proofLoaded(proofId);
    final bytes = vm.proof(proofId);

    if (loaded && bytes == null) {
      return Text(AppStrings.screenshotUnavailable, style: AppTextStyles.caption);
    }
    if (loaded && bytes != null) {
      return GestureDetector(
        onTap: () => ZoomableImageViewer.open(context, bytes),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.w),
          child: Image.memory(bytes, height: 22.h, width: double.infinity, fit: BoxFit.cover),
        ),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(5.h)),
      onPressed: loading ? null : () => vm.loadProof(proofId),
      icon: loading
          ? SizedBox(width: 4.w, height: 4.w, child: const CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.image_outlined),
      label: const Text(AppStrings.viewScreenshot),
    );
  }
}

/// Red warning when another order uses the same transaction ID.
class DuplicateTxnBadge extends StatelessWidget {
  const DuplicateTxnBadge({super.key, required this.transactionId, required this.vm});

  final String transactionId;
  final ReviewSupport vm;

  @override
  Widget build(BuildContext context) {
    final n = vm.duplicates(transactionId);
    if (n == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.loadDuplicates(transactionId));
      return const SizedBox.shrink();
    }
    if (n == 0) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(2.w)),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              '${AppStrings.duplicateTxnWarning}: ${AppStrings.duplicateTxnDetail(n)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Approve / Reject buttons with confirmation and reason prompt.
class ReviewActions extends StatelessWidget {
  const ReviewActions({
    super.key,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.approveMessage,
    this.approveEnabled = true,
    this.confirmApprove = true,
  });

  final bool busy;
  final Future<void> Function() onApprove;
  final Future<void> Function(String reason) onReject;
  final String approveMessage;
  final bool approveEnabled;

  /// When false, [onApprove] handles its own confirmation (e.g. a prompt).
  final bool confirmApprove;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: Size.fromHeight(5.h),
            ),
            onPressed: () async {
              final reason = await ConfirmDialog.input(
                context,
                title: AppStrings.reject,
                label: AppStrings.rejectReasonLabel,
                confirmLabel: AppStrings.reject,
                destructive: true,
              );
              if (reason != null && reason.isNotEmpty) await onReject(reason);
            },
            child: const Text(AppStrings.reject),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: Size.fromHeight(5.h)),
            onPressed: !approveEnabled
                ? null
                : () async {
                    if (!confirmApprove) return onApprove();
                    final ok = await ConfirmDialog.show(
                      context,
                      title: AppStrings.approveConfirmTitle,
                      message: approveMessage,
                      confirmLabel: AppStrings.approve,
                    );
                    if (ok) await onApprove();
                  },
            child: const Text(AppStrings.approve),
          ),
        ),
      ],
    );
  }
}

/// Footer showing submitted/reviewed dates and rejection reason.
class ReviewFooter extends StatelessWidget {
  const ReviewFooter({super.key, required this.createdAt, this.reviewedAt, this.rejectionReason});

  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(label: AppStrings.submitted, value: Formatters.dateTime(createdAt)),
        if (reviewedAt != null) InfoRow(label: AppStrings.reviewed, value: Formatters.dateTime(reviewedAt)),
        if (rejectionReason != null)
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              AppStrings.rejectionReason(rejectionReason!),
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
