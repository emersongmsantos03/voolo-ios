import 'package:flutter/material.dart';
import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/routes/app_routes.dart';

class PremiumOnboardingPage extends StatefulWidget {
  const PremiumOnboardingPage({super.key});

  @override
  State<PremiumOnboardingPage> createState() => _PremiumOnboardingPageState();
}

class _PremiumOnboardingPageState extends State<PremiumOnboardingPage> {
  final Set<String> _visited = {};

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(context);
    final progress =
        steps.isEmpty ? 0.0 : _visited.length / steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'premium_onboarding_title')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.t(context, 'premium_onboarding_skip')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.t(context, 'premium_onboarding_subtitle'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tr(context, 'premium_onboarding_progress', {
                      'done': '${_visited.length}',
                      'total': '${steps.length}',
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _StepCard(
                  step: steps[i],
                  done: _visited.contains(steps[i].id),
                  onOpen: () async {
                    await Navigator.pushNamed(
                      context,
                      steps[i].route,
                      arguments: {
                        'premiumTour': true,
                        'tourStep': steps[i].id,
                      },
                    );
                    if (!mounted) return;
                    setState(() => _visited.add(steps[i].id));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.t(context, 'premium_onboarding_finish')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_OnboardingStep> _buildSteps(BuildContext context) => [
        _OnboardingStep(
          id: 'calculator',
          route: AppRoutes.investmentCalculator,
          icon: Icons.calculate_rounded,
          title: AppStrings.t(context, 'premium_step_invest_title'),
          body: AppStrings.t(context, 'premium_step_invest_body'),
          tip: AppStrings.t(context, 'premium_step_invest_tip'),
        ),
        _OnboardingStep(
          id: 'goals',
          route: AppRoutes.goals,
          icon: Icons.flag_rounded,
          title: AppStrings.t(context, 'premium_step_goals_title'),
          body: AppStrings.t(context, 'premium_step_goals_body'),
          tip: AppStrings.t(context, 'premium_step_goals_tip'),
        ),
        _OnboardingStep(
          id: 'missions',
          route: AppRoutes.missions,
          icon: Icons.auto_awesome_rounded,
          title: AppStrings.t(context, 'premium_step_missions_title'),
          body: AppStrings.t(context, 'premium_step_missions_body'),
          tip: AppStrings.t(context, 'premium_step_missions_tip'),
        ),
        _OnboardingStep(
          id: 'reports',
          route: AppRoutes.monthlyReport,
          icon: Icons.bar_chart_rounded,
          title: AppStrings.t(context, 'premium_step_reports_title'),
          body: AppStrings.t(context, 'premium_step_reports_body'),
          tip: AppStrings.t(context, 'premium_step_reports_tip'),
        ),
        _OnboardingStep(
          id: 'insights',
          route: AppRoutes.insights,
          icon: Icons.lightbulb_rounded,
          title: AppStrings.t(context, 'premium_step_insights_title'),
          body: AppStrings.t(context, 'premium_step_insights_body'),
          tip: AppStrings.t(context, 'premium_step_insights_tip'),
        ),
      ];
}

class _OnboardingStep {
  final String id;
  final String route;
  final IconData icon;
  final String title;
  final String body;
  final String tip;

  const _OnboardingStep({
    required this.id,
    required this.route,
    required this.icon,
    required this.title,
    required this.body,
    required this.tip,
  });
}

class _StepCard extends StatelessWidget {
  final _OnboardingStep step;
  final bool done;
  final VoidCallback onOpen;

  const _StepCard({
    required this.step,
    required this.done,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                done ? scheme.primary : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(step.icon, color: scheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (done)
                  Icon(Icons.check_circle, color: scheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(step.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                step.tip,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpen,
                child: Text(
                  AppStrings.t(context, 'premium_onboarding_open'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
