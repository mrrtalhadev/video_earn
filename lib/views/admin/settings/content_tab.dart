import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/faq_item.dart';
import '../../../viewmodels/admin/admin_settings_view_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/number_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import 'app_settings_screen.dart';

class ContentTab extends StatefulWidget {
  const ContentTab({super.key});

  @override
  State<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<ContentTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late final _about = TextEditingController(text: context.read<AdminSettingsViewModel>().settings!.aboutUs);
  late final _terms = TextEditingController(text: context.read<AdminSettingsViewModel>().settings!.termsAndConditions);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminSettingsViewModel>().loadFaqs();
    });
  }

  @override
  void dispose() {
    _about.dispose();
    _terms.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final next = vm.settings!.copyWith(aboutUs: _about.text.trim(), termsAndConditions: _terms.text.trim());
    await saveSettingsWithFeedback(context, () => vm.save(next));
  }

  String? _content(String? v) => Validators.maxLength(v, AppConstants.maxContentLength, isRequired: false);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = context.watch<AdminSettingsViewModel>();
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          AppTextField(controller: _about, label: AppStrings.aboutUs, maxLines: 6, validator: _content),
          AppTextField(controller: _terms, label: AppStrings.terms, maxLines: 8, validator: _content),
          PrimaryButton(label: AppStrings.save, isLoading: vm.isLoading, onPressed: _save),
          SectionHeader(
            title: AppStrings.faqManage,
            actionLabel: AppStrings.addFaq,
            onAction: () => _editFaq(context, null),
          ),
          if (vm.faqsLoading && vm.faqs.isEmpty)
            const SkeletonList(count: 3)
          else if (vm.faqsError != null && vm.faqs.isEmpty)
            ErrorState(message: vm.faqsError, onRetry: () => vm.loadFaqs(force: true), compact: true)
          else if (vm.faqs.isEmpty)
            const EmptyState(
              title: AppStrings.noFaqs,
              message: AppStrings.noFaqsAdminMessage,
              icon: Icons.quiz_rounded,
              compact: true,
            )
          else
            ...vm.faqs.map((f) => _FaqTile(faq: f)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: AppCard(
        onTap: () => _editFaq(context, faq),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.question, style: AppTextStyles.subtitle),
                  SizedBox(height: 0.5.h),
                  Text(faq.answer, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.8.h),
                  faq.isActive
                      ? StatusChip.positive(AppStrings.statusActive)
                      : StatusChip.neutral(AppStrings.statusInactive),
                ],
              ),
            ),
            IconButton(
              tooltip: AppStrings.delete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () async {
                final vm = context.read<AdminSettingsViewModel>();
                final ok = await ConfirmDialog.show(
                  context,
                  message: AppStrings.deleteFaqConfirm,
                  confirmLabel: AppStrings.delete,
                  destructive: true,
                );
                if (!ok) return;
                final done = await vm.deleteFaq(faq.id);
                if (!done && context.mounted) {
                  AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editFaq(BuildContext context, FaqItem? faq) {
  final vm = context.read<AdminSettingsViewModel>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: _FaqEditor(faq: faq),
    ),
  );
}

class _FaqEditor extends StatefulWidget {
  const _FaqEditor({this.faq});

  final FaqItem? faq;

  @override
  State<_FaqEditor> createState() => _FaqEditorState();
}

class _FaqEditorState extends State<_FaqEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _q = TextEditingController(text: widget.faq?.question);
  late final _a = TextEditingController(text: widget.faq?.answer);
  late final _order = TextEditingController(text: '${widget.faq?.sortOrder ?? 0}');
  late bool _active = widget.faq?.isActive ?? true;

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AdminSettingsViewModel>();
    final ok = await vm.saveFaq(
      FaqItem(
        id: widget.faq?.id ?? '',
        question: _q.text.trim(),
        answer: _a.text.trim(),
        sortOrder: int.parse(_order.text.trim()),
        isActive: _active,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AdminSettingsViewModel, bool>((v) => v.isLoading);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(5.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.faq == null ? AppStrings.addFaq : AppStrings.editFaq, style: AppTextStyles.title),
                SizedBox(height: 2.h),
                AppTextField(controller: _q, label: AppStrings.question, validator: Validators.required, maxLines: 2),
                AppTextField(controller: _a, label: AppStrings.answer, validator: Validators.required, maxLines: 5),
                NumberField(controller: _order, label: AppStrings.sortOrderLabel, validator: Validators.nonNegativeInt),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text(AppStrings.activeLabel),
                ),
                SizedBox(height: 1.h),
                PrimaryButton(label: AppStrings.save, isLoading: loading, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
