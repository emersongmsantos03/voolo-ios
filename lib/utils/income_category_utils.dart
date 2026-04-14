import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';

class IncomeCategoryUtils {
  IncomeCategoryUtils._();

  static const salary = 'salary';
  static const service = 'service';
  static const yieldIncome = 'yield';
  static const bonus = 'bonus';
  static const other = 'other';

  static const all = <String>[
    salary,
    service,
    yieldIncome,
    bonus,
    other,
  ];

  static String normalize(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'fixed':
      case salary:
        return salary;
      case 'variable':
      case service:
        return service;
      case yieldIncome:
        return yieldIncome;
      case bonus:
        return bonus;
      case other:
        return other;
      default:
        return other;
    }
  }

  static String label(BuildContext context, String raw) {
    switch (normalize(raw)) {
      case salary:
        return AppStrings.t(context, 'income_category_salary');
      case service:
        return AppStrings.t(context, 'income_category_service');
      case yieldIncome:
        return AppStrings.t(context, 'income_category_yield');
      case bonus:
        return AppStrings.t(context, 'income_category_bonus');
      default:
        return AppStrings.t(context, 'income_category_other');
    }
  }

  static String iconLabel(String raw) => labelTextForRaw(raw);

  static String labelTextForRaw(String raw) {
    switch (normalize(raw)) {
      case salary:
        return 'salary';
      case service:
        return 'service';
      case yieldIncome:
        return 'yield';
      case bonus:
        return 'bonus';
      default:
        return 'other';
    }
  }

  static IconData icon(String raw) {
    switch (normalize(raw)) {
      case salary:
        return Icons.badge_outlined;
      case service:
        return Icons.handyman_outlined;
      case yieldIncome:
        return Icons.trending_up_rounded;
      case bonus:
        return Icons.card_giftcard_outlined;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}
