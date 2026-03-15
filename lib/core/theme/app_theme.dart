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

  static const double _radius = 18;
  static const double _radiusLarge = 28;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static const Color gold = Color(0xFFD4AF37);
  static const Color yellow = Color(0xFFF5C842);
  static const Color black = Color(0xFF0F1115);
  static const Color graphite = Color(0xFF171A20);
  static const Color greyMedium = Color(0xFF8E8E8E);
  static const Color greyLight = Color(0xFFE5E5E5);
  static const Color softLight = Color(0xFFF7F3EA);
  static const Color warmWhite = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF22C55E);
  static const Color goodStatus = Color(0xFFA3E635);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF4C8DFF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFFF7D86E),
      Color(0xFFD4AF37),
      Color(0xFFB98D1A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient authBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [
              Color(0xFF0C0D10),
              Color(0xFF141821),
              Color(0xFF201806),
            ]
          : const [
              Color(0xFFF8F3E8),
              Color(0xFFF3ECE0),
              Color(0xFFEDE0C1),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static List<BoxShadow> softShadow(BuildContext context, {double depth = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = isDark ? 0.22 : 0.09;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity * depth),
        blurRadius: 32,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity * 0.35 * depth),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static BoxDecoration panelDecoration(
    BuildContext context, {
    double radius = _radiusLarge,
    bool highlighted = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColors = highlighted
        ? (isDark
            ? const [
                Color(0xFF2D2310),
                Color(0xFF1C2028),
                Color(0xFF15181F),
              ]
            : const [
                Color(0xFFFFFDF7),
                Color(0xFFF9F1DD),
                Color(0xFFF4E7C4),
              ])
        : (isDark
            ? const [
                Color(0xFF1B2029),
                Color(0xFF161A21),
                Color(0xFF12151B),
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFCF8),
                scheme.surface,
              ]);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: baseColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlighted
            ? scheme.primary.withValues(alpha: isDark ? 0.3 : 0.22)
            : scheme.outline.withValues(alpha: isDark ? 0.34 : 0.72),
      ),
      boxShadow: softShadow(context, depth: highlighted ? 1.2 : 1),
    );
  }

  static BoxDecoration tintedPanelDecoration(
    BuildContext context, {
    required Color tint,
    double radius = _radiusLarge,
    double tintOpacity = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.alphaBlend(
            tint.withValues(alpha: isDark ? tintOpacity * 1.2 : tintOpacity),
            scheme.surface,
          ),
          Color.alphaBlend(
            tint.withValues(
                alpha: isDark ? tintOpacity * 0.35 : tintOpacity * 0.55),
            scheme.surface,
          ),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: tint.withValues(alpha: isDark ? 0.22 : 0.18),
      ),
      boxShadow: softShadow(context, depth: 0.9),
    );
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    pageTransitionsTheme: _pageTransitions,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: softLight,
    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: yellow,
      surface: warmWhite,
      onPrimary: white,
      onSurface: Color(0xFF111318),
      onSurfaceVariant: Color(0xFF706857),
      outline: Color(0xFFE1D5BE),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: const Color(0xFF111318),
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF111318)),
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF111318),
          fontWeight: FontWeight.w700,
          fontSize: 26,
          letterSpacing: -0.8,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF111318),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF111318),
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF706857),
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFCF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: Color(0xFFE3D8C7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.9), width: 1.4),
      ),
      labelStyle: const TextStyle(color: Color(0xFF756C5A)),
      hintStyle: const TextStyle(color: Color(0xFFAAA08D)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: white,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 2),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111318),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 2),
        ),
        side: const BorderSide(color: Color(0xFFE3D8C7)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: warmWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radiusLarge)),
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
      backgroundColor: warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLarge),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEBE1D1),
      thickness: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    pageTransitionsTheme: _pageTransitions,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: black,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: yellow,
      surface: graphite,
      onPrimary: Color(0xFF0B0C0F),
      onSurface: Color(0xFFF5F6F7),
      onSurfaceVariant: Color(0xFF9FA7B5),
      outline: Color(0xFF2A2F3A),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: const Color(0xFFF5F6F7),
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF5F6F7)),
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      const TextTheme(
        titleLarge: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
        titleMedium: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: white,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: greyMedium,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: black,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF171B22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
        borderSide: BorderSide(color: gold.withValues(alpha: 0.9), width: 1.4),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF0B0C0F),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 2),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF5F6F7),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: const Color(0xFF171B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 2),
        ),
        side: const BorderSide(color: Color(0xFF2A2F3A)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: graphite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radiusLarge)),
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
      backgroundColor: graphite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLarge),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
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
