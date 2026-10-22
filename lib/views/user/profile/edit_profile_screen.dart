import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../viewmodels/auth/session_view_model.dart';
import '../../../viewmodels/connectivity_view_model.dart';
import '../../../viewmodels/user/profile_view_model.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EditProfileViewModel(repo: ctx.read<UserRepository>(), uid: ctx.read<SessionViewModel>().uid!),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<SessionViewModel>().user!;
  late final _name = TextEditingController(text: _user.name);
  late final _phone = TextEditingController(text: _user.phone);
  late final _photo = TextEditingController(text: _user.photoUrl);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _photo.dispose();
    super.dispose();
  }

  String? _url(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    final ok = uri != null && uri.hasScheme && uri.scheme.startsWith('http') && t.length <= 500;
    return ok ? null : AppStrings.invalidUrl;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<EditProfileViewModel>();
    final ok = await vm.save(name: _name.text, phone: _phone.text, photoUrl: _photo.text);
    if (!mounted) return;
    if (ok) {
      AppSnackbars.success(context, AppStrings.profileUpdated);
      context.pop();
    } else {
      AppSnackbars.error(context, vm.errorMessage ?? AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final online = context.select<ConnectivityViewModel, bool>((c) => c.isOnline);
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
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
                        AppStrings.editProfile,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── form ──
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 3.h),
                  child: Column(
                    children: [
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
                              'Personal Info',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                            ),
                            SizedBox(height: 2.h),
                            AppTextField(
                              controller: _name,
                              label: AppStrings.name,
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.name,
                            ),
                            AppTextField(
                              controller: _phone,
                              label: AppStrings.phone,
                              hint: AppStrings.phoneHint,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: Validators.phone,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]'))],
                            ),
                            AppTextField(
                              controller: _photo,
                              label: '${AppStrings.photoUrl} ${AppStrings.optional}',
                              prefixIcon: Icons.image_outlined,
                              keyboardType: TextInputType.url,
                              validator: _url,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.5.h),

                      // ── save button ──
                      GestureDetector(
                        onTap: online && !vm.isLoading ? _save : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: online ? 1.0 : 0.5,
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
                                      Icon(Icons.check_rounded, color: AppColors.white, size: 5.w),
                                      SizedBox(width: 2.w),
                                      Text(
                                        AppStrings.save,
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
}
