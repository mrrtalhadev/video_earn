import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/promote_order.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../data/repositories/proof_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../viewmodels/admin/admin_promote_orders_view_model.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/copyable_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/video_verify_panel.dart';
import 'review_widgets.dart';

class PromoteOrdersManagementScreen extends StatelessWidget {
  const PromoteOrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminPromoteOrdersViewModel(
        promoteRepo: ctx.read<PromoteRepository>(),
        subscriptionRepo: ctx.read<SubscriptionRepository>(),
        proofRepo: ctx.read<ProofRepository>(),
        adminUid: ctx.read<SessionViewModel>().uid ?? '',
      ),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AdminPromoteOrdersViewModel>();
          return StatusTabsScaffold<PromoteOrder>(
            title: AppStrings.promoteOrdersManagement,
            lists: vm.lists,
            itemBuilder: (_, o) => _PromoteOrderCard(order: o),
          );
        },
      ),
    );
  }
}

class _PromoteOrderCard extends StatelessWidget {
  const _PromoteOrderCard({required this.order});

  final PromoteOrder order;

  void _feedback(BuildContext context, bool ok, String success, String? error) {
    ok ? AppSnackbars.success(context, success) : AppSnackbars.error(context, error ?? AppStrings.errorGeneric);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminPromoteOrdersViewModel>();
    final maxMinutes = context.select<SessionViewModel, int>((s) => s.settingsOrDefault.maxVideoMinutes);
    final pending = order.status == OrderStatus.pending;
    final verified = vm.verifiedFor(order.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(order.videoTitle, style: AppTextStyles.subtitle)),
              SizedBox(width: 2.w),
              StatusChip.order(order.status),
            ],
          ),
          Text(order.userName, style: AppTextStyles.caption),
          if (order.videoDescription.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(order.videoDescription, style: AppTextStyles.caption, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const Divider(),
          CopyableRow(label: AppStrings.youtubeLink, value: order.videoUrl),
          InfoRow(
            label: AppStrings.packageName,
            value: '${order.packageName} · ${AppStrings.packageDays(order.durationDays)}',
          ),
          InfoRow(
            label: AppStrings.amount,
            value: Formatters.pkr(order.price),
            valueStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
          ),
          InfoRow(label: AppStrings.transactionId, value: order.transactionId),
          DuplicateTxnBadge(transactionId: order.transactionId, vm: vm),
          ReviewFooter(
            createdAt: order.createdAt,
            reviewedAt: order.reviewedAt,
            rejectionReason: order.rejectionReason,
          ),
          if (order.startAt != null && order.expiresAt != null)
            InfoRow(
              label: AppStrings.statusActive,
              value: AppStrings.promoteRunPeriod(
                Formatters.dateTime(order.startAt),
                Formatters.dateTime(order.expiresAt),
              ),
            ),
          SizedBox(height: 1.h),
          ProofButton(proofId: order.proofId, vm: vm),
          if (pending) ...[
            SizedBox(height: 1.5.h),
            Text(AppStrings.approvePromoteHint, style: AppTextStyles.caption),
            SizedBox(height: 1.h),
            VideoVerifyPanel(
              videoId: order.youtubeVideoId,
              maxMinutes: maxMinutes,
              onResult: (r) => vm.setVerified(order.id, r),
            ),
            SizedBox(height: 1.5.h),
            ReviewActions(
              busy: vm.isBusy(order.id),
              approveEnabled: verified != null,
              approveMessage: AppStrings.approvePromoteHint,
              onApprove: () async {
                final ok = await vm.approve(order);
                if (context.mounted) _feedback(context, ok, AppStrings.approvedSuccess, vm.errorMessage);
              },
              onReject: (reason) async {
                final ok = await vm.reject(order, reason);
                if (context.mounted) _feedback(context, ok, AppStrings.rejectedSuccess, vm.errorMessage);
              },
            ),
          ],
        ],
      ),
    );
  }
}
