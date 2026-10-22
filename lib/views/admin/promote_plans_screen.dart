import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbars.dart';
import '../../core/utils/validators.dart';
import '../../data/models/promote_package.dart';
import '../../data/repositories/promote_repository.dart';
import '../../viewmodels/admin/promote_plans_view_model.dart';
import '../widgets/app_bar_x.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/number_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';

class PromotePlansScreen extends StatelessWidget {
  const PromotePlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PromotePlansViewModel(ctx.read<PromoteRepository>()),
      child: const _PlansView(),
    );
  }
}

class _PlansView extends StatelessWidget {
  const _PlansView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PromotePlansViewModel>();
    Widget body;
    if (vm.listLoading && vm.packages.isEmpty) {
      body = const SkeletonList();
    } else if (vm.listError != null && vm.packages.isEmpty) {
      body = ErrorState(message: vm.listError, onRetry: vm.load);
    } else if (vm.packages.isEmpty) {
      body = const EmptyState(
        title: AppStrings.noPackagesAdmin,
        message: AppStrings.noPackagesAdminMessage,
        icon: Icons.campaign_rounded,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView.separated(
          padding: EdgeInsets.all(4.w),
          itemCount: vm.packages.length,
          separatorBuilder: (_, _) => SizedBox(height: 1.5.h),
          itemBuilder: (_, i) => _PackageCard(package: vm.packages[i]),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarX(title: AppStrings.promotePlansManagement),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addPackage),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final PromotePackage package;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PromotePlansViewModel>();
    return AppCard(
      onTap: () => _edit(context, package),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(package.name, style: AppTextStyles.subtitle)),
              package.isActive
                  ? StatusChip.positive(AppStrings.statusActive)
                  : StatusChip.neutral(AppStrings.statusInactive),
            ],
          ),
          SizedBox(height: 0.6.h),
          Text(
            '${Formatters.pkr(package.price)} · ${AppStrings.packageDays(package.durationDays)}',
            style: AppTextStyles.body,
          ),
          if (package.description != null) ...[
            SizedBox(height: 0.4.h),
            Text(package.description!, style: AppTextStyles.caption),
          ],
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  final ok = await vm.toggleActive(package);
                  if (!ok && context.mounted) {
                    AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
                  }
                },
                child: Text(package.isActive ? AppStrings.deactivate : AppStrings.activate),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await ConfirmDialog.show(
                    context,
                    message: AppStrings.deletePackageConfirm,
                    confirmLabel: AppStrings.delete,
                    destructive: true,
                  );
                  if (!ok) return;
                  final deleted = await vm.delete(package.id);
                  if (!context.mounted) return;
                  if (deleted == null) {
                    AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
                  } else if (!deleted) {
                    AppSnackbars.info(context, AppStrings.packageInUse);
                  }
                },
                child: Text(AppStrings.delete, style: AppTextStyles.label.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _edit(BuildContext context, PromotePackage? package) {
  final vm = context.read<PromotePlansViewModel>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: _PackageEditor(package: package),
    ),
  );
}

class _PackageEditor extends StatefulWidget {
  const _PackageEditor({this.package});

  final PromotePackage? package;

  @override
  State<_PackageEditor> createState() => _PackageEditorState();
}

class _PackageEditorState extends State<_PackageEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.package?.name);
  late final _price = TextEditingController(text: widget.package == null ? '' : '${widget.package!.price}');
  late final _days = TextEditingController(text: widget.package == null ? '' : '${widget.package!.durationDays}');
  late final _order = TextEditingController(text: '${widget.package?.sortOrder ?? 0}');
  late final _desc = TextEditingController(text: widget.package?.description);
  late bool _active = widget.package?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _price, _days, _order, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<PromotePlansViewModel>();
    final desc = _desc.text.trim();
    final ok = await vm.save(
      PromotePackage(
        id: widget.package?.id ?? '',
        name: _name.text.trim(),
        price: int.parse(_price.text.trim()),
        durationDays: int.parse(_days.text.trim()),
        isActive: _active,
        sortOrder: int.parse(_order.text.trim()),
        description: desc.isEmpty ? null : desc,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      AppSnackbars.success(context, AppStrings.packageSaved);
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PromotePlansViewModel, bool>((v) => v.isLoading);
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
                Text(
                  widget.package == null ? AppStrings.addPackage : AppStrings.editPackage,
                  style: AppTextStyles.title,
                ),
                SizedBox(height: 2.h),
                AppTextField(controller: _name, label: AppStrings.packageName, validator: Validators.title),
                NumberField(controller: _price, label: AppStrings.packagePrice),
                NumberField(controller: _days, label: AppStrings.packageDurationDays),
                NumberField(controller: _order, label: AppStrings.sortOrderLabel, validator: Validators.nonNegativeInt),
                AppTextField(
                  controller: _desc,
                  label: '${AppStrings.packageDescription} ${AppStrings.optional}',
                  maxLines: 3,
                  validator: Validators.description,
                ),
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
