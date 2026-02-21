import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../core/ui/responsive.dart';
import '../routes/app_routes.dart';

class PremiumGate extends StatelessWidget {
  final Widget? child;
  final bool isPremium;
  final String title;
  final String subtitle;
  final List<String> perks;
  final String ctaLabel;
  final VoidCallback? onCta;

  const PremiumGate({
    super.key,
    this.child,
    this.isPremium = false,
    required this.title,
    required this.subtitle,
    required this.perks,
    this.ctaLabel = '',
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      if (isPremium) return child!;
      return Stack(
        children: [
          IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: 0.35,
              child: child,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: _gateCard(context),
            ),
          ),
        ],
      );
    }

    return _fullScreenGate(context);
  }

  Widget _fullScreenGate(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [const Color(0xFF0B0B0B), const Color(0xFF1E1E1E)]
        : [scheme.surfaceVariant, scheme.surface];
    final surface = isDark ? const Color(0xFF1E1E1E) : scheme.surface;
    final borderColor = isDark
        ? Colors.white10
        : scheme.outline.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: _gateCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gateCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : scheme.surface;
    final borderColor = isDark ? Colors.white10 : scheme.outline.withValues(alpha: 0.6);
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Icon(Icons.lock_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(AppStrings.t(context, 'premium_badge'), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              ...perks.map((p) => _perkRow(context, p)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCta ??
                      () => Navigator.of(context).pushNamed(AppRoutes.premium),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    ctaLabel.isEmpty ? AppStrings.t(context, 'premium_cta') : ctaLabel,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cancele quando quiser.',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _perkRow(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    final textSecondary = scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumUpsellCard extends StatelessWidget {
  final List<String> perks;
  final VoidCallback? onCta;

  const PremiumUpsellCard({
    super.key,
    required this.perks,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : scheme.surface;
    final borderColor = isDark
        ? Colors.white10
        : scheme.outline.withValues(alpha: 0.6);
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surface,
            surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PremiumBadge(),
          const SizedBox(height: 10),
          Text(
            AppStrings.t(context, 'premium_upsell_title'),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...perks.take(3).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $p',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCta ??
                  () => Navigator.of(context).pushNamed(AppRoutes.premium),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(AppStrings.t(context, 'premium_cta')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStrings.t(context, 'premium_badge'),
        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

void showPremiumDialog(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  String selectedPlan = 'monthly';

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.t(context, 'premium_dialog_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: AppStrings.t(context, 'close'),
                  ),
                ],
              ),
              Text(
                'Escolha seu plano premium:',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _DialogPlanTile(
                title: 'Plano mensal - R\$ 29,90/mes',
                subtitle: 'Renovacao automatica. Cancele quando quiser.',
                selected: selectedPlan == 'monthly',
                onTap: () => setDialogState(() => selectedPlan = 'monthly'),
              ),
              const SizedBox(height: 10),
              _DialogPlanTile(
                title: 'Plano anual - R\$ 299,90/ano',
                subtitle:
                    'Pagamento anual com acesso premium durante todos os meses do periodo.',
                selected: selectedPlan == 'yearly',
                onTap: () => setDialogState(() => selectedPlan = 'yearly'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(
                      AppRoutes.premium,
                      arguments: {'plan': selectedPlan},
                    );
                  },
                  child: Text(AppStrings.t(context, 'premium_cta')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DialogPlanTile extends StatelessWidget {
  const _DialogPlanTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
