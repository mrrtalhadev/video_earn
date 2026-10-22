import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/promote_order.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/my_promote_orders_view_model.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/status_chip.dart';

class MyPromoteOrdersScreen extends StatelessWidget {
  const MyPromoteOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => MyPromoteOrdersViewModel(ctx.read<PromoteRepository>(), ctx.read<SessionViewModel>().uid!),
      child: Builder(
        builder: (context) {
          final vm = context.watch<MyPromoteOrdersViewModel>();
          final top = MediaQuery.of(context).padding.top;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: const Color(0xFFF2F2F7),
              body: Column(
                children: [
                  // ── header ──
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 3.h),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.black, AppColors.primaryDark],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: EdgeInsets.all(2.2.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2.8.w),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 4.5.w),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          AppStrings.myPromoteOrders,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── list ──
                  Expanded(
                    child: PagedListView<PromoteOrder>(
                      list: vm.orders,
                      emptyTitle: AppStrings.noPromoteOrders,
                      emptyMessage: AppStrings.noPromoteOrdersMessage,
                      emptyIcon: Icons.campaign_rounded,
                      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
                      itemBuilder: (_, o) => _PromoteOrderCard(order: o),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoteOrderCard extends StatelessWidget {
  const _PromoteOrderCard({required this.order});

  final PromoteOrder order;

  @override
  Widget build(BuildContext context) {
    final live =
        order.status == OrderStatus.approved && order.expiresAt != null && order.expiresAt!.isAfter(DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // video icon
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.5.w),
                ),
                child: Icon(Icons.play_circle_rounded, color: AppColors.primary, size: 5.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.videoTitle,
                      style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      '${order.packageName} · ${AppStrings.packageDays(order.durationDays)}',
                      style: AppTextStyles.caption.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              StatusChip.order(order.status),
            ],
          ),

          SizedBox(height: 1.5.h),

          // info row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(3.w)),
            child: Row(
              children: [
                _DetailItem(icon: Icons.payments_rounded, value: Formatters.pkr(order.price)),
                Container(width: 1, height: 3.h, color: Colors.grey.shade200),
                _DetailItem(icon: Icons.receipt_long_rounded, value: order.transactionId),
                Container(width: 1, height: 3.h, color: Colors.grey.shade200),
                _DetailItem(icon: Icons.calendar_today_rounded, value: Formatters.dateTime(order.createdAt)),
              ],
            ),
          ),

          if (order.startAt != null && order.expiresAt != null) ...[
            SizedBox(height: 1.2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: live ? AppColors.success.withValues(alpha: 0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(2.5.w),
              ),
              child: Row(
                children: [
                  Icon(
                    live ? Icons.play_circle_fill_rounded : Icons.history_rounded,
                    size: 4.w,
                    color: live ? AppColors.success : Colors.grey.shade500,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      AppStrings.promoteRunPeriod(
                        Formatters.dateTime(order.startAt),
                        Formatters.dateTime(order.expiresAt),
                      ),
                      style: TextStyle(
                        color: live ? AppColors.success : Colors.grey.shade600,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.status == OrderStatus.rejected && order.rejectionReason != null) ...[
            SizedBox(height: 1.2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2.5.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 4.w, color: AppColors.error),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      AppStrings.rejectionReason(order.rejectionReason!),
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 3.5.w, color: Colors.grey.shade400),
          SizedBox(width: 1.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
