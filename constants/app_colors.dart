import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF1A1A1A);

  static const Color primary = Color(0xFFFFC107); // Amarelo Jetx
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Financeiro
  static const Color fixedExpense = Color(0xFFE74C3C);     // vermelho
  static const Color variableExpense = Color(0xFFF1C40F);  // amarelo
  static const Color investment = Color(0xFF3498DB);       // azul
  static const Color freeBalance = Color(0xFF2ECC71);      // verde

  // Estados
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
}
