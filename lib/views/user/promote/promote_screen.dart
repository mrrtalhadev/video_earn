import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/promote_package.dart';
import '../../../data/repositories/promote_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/connectivity_view_model.dart';
import '../../../viewmodels/user/promote_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bank_details_card.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/success_dialog.dart';

class PromoteScreen extends StatelessWidget {
  const PromoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PromoteViewModel(repo: ctx.read<PromoteRepository>(), uid: ctx.read<SessionViewModel>().uid!),
      child: const _PromoteView(),
    );
  }
}

class _PromoteView extends StatefulWidget {
  const _PromoteView();

  @override
  State<_PromoteView> createState() => _PromoteViewState();
}

class _PromoteViewState extends State<_PromoteView> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _txn = TextEditingController();

  @override
  void dispose() {
    for (final c in [_url, _title, _desc, _txn]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<PromoteViewModel>();
    final valid = _formKey.currentState?.validate() ?? false;
    final ok =
        valid &&
        await vm.submit(videoUrl: _url.text, title: _title.text, description: _desc.text, transactionId: _txn.text);
    if (!mounted) return;
    if (ok) {
      _formKey.currentState?.reset();
      for (final c in [_url, _title, _desc, _txn]) {
        c.clear();
      }
      await SuccessDialog.show(
        context,
        title: AppStrings.promoteSubmittedTitle,
        message: AppStrings.promoteSubmittedMessage,
      );
    } else if (valid && vm.hasError) {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PromoteViewModel>();
    final settings = context.select<SessionViewModel, AppSettings?>((s) => s.settings);
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);
    final bankOk = settings?.bank.isConfigured ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: vm.loadPackages,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _PromoteHeader(),
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 5.h, 4.w, 3.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.5.h),

                      // ── intro + orders button ──
                      Text(AppStrings.promoteIntro, style: AppTextStyles.caption),
                      SizedBox(height: 1.5.h),
                      SizedBox(height: 1.5.h),

                      GestureDetector(
                        onTap: () => context.push(Routes.myPromoteOrders),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(3.w),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 5.w),
                              SizedBox(width: 2.w),
                              Text(
                                AppStrings.myPromoteOrders,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // ── packages ──
                      const SectionHeader(title: AppStrings.choosePackage),
                      ..._packages(vm),
                      if (vm.packageError != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: Text(vm.packageError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                        ),

                      SizedBox(height: 1.5.h),

                      // ── video details card ──
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Video Details',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                            ),
                            SizedBox(height: 2.h),
                            AppTextField(
                              controller: _url,
                              label: AppStrings.youtubeLink,
                              prefixIcon: Icons.link_rounded,
                              keyboardType: TextInputType.url,
                              validator: Validators.youtubeUrl,
                            ),
                            AppTextField(
                              controller: _title,
                              label: AppStrings.videoTitle,
                              validator: Validators.title,
                              maxLength: 100,
                            ),
                            AppTextField(
                              controller: _desc,
                              label: '${AppStrings.videoDescription} ${AppStrings.optional}',
                              maxLines: 3,
                              maxLength: 500,
                              validator: Validators.description,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // ── payment section ──
                      const SectionHeader(title: AppStrings.bankDetails),
                      if (settings != null) BankDetailsCard(bank: settings.bank),
                      SizedBox(height: 2.h),

                      // amount display
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.08),
                              AppColors.primaryDark.withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4.w),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.5.w),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                borderRadius: BorderRadius.circular(2.5.w),
                              ),
                              child: Icon(Icons.payments_rounded, color: AppColors.white, size: 5.w),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(child: Text(AppStrings.amount, style: AppTextStyles.subtitle)),
                            Text(
                              vm.selected == null ? '—' : Formatters.pkr(vm.selected!.price),
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // payment proof card
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Proof',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                            ),
                            SizedBox(height: 2.h),
                            AppTextField(
                              controller: _txn,
                              label: AppStrings.transactionId,
                              prefixIcon: Icons.receipt_long_rounded,
                              validator: Validators.transactionId,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(40),
                              ],
                            ),
                            ImagePickerField(
                              label: AppStrings.paymentScreenshot,
                              bytes: vm.proofBytes,
                              isProcessing: vm.compressing,
                              errorText: vm.proofError,
                              onPick: vm.pickProof,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),

                      if (!online)
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.5.h),
                          child: NoticeBanner.warning(AppStrings.errorOffline),
                        ),

                      // ── submit button ──
                      GestureDetector(
                        onTap: online && bankOk && !vm.compressing && !vm.isLoading ? _submit : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: online && bankOk && !vm.compressing ? 1.0 : 0.5,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 1.8.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(3.w),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: vm.isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 5.w,
                                      height: 5.w,
                                      child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.rocket_launch_rounded, color: AppColors.white, size: 5.w),
                                      SizedBox(width: 2.w),
                                      Text(
                                        AppStrings.submitPromote,
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _packages(PromoteViewModel vm) {
    if (vm.packagesLoading && vm.packages.isEmpty) return [const SkeletonList(count: 2)];
    if (vm.packagesError != null && vm.packages.isEmpty) {
      return [ErrorState(message: vm.packagesError, onRetry: vm.loadPackages)];
    }
    if (vm.packages.isEmpty) return [NoticeBanner.info(AppStrings.noPackages)];
    return vm.packages.map((p) => _PackageOption(package: p, selected: vm.selected?.id == p.id)).toList();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PROMOTE HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PromoteHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 10.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.black, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // app bar
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.2.w),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2.8.w)),
                        child: Icon(Icons.play_arrow_rounded, color: AppColors.white, size: 5.w),
                      ),
                      SizedBox(width: 2.5.w),
                      Text(
                        AppStrings.promoteTitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  // hero text
                  Column(
                    children: [
                      Text(
                        'Boost Your Videos',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24.sp,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      Text(
                        'Get more views and grow your channel!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ],
          ),
        ),

        // floating stat card
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: -4.5.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -3.w,
                  top: -2.h,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Row(
                  children: [
                    _HeaderChip(icon: Icons.visibility_rounded, label: 'Reach', value: 'Real Views'),
                    _VertDivider(),
                    _HeaderChip(icon: Icons.trending_up_rounded, label: 'Growth', value: 'Organic'),
                    _VertDivider(),
                    _HeaderChip(icon: Icons.verified_rounded, label: 'Quality', value: 'Guaranteed'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.75), size: 4.5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15.5.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.2.h),
          Text(
            label,
            style: TextStyle(color: AppColors.white, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 5.h, color: AppColors.white.withValues(alpha: 0.12));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PACKAGE OPTION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PackageOption extends StatelessWidget {
  const _PackageOption({required this.package, required this.selected});

  final PromotePackage package;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: GestureDetector(
        onTap: () => context.read<PromoteViewModel>().select(package),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(3.5.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : AppColors.white,
            borderRadius: BorderRadius.circular(4.w),
            border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200, width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : Colors.grey.shade400,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(height: 0.2.h),
                    Text(AppStrings.packageDays(package.durationDays), style: AppTextStyles.caption),
                    if (package.description != null) Text(package.description!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  gradient: selected ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]) : null,
                  color: selected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(2.5.w),
                ),
                child: Text(
                  Formatters.pkr(package.price),
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
