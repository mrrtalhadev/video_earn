import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/withdraw_request.dart';
import '../../../data/repositories/withdraw_repository.dart';
import '../../../viewmodels/admin/admin_withdrawals_view_model.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/copyable_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'review_widgets.dart';

class WithdrawManagementScreen extends StatelessWidget {
  const WithdrawManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminWithdrawalsViewModel(
        repo: ctx.read<WithdrawRepository>(),
        adminUid: ctx.read<SessionViewModel>().uid ?? '',
      ),
      child: const _WithdrawalsView(),
    );
  }
}

class _WithdrawalsView extends StatelessWidget {
  const _WithdrawalsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminWithdrawalsViewModel>();
    return StatusTabsScaffold<WithdrawRequest>(
      title: AppStrings.withdrawManagement,
      showBack: false,
      lists: vm.lists,
      itemBuilder: (_, r) => _RequestCard(request: r),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final WithdrawRequest request;

  void _feedback(BuildContext context, bool ok, String success, String? error) {
    if (!context.mounted) return;
    ok ? AppSnackbars.success(context, success) : AppSnackbars.error(context, error ?? AppStrings.errorGeneric);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminWithdrawalsViewModel>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(request.userName, style: AppTextStyles.subtitle)),
              StatusChip.order(request.status),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(Formatters.pkr(request.amount), style: AppTextStyles.headline.copyWith(color: AppColors.primaryDark)),
          const Divider(),
          CopyableRow(label: AppStrings.accountHolderName, value: request.accountHolderName),
          CopyableRow(label: AppStrings.bankName, value: request.bankName),
          CopyableRow(label: AppStrings.accountNumber, value: request.accountNumber),
          if (request.adminTransferRef != null)
            InfoRow(label: AppStrings.adminTransferRef, value: request.adminTransferRef!),
          ReviewFooter(
            createdAt: request.createdAt,
            reviewedAt: request.reviewedAt,
            rejectionReason: request.rejectionReason,
          ),
          if (request.status == OrderStatus.pending) ...[
            SizedBox(height: 1.5.h),
            ReviewActions(
              busy: vm.isBusy(request.id),
              approveMessage: AppStrings.approveWithdrawConfirm,
              confirmApprove: false,
              onApprove: () async {
                final ref = await ConfirmDialog.input(
                  context,
                  title: AppStrings.approveWithdrawConfirm,
                  label: AppStrings.adminTransferRef,
                  confirmLabel: AppStrings.approve,
                  required: false,
                );
                if (ref == null) return;
                final ok = await vm.approve(request, transferRef: ref);
                if (context.mounted) _feedback(context, ok, AppStrings.approvedSuccess, vm.errorMessage);
              },
              onReject: (reason) async {
                final ok = await vm.reject(request, reason);
                if (context.mounted) _feedback(context, ok, AppStrings.rejectedSuccess, vm.errorMessage);
              },
            ),
          ],
        ],
      ),
    );
  }
}
