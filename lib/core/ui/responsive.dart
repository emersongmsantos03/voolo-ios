import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class Responsive {
  Responsive._();

  static Size size(BuildContext context) => MediaQuery.sizeOf(context);

  static double width(BuildContext context) => size(context).width;

  static bool isCompactPhone(BuildContext context) => width(context) < 360;

  static bool isPhone(BuildContext context) => width(context) < 600;

  static EdgeInsets pagePadding(BuildContext context) {
    final w = width(context);
    final h = size(context).height;

    // Keep comfortable padding on larger screens, but reduce on small phones.
    final horizontal = w < 360 ? 16.0 : (w < 420 ? 20.0 : 24.0);
    final vertical = h < 700 ? 16.0 : 24.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1100) return 720;
    if (w >= 900) return 640;
    if (w >= 700) return 560;
    return w;
  }

  static double clampLogoWidth(
    BuildContext context, {
    double min = 180,
    double max = 390,
    double fraction = 0.82,
  }) {
    final w = width(context);
    return math.min(max, math.max(min, w * fraction));
  }

  static Widget centered({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? maxWidth,
  }) {
    final p = padding ?? pagePadding(context);
    final mw = maxWidth ?? maxContentWidth(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: Padding(padding: p, child: child),
      ),
    );
  }
}

