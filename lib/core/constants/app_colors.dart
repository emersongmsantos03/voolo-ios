import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFF131416);
  static const Color surface = Color(0xFF1C1D21);

  static const Color primary = Color(0xFFD4AF37); // Voolo Gold
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E8E);

  // Financeiro (Aligning with App Web / Admin Web)
  static const Color fixedExpense = Color(0xFFF15B5B);     // Vermelho/Salmon
  static const Color variableExpense = Color(0xFFF5C842);  // Amarelo Voolo
  static const Color investment = Color(0xFF4C8DFF);       // Azul
  static const Color freeBalance = Color(0xFF33C587);      // Verde

  // Estados
  static const Color success = Color(0xFF33C587);
  static const Color warning = Color(0xFFF5C842);
  static const Color danger = Color(0xFFF15B5B);
  
  static const Color green = success;
  static const Color blue = investment;
}
