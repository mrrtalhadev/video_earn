import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/link_utils.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/user/profile_view_model.dart';
import '../../widgets/state_views.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SHARED COMPACT HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(5.w, top + 1.5.h, 5.w, 3.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.black, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
            title,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CONTENT SCREEN — About Us / Terms
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
enum ContentKind { about, terms }

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    final settings = context.select<SessionViewModel, AppSettings?>((s) => s.settings);
    final title = kind == ContentKind.about ? AppStrings.aboutUs : AppStrings.terms;
    final text = kind == ContentKind.about ? settings?.aboutUs : settings?.termsAndConditions;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: (text == null || text.trim().isEmpty)
            ? Column(
                children: [
                  _CompactHeader(title: title),
                  const Expanded(
                    child: EmptyState(
                      title: AppStrings.noContent,
                      message: AppStrings.noContentMessage,
                      icon: Icons.article_rounded,
                    ),
                  ),
                ],
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _CompactHeader(title: title),
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 3.h),
                    child: Container(
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
                      child: SelectableText(text, style: AppTextStyles.body.copyWith(height: 1.5)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FAQ SCREEN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FaqViewModel(ctx.read<SettingsRepository>()),
      child: Builder(
        builder: (context) {
          final vm = context.watch<FaqViewModel>();

          Widget body;
          if (!vm.loaded && !vm.hasError) {
            body = Padding(padding: EdgeInsets.all(4.w), child: const SkeletonList());
          } else if (vm.hasError && vm.faqs.isEmpty) {
            body = ErrorState(message: vm.errorMessage, onRetry: vm.load);
          } else if (vm.faqs.isEmpty) {
            body = const EmptyState(
              title: AppStrings.noFaqs,
              message: AppStrings.noFaqsMessage,
              icon: Icons.quiz_rounded,
            );
          } else {
            body = RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.load,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 3.h),
                itemCount: vm.faqs.length,
                separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
                itemBuilder: (_, i) => Container(
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
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: AppColors.primary,
                      tilePadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                      childrenPadding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      leading: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(2.5.w),
                        ),
                        child: Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 5.w),
                      ),
                      title: Text(
                        vm.faqs[i].question,
                        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      children: [Text(vm.faqs[i].answer, style: AppTextStyles.bodySecondary)],
                    ),
                  ),
                ),
              ),
            );
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: const Color(0xFFF2F2F7),
              body: Column(
                children: [
                  _CompactHeader(title: AppStrings.faq),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CONTACT US SCREEN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.select<SessionViewModel, AppSettings?>((s) => s.settings);
    final c = s?.contactUs ?? const ContactInfo();
    final whatsapp = c.whatsapp.isNotEmpty ? c.whatsapp : (s?.supportWhatsapp ?? '');
    final email = c.email.isNotEmpty ? c.email : (s?.supportEmail ?? '');

    Future<void> open(Future<bool> Function() action) async {
      final ok = await action();
      if (!ok && context.mounted) AppSnackbars.error(context, AppStrings.cannotOpenLink);
    }

    final items = [
      if (whatsapp.isNotEmpty)
        (Icons.chat_rounded, AppStrings.contactWhatsapp, whatsapp, () => open(() => LinkUtils.whatsapp(whatsapp))),
      if (email.isNotEmpty)
        (Icons.email_rounded, AppStrings.contactEmail, email, () => open(() => LinkUtils.email(email))),
      if (c.phone.isNotEmpty)
        (Icons.phone_rounded, AppStrings.contactPhone, c.phone, () => open(() => LinkUtils.phone(c.phone))),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: items.isEmpty && c.address.isEmpty
            ? Column(
                children: [
                  _CompactHeader(title: AppStrings.contactUs),
                  const Expanded(
                    child: EmptyState(
                      title: AppStrings.noContent,
                      message: AppStrings.noContentMessage,
                      icon: Icons.support_agent_rounded,
                    ),
                  ),
                ],
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _CompactHeader(title: AppStrings.contactUs),
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 3.h),
                    child: Column(
                      children: [
                        for (final (icon, label, value, onTap) in items)
                          Padding(
                            padding: EdgeInsets.only(bottom: 1.2.h),
                            child: GestureDetector(
                              onTap: onTap,
                              child: Container(
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
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2.5.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(2.5.w),
                                      ),
                                      child: Icon(icon, color: AppColors.primary, size: 5.w),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          SizedBox(height: 0.2.h),
                                          Text(
                                            value,
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.open_in_new_rounded, color: Colors.grey.shade400, size: 5.w),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (c.address.isNotEmpty)
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2.5.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(2.5.w),
                                  ),
                                  child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 5.w),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.address,
                                        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      SizedBox(height: 0.2.h),
                                      Text(
                                        c.address,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
