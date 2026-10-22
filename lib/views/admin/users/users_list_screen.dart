import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../viewmodels/admin/admin_users_view_model.dart';
import '../../widgets/app_bar_x.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/user_avatar.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  static const _labels = {
    UserFilter.all: AppStrings.all,
    UserFilter.subscribed: AppStrings.filterSubscribed,
    UserFilter.notSubscribed: AppStrings.filterNotSubscribed,
    UserFilter.blocked: AppStrings.filterBlocked,
  };

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminUsersViewModel(ctx.read<AdminUserRepository>()),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AdminUsersViewModel>();
          return Scaffold(
            appBar: const AppBarX(title: AppStrings.usersTitle, automaticallyImplyLeading: false),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
                    child: TextField(
                      onChanged: vm.setSearch,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: AppStrings.searchUsersHint,
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 7.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      children: UserFilter.values
                          .map(
                            (f) => Padding(
                              padding: EdgeInsets.only(right: 2.w),
                              child: ChoiceChip(
                                label: Text(_labels[f]!),
                                selected: vm.filter == f,
                                onSelected: (_) => vm.setFilter(f),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: PagedListView<AppUser>(
                      list: vm.users,
                      emptyTitle: AppStrings.noUsers,
                      emptyMessage: AppStrings.noUsersMessage,
                      emptyIcon: Icons.person_search_rounded,
                      itemBuilder: (ctx, u) => _UserTile(user: u),
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

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(3.5.w),
      onTap: () => context.push(Routes.adminUser(user.uid)),
      child: Row(
        children: [
          UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.subtitle),
                Text(user.email, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                Text('${user.phone} · ${Formatters.pkr(user.balance)}', style: AppTextStyles.caption),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (user.isBlocked) StatusChip.negative(AppStrings.statusBlocked),
              if (!user.isBlocked)
                user.subscriptionActive
                    ? StatusChip.positive(AppStrings.statusSubscribed)
                    : StatusChip.neutral(AppStrings.statusNotSubscribed),
            ],
          ),
        ],
      ),
    );
  }
}
