import 'package:flutter/material.dart';

class PremiumTourOverlay extends StatelessWidget {
  final bool active;
  final Widget child;
  final Widget spotlight;

  const PremiumTourOverlay({
    super.key,
    required this.active,
    required this.child,
    required this.spotlight,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: spotlight,
          ),
        ),
      ],
    );
  }
}

class PremiumTourSpotlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String location;
  final String tip;

  const PremiumTourSpotlight({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.location,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .shadowColor
                .withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.2),
              ),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  tip,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumTourHighlight extends StatelessWidget {
  final bool active;
  final Widget child;

  const PremiumTourHighlight({
    super.key,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .shadowColor
                .withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
