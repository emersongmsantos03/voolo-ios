import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _SmoothPageTransitionsBuilder(),
      TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
    },
  );

  static const double radius = 24;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldDark = Color(0xFFF2D675);
  static const Color primaryGoldSoft = Color(0xFFFFF3C7);
  static const Color gold = primaryGold;
  static const Color yellow = Color(0xFFA8891F);
  static const Color backgroundLight = Color(0xFFF0ECE3);
  static const Color surfaceLight = Color(0xFFFAF7F0);
  static const Color surfaceMutedLight = Color(0xFFF4EFE6);
  static const Color highlightLight = Color(0xFFEFE4C7);
  static const Color textLight = Color(0xFF0B0B0C);
  static const Color textSecondaryLight = Color(0xFF544F47);
  static const Color dividerLight = Color(0xFFCFC5B4);

  static const Color backgroundDark = Color(0xFF0B0B0C);
  static const Color surfaceDark = Color(0xFF1A1A1D);
  static const Color surfaceMutedDark = Color(0xFF202024);
  static const Color highlightDark = Color(0xFF2A2312);
  static const Color textDark = Color(0xFFF5F3EE);
  static const Color textSecondaryDark = Color(0xFF9A9AA0);
  static const Color dividerDark = Color(0xFF2A2A2E);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color goodStatus = Color(0xFF22C55E);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.72);
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color highlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? highlightDark
          : highlightLight;
  static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color surfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceMutedDark
          : surfaceMutedLight;

  static BoxDecoration premiumCardDecoration(
    BuildContext context, {
    bool highlighted = false,
    Color? borderColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: highlighted
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.055 : 0.022),
              scheme.surfaceContainerLow,
            )
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(radius + 4),
      border: Border.all(
        color: borderColor ??
            scheme.outline.withValues(
              alpha: highlighted ? 0.18 : 0.08,
            ),
      ),
      boxShadow: isDark
          ? const []
          : [
              BoxShadow(
                color: const Color(0xFF111111).withValues(alpha: 0.028),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  static final ThemeData lightTheme = _buildTheme(brightness: Brightness.light);
  static final ThemeData darkTheme = _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? primaryGoldDark : yellow,
      onPrimary: const Color(0xFF111111),
      secondary: const Color(0xFF2563EB),
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: isDark ? surfaceDark : surfaceLight,
      onSurface: isDark ? textDark : textLight,
      onSurfaceVariant: isDark ? textSecondaryDark : textSecondaryLight,
      outline: isDark ? dividerDark : dividerLight,
      outlineVariant:
          isDark ? const Color(0xFF323236) : const Color(0xFFE1D6C5),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: isDark ? surfaceLight : surfaceDark,
      onInverseSurface: isDark ? textLight : textDark,
      inversePrimary: isDark ? primaryGold : primaryGold,
      surfaceDim: isDark ? const Color(0xFF080809) : const Color(0xFFE7E0D2),
      surfaceBright: isDark ? const Color(0xFF232327) : surfaceLight,
      surfaceContainerLowest:
          isDark ? const Color(0xFF101013) : const Color(0xFFFFFCF8),
      surfaceContainerLow:
          isDark ? const Color(0xFF17171A) : const Color(0xFFFBF8F2),
      surfaceContainer:
          isDark ? const Color(0xFF1D1D21) : const Color(0xFFF6F1E8),
      surfaceContainerHigh: isDark ? surfaceMutedDark : surfaceMutedLight,
      surfaceContainerHighest:
          isDark ? const Color(0xFF26262B) : const Color(0xFFECE4D6),
    );

    final textTheme = GoogleFonts.manropeTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: scheme.onPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitions,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.34),
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? backgroundDark : backgroundLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF201C18) : const Color(0xFF1A1714),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        actionTextColor: isDark ? primaryGoldDark : primaryGold,
        showCloseIcon: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 6),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 2),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.08 : 0.16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
        ),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.10 : 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.60),
            width: 1.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? scheme.primary : yellow,
          foregroundColor: isDark ? scheme.onPrimary : const Color(0xFFFFFBF2),
          minimumSize: const Size(0, 54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerHighest,
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
        secondarySelectedColor:
            scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
        disabledColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.24);
          }
          return scheme.outline.withValues(alpha: 0.18);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? scheme.primary : yellow,
        foregroundColor: isDark ? scheme.onPrimary : const Color(0xFFFFFBF2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 8)),
        ),
      ),
    );

    return base.copyWith(
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: scheme.primary.withValues(alpha: 0.36));
            }
            return BorderSide(color: scheme.outline.withValues(alpha: 0.16));
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08);
            }
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onSurface;
            return scheme.onSurfaceVariant;
          }),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelMedium?.copyWith(fontSize: 14),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }
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
      begin: const Offset(0.03, 0),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
