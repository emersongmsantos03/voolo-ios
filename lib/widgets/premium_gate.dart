import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/legal_links.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
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
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.28,
                child: child,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.32),
                alignment: Alignment.center,
                child: _gateCard(context),
              ),
            ),
          ],
        ),
      );
    }

    return _fullScreenGate(context);
  }

  Widget _fullScreenGate(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            scheme.surfaceContainerLow,
          ],
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
              padding: const EdgeInsets.all(6),
              decoration: AppTheme.premiumCardDecoration(
                context,
                highlighted: true,
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
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;
    final ctaBackground = isDark ? scheme.primary : AppTheme.yellow;
    final ctaForeground = isDark ? scheme.onPrimary : const Color(0xFFFFFBF2);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: AppTheme.premiumCardDecoration(context),
          child: SizedBox(
            height: maxHeight,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: scheme.primary
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.lock_rounded,
                        color: scheme.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.primary
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.primary
                            .withValues(alpha: isDark ? 0.18 : 0.16),
                      ),
                    ),
                    child: Text(
                      AppStrings.t(context, 'premium_badge'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  ...perks.map((p) => _perkRow(context, p)),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onCta ??
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.premium),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ctaBackground,
                        foregroundColor: ctaForeground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        side: BorderSide(
                          color: scheme.primary
                              .withValues(alpha: isDark ? 0.0 : 0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        ctaLabel.isEmpty
                            ? AppStrings.t(context, 'premium_cta')
                            : ctaLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.t(context, 'premium_cancel_anytime') ==
                            'premium_cancel_anytime'
                        ? 'Cancele quando quiser.'
                        : AppStrings.t(context, 'premium_cancel_anytime'),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
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
          Icon(Icons.check_rounded, size: 18, color: scheme.primary),
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
  final String? title;
  final String? subtitle;

  const PremiumUpsellCard({
    super.key,
    required this.perks,
    this.onCta,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;
    final borderColor = scheme.outline.withValues(alpha: 0.16);
    final ctaBackground =
        isDark ? scheme.primary.withValues(alpha: 0.88) : AppTheme.yellow;
    final ctaForeground = isDark ? scheme.onPrimary : const Color(0xFFFFFBF2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.premiumCardDecoration(
        context,
        highlighted: true,
        borderColor: borderColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PremiumBadge(),
          const SizedBox(height: 12),
          Text(
            title ?? AppStrings.t(context, 'premium_upsell_title'),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...perks.take(3).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: scheme.primary
                              .withValues(alpha: isDark ? 0.72 : 0.54),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                            color: textSecondary,
                            height: 1.34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCta ??
                  () => Navigator.of(context).pushNamed(AppRoutes.premium),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ctaBackground,
                foregroundColor: ctaForeground,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                  color: scheme.primary.withValues(alpha: isDark ? 0.0 : 0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(AppStrings.t(context, 'premium_cta')),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(context, 'premium_subtitle_short'),
            style: TextStyle(
              color: textSecondary.withValues(alpha: 0.86),
              fontSize: 12,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: scheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            AppStrings.t(context, 'premium_badge'),
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
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
                    AppStrings.t(context, 'premium_dialog_choose_plan'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  _DialogPlanTile(
                    title: AppStrings.t(context, 'premium_plan_monthly_title'),
                    subtitle:
                        AppStrings.t(context, 'premium_plan_monthly_subtitle'),
                    selected: selectedPlan == 'monthly',
                    onTap: () => setDialogState(() => selectedPlan = 'monthly'),
                  ),
                  const SizedBox(height: 10),
                  _DialogPlanTile(
                    title: AppStrings.t(context, 'premium_plan_yearly_title'),
                    subtitle:
                        AppStrings.t(context, 'premium_plan_yearly_subtitle'),
                    selected: selectedPlan == 'yearly',
                    onTap: () => setDialogState(() => selectedPlan = 'yearly'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By subscribing, you agree to our Terms of Use (EULA) and Privacy Policy.',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _openLegalLink(LegalLinks.termsOfUseUrl),
                              child: const Text('Terms of Use (EULA)'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _openLegalLink(LegalLinks.privacyPolicyUrl),
                              child: const Text('Privacy Policy'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
          color:
              selected ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
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

Future<void> _openLegalLink(String url) async {
  await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
}
