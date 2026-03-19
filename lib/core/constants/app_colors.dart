import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppColors {
  AppColors._();

  static const Color background = AppTheme.backgroundDark;
  static const Color surface = AppTheme.surfaceDark;

  static const Color primary = AppTheme.primaryGold;
  static const Color textPrimary = AppTheme.textDark;
  static const Color textSecondary = AppTheme.textSecondaryDark;

  static const Color fixedExpense = Color(0xFF8E6A2F);
  static const Color variableExpense = AppTheme.warning;
  static const Color investment = AppTheme.info;
  static const Color freeBalance = AppTheme.success;

  static const Color success = AppTheme.success;
  static const Color warning = AppTheme.warning;
  static const Color danger = AppTheme.danger;
  static const Color green = AppTheme.success;
  static const Color blue = AppTheme.info;
}
