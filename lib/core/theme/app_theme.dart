import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(); // prevents instantiation

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _SmoothPageTransitionsBuilder(),
      TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
    },
  );

  static const double _radius = 14;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  // Official Palette
  static const Color gold = Color(0xFFD4AF37);
  static const Color yellow = Color(0xFFF5C842);
  
  static const Color black = Color(0xFF0F1115); // Softer dark (less harsh)
  static const Color graphite = Color(0xFF171A20); // Elevated surface
  static const Color greyMedium = Color(0xFF8E8E8E);
  static const Color greyLight = Color(0xFFE5E5E5);
  static const Color softLight = Color(0xFFF7F7F6); // Neutral light (less yellow)
  static const Color warmWhite = Color(0xFFFFFFFF); // Clean surface
  static const Color white = Color(0xFFFFFFFF);

  // Status indicators (kept for functionality, adjusted for harmony)
  static const Color success = Color(0xFF22C55E); // Green
  static const Color goodStatus = Color(0xFFA3E635); // Yellow-Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF4C8DFF);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    pageTransitionsTheme: _pageTransitions,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: softLight,
    colorScheme: ColorScheme.light(
      primary: gold,
      secondary: yellow,
      surface: warmWhite,
      surfaceVariant: const Color(0xFFF0F0EF),
      onPrimary: white,
      onSurface: const Color(0xFF111318),
      onSurfaceVariant: const Color(0xFF6B7280),
      outline: const Color(0xFFE6E6E4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: softLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFF111318),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF111318)),
    ),
    textTheme: GoogleFonts.interTextTheme(TextTheme(
      titleLarge: TextStyle(
        color: const Color(0xFF111318),
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        color: const Color(0xFF111318),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(
        color: const Color(0xFF111318),
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        color: const Color(0xFF6B7280),
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        color: white,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    )),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: warmWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: Color(0xFFE6E6E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.9)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111318),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        side: const BorderSide(color: Color(0xFFE6E6E4)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: warmWhite,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius + 2)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius + 4),
      ),
    ),
    // cardColor: surfaceLight, // Removed
    // progressIndicatorTheme: const ProgressIndicatorThemeData( // Removed
    //   color: primary,
    //   linearTrackColor: surfaceMutedLight,
    // ),
    // floatingActionButtonTheme: const FloatingActionButtonThemeData( // Removed
    //   backgroundColor: primary,
    //   foregroundColor: Colors.white,
    //   elevation: 1,
    // ),
    // chipTheme: const ChipThemeData( // Removed
    //   backgroundColor: surfaceMutedLight,
    //   selectedColor: primary,
    //   secondarySelectedColor: warning,
    //   labelStyle: TextStyle(color: textSecondaryLight),
    //   secondaryLabelStyle: TextStyle(color: Colors.white),
    //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    // ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEDEDED),
      thickness: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    pageTransitionsTheme: _pageTransitions,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: black,

    // Material 3 color scheme
    colorScheme: ColorScheme.dark(
      primary: gold,
      secondary: yellow,
      surface: graphite,
      onPrimary: const Color(0xFF0B0C0F),
      onSurface: const Color(0xFFF5F6F7),
      onSurfaceVariant: const Color(0xFF9CA3AF),
      outline: const Color(0xFF2A2F3A),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFFF5F6F7),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF5F6F7)),
    ),

    textTheme: GoogleFonts.interTextTheme(const TextTheme(
      titleLarge: TextStyle(
        color: white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      titleMedium: TextStyle(
        color: white,
        fontSize: 18,
      ),
      bodyLarge: TextStyle(
        color: white,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: greyMedium,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: black,
        fontWeight: FontWeight.bold,
      ),
    )),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: graphite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: Color(0xFF2A2F3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.9)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF0B0C0F),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        shadowColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Card theme for consistent rounded surfaces.
    cardTheme: const CardThemeData(
      elevation: 0,
      color: graphite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius + 2)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius + 4),
      ),
    ),
    // cardColor: surface, // Removed

    // progressIndicatorTheme: const ProgressIndicatorThemeData( // Removed
    //   color: primary,
    //   linearTrackColor: Color(0xFF1B2A42),
    // ),
    // floatingActionButtonTheme: const FloatingActionButtonThemeData( // Removed
    //   backgroundColor: primary,
    //   foregroundColor: Colors.black,
    // ),

    // chipTheme: const ChipThemeData( // Removed
    //   backgroundColor: Color(0xFF1B2A42),
    //   selectedColor: Color(0xFF3DCB9A),
    //   secondarySelectedColor: Color(0xFFF0A84B),
    //   labelStyle: TextStyle(color: Colors.white70),
    //   secondaryLabelStyle: TextStyle(color: Colors.black),
    //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    // ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2F3A),
      thickness: 1,
    ),
  );
}

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
