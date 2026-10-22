import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/subscription_order.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../data/repositories/proof_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../viewmodels/admin/admin_subscriptions_view_model.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'review_widgets.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminSubscriptionsViewModel(
        subscriptionRepo: ctx.read<SubscriptionRepository>(),
        promoteRepo: ctx.read<PromoteRepository>(),
        proofRepo: ctx.read<ProofRepository>(),
        adminUid: ctx.read<SessionViewModel>().uid ?? '',
      ),
      child: const _SubscriptionsView(),
    );
  }
}

class _SubscriptionsView extends StatelessWidget {
  const _SubscriptionsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSubscriptionsViewModel>();
    return StatusTabsScaffold<SubscriptionOrder>(
      title: AppStrings.subscriptionManagement,
      showBack: false,
      lists: vm.lists,
      itemBuilder: (ctx, order) => _OrderCard(order: order),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final SubscriptionOrder order;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSubscriptionsViewModel>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName, style: AppTextStyles.subtitle),
                    Text(order.userEmail, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip.order(order.status),
            ],
          ),
          SizedBox(height: 1.h),
          InfoRow(label: AppStrings.amount, value: Formatters.pkr(order.amount)),
          InfoRow(label: AppStrings.transactionId, value: order.transactionId),
          DuplicateTxnBadge(transactionId: order.transactionId, vm: vm),
          ReviewFooter(
            createdAt: order.createdAt,
            reviewedAt: order.reviewedAt,
            rejectionReason: order.rejectionReason,
          ),
          SizedBox(height: 1.h),
          ProofButton(proofId: order.proofId, vm: vm),
          if (order.status == OrderStatus.pending) ...[
            SizedBox(height: 1.5.h),
            ReviewActions(
              busy: vm.isBusy(order.id),
              approveMessage: AppStrings.approveSubscriptionConfirm,
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

void _feedback(BuildContext context, bool ok, String success, String? error) {
  ok ? AppSnackbars.success(context, success) : AppSnackbars.error(context, error ?? AppStrings.errorGeneric);
}
