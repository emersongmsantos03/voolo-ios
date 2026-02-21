import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/app_strings.dart';
import '../routes/app_routes.dart';
import '../services/local_storage_service.dart';
import '../state/user_state.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _proBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 14, color: AppColors.primary),
          SizedBox(width: 6),
          Text(
            'PRO',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoWidget(String? path) {
    if (path == null || path.isEmpty) {
      return const Icon(Icons.person, size: 36);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ClipOval(child: Image.network(path, fit: BoxFit.cover));
    }
    final file = File(path);
    if (!file.existsSync()) {
      return const Icon(Icons.person, size: 36);
    }
    return ClipOval(child: Image.file(file, fit: BoxFit.cover));
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;
    final isPremium = user?.isPremium ?? false;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: _photoWidget(user?.photoPath),
            ),
            accountName:
                Text(user?.fullName ?? AppStrings.t(context, 'user_label')),
            accountEmail: Text(AppStrings.t(context, 'profile_edit_short')),
            onDetailsPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          _item(context, Icons.person_rounded,
              AppStrings.t(context, 'profile_edit_short'), AppRoutes.profile),
          _item(context, Icons.dashboard_rounded,
              AppStrings.t(context, 'dashboard'), AppRoutes.dashboard),
          _item(context, Icons.bar_chart_rounded,
              AppStrings.t(context, 'insights'), AppRoutes.insights),
          _item(context, Icons.track_changes_rounded,
              AppStrings.t(context, 'missions'), AppRoutes.missions,
              premium: true, isPremium: isPremium),
          _item(context, Icons.rocket_launch_rounded,
              AppStrings.t(context, 'goals'), AppRoutes.goals,
              premium: true, isPremium: isPremium),
          _item(context, Icons.pie_chart_rounded,
              AppStrings.t(context, 'reports'), AppRoutes.monthlyReport,
              premium: true, isPremium: isPremium),
          _item(
              context,
              Icons.calculate_rounded,
              AppStrings.t(context, 'simulator'),
              AppRoutes.investmentCalculator,
              premium: true,
              isPremium: isPremium),
          _item(context, Icons.account_balance_wallet_rounded,
              AppStrings.t(context, 'budgets'), AppRoutes.budgets,
              premium: true, isPremium: isPremium),
          _item(
              context,
              Icons.trending_up_rounded,
              AppStrings.t(context, 'investments_plan'),
              AppRoutes.investmentPlan,
              premium: true,
              isPremium: isPremium),
          _item(context, Icons.credit_score_rounded,
              AppStrings.t(context, 'debts_exit'), AppRoutes.debts,
              premium: true, isPremium: isPremium),
          const Divider(),
          _item(context, Icons.logout_rounded, AppStrings.t(context, 'logout'),
              null,
              isLogout: true),
        ],
      ),
    );
  }

  ListTile _item(
    BuildContext context,
    IconData icon,
    String title,
    String? route, {
    bool isLogout = false,
    bool premium = false,
    bool isPremium = true,
  }) {
    return ListTile(
      leading:
          Icon(icon, color: isLogout ? Colors.redAccent : AppColors.primary),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isLogout ? Colors.redAccent : null)),
      trailing: premium && !isPremium ? _proBadge() : null,
      onTap: () async {
        Navigator.pop(context); // Close drawer
        if (isLogout) {
          await LocalStorageService.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } else if (route != null) {
          if (premium && !isPremium) {
            Navigator.pushNamed(context, AppRoutes.premium);
            return;
          }
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
