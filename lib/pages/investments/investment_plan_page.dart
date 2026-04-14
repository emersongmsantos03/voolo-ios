import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/plans/user_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/investment_profile.dart';
import '../../models/investment_plan_doc.dart';
import '../../services/advanced_modules_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/money_input.dart';
import '../../widgets/premium_gate.dart';

class _LocalInvestmentProfile {
  final String risk; // conservative | moderate | aggressive
  final int score;
  final Map<String, double> allocation;

  const _LocalInvestmentProfile({
    required this.risk,
    required this.score,
    required this.allocation,
  });
}

class _SuggestionBlock {
  final String label;
  final double percent;

  _SuggestionBlock({required this.label, required this.percent});
}

class _SuggestionCard {
  final String title;
  final String subtitle;
  final List<_SuggestionBlock> blocks;
  final List<String> notes;

  const _SuggestionCard({
    required this.title,
    required this.subtitle,
    required this.blocks,
    required this.notes,
  });
}

class InvestmentPlanPage extends StatefulWidget {
  const InvestmentPlanPage({super.key});

  @override
  State<InvestmentPlanPage> createState() => _InvestmentPlanPageState();
}

class _InvestmentPlanPageState extends State<InvestmentPlanPage> {
  final List<int?> _answers = List<int?>.filled(6, null);
  final _amountController = TextEditingController();
  final _emergencyMonthsController = TextEditingController();
  final _monthlyContributionController = TextEditingController();
  final _investNowController = TextEditingController();
  bool _saving = false;
  bool _savingPlan = false;
  bool _savingAllocation = false;
  bool _hydratedFromProfile = false;
  bool _hydratedFromPlan = false;
  bool _showEditor = false;
  bool _showPlanEditor = false;
  String? _selectedSuggestionTitle;
  InvestmentPlanDoc? _latestPlan;

  void _stopEditing() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emergencyMonthsController.dispose();
    _monthlyContributionController.dispose();
    _investNowController.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    if (_saving) return;
    final uid = LocalStorageService.currentUserId;
    if (uid == null) return;
    final hasAllAnswers = _answers.every((a) => a != null);
    if (!hasAllAnswers) return;
    _stopEditing();
    final answers = _answers.map((a) => a ?? 0).toList();
    setState(() => _saving = true);
    try {
      await AdvancedModulesService.computeInvestmentProfile(
        answers: answers,
      );
      await FirestoreService.saveInvestmentProfileAnswers(
        uid: uid,
        answers: answers,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppStrings.t(context, 'investment_profile_updated'))),
        );
      }
    } catch (_) {
      try {
        final local = _computeLocalProfile(answers);
        await FirestoreService.saveInvestmentProfileLocal(
          uid: uid,
          risk: local.risk,
          allocation: local.allocation,
          answers: answers,
          source: 'local',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(context, 'investment_profile_local_fallback'),
              ),
            ),
          );
        }
      } catch (_) {
        // ignore local fallback errors
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppStrings.t(context, 'investment_profile_local_saved'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _showEditor = false;
        });
        _stopEditing();
      }
    }
  }

  String _riskLabel(BuildContext context, String risk) {
    switch (risk) {
      case 'aggressive':
        return AppStrings.t(context, 'investment_risk_aggressive');
      case 'moderate':
        return AppStrings.t(context, 'investment_risk_moderate');
      default:
        return AppStrings.t(context, 'investment_risk_conservative');
    }
  }

  String _monthYearNow() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  _LocalInvestmentProfile _computeLocalProfile(List<int> answers) {
    final score = answers.fold<int>(0, (acc, v) => acc + v);
    final risk = score >= 9
        ? 'aggressive'
        : score >= 5
            ? 'moderate'
            : 'conservative';

    final allocation = risk == 'aggressive'
        ? <String, double>{
            'fixedLiquid': 0.35,
            'fixedLong': 0.25,
            'equity': 0.30,
            'highRisk': 0.10,
          }
        : risk == 'moderate'
            ? <String, double>{
                'fixedLiquid': 0.55,
                'fixedLong': 0.25,
                'equity': 0.18,
                'highRisk': 0.02,
              }
            : <String, double>{
                'fixedLiquid': 0.80,
                'fixedLong': 0.15,
                'equity': 0.05,
                'highRisk': 0.00,
              };

    return _LocalInvestmentProfile(
        risk: risk, score: score, allocation: allocation);
  }

  Map<String, dynamic> _defaultTargetsForRisk(String risk) {
    if (risk == 'aggressive') return {'emergencyMonths': 3, 'investPct': 0.20};
    if (risk == 'moderate') return {'emergencyMonths': 4, 'investPct': 0.15};
    return {'emergencyMonths': 6, 'investPct': 0.10};
  }

  List<_SuggestionCard> _buildSimpleSuggestions({
    required BuildContext context,
    required String risk,
    required double amount,
    required bool hasEmergencyFund,
  }) {
    if (!amount.isFinite || amount <= 0) return const [];

    final safetyNote = hasEmergencyFund
        ? null
        : AppStrings.t(context, 'investment_step_safety_note');

    final commonFixedLiquid =
        AppStrings.t(context, 'investment_fixed_liquid_label');

    if (!hasEmergencyFund) {
      return [
        _SuggestionCard(
          title: AppStrings.t(context, 'investment_reserve_emergency_title'),
          subtitle:
              AppStrings.t(context, 'investment_reserve_emergency_subtitle'),
          blocks: [
            _SuggestionBlock(
              label: commonFixedLiquid,
              percent: 1.0,
            ),
          ],
          notes: [
            AppStrings.t(context, 'investment_reserve_emergency_note_1'),
            AppStrings.t(context, 'investment_reserve_emergency_note_2'),
          ],
        ),
      ];
    }

    if (risk == 'aggressive') {
      return [
        _SuggestionCard(
          title: AppStrings.t(context, 'investment_step_simple_title'),
          subtitle: AppStrings.t(context, 'investment_step_simple_subtitle'),
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.45),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_ipca_label'),
              percent: 0.20,
            ),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_equity_label'),
              percent: 0.30,
            ),
            _SuggestionBlock(
              label: AppStrings.t(context, 'investment_high_risk_label'),
              percent: 0.05,
            ),
          ],
          notes: [
            if (safetyNote != null) safetyNote,
            AppStrings.t(context, 'investment_step_simple_note'),
          ],
        ),
        _SuggestionCard(
          title: AppStrings.t(context, 'investment_step_aggressive_title'),
          subtitle:
              AppStrings.t(context, 'investment_step_aggressive_subtitle'),
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.35),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_ipca_label'),
              percent: 0.20,
            ),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_equity_label'),
              percent: 0.40,
            ),
            _SuggestionBlock(
              label: AppStrings.t(context, 'investment_high_risk_label'),
              percent: 0.05,
            ),
          ],
          notes: [if (safetyNote != null) safetyNote],
        ),
      ];
    }

    if (risk == 'moderate') {
      return [
        _SuggestionCard(
          title: AppStrings.t(context, 'investment_step_moderate_title'),
          subtitle: AppStrings.t(context, 'investment_step_moderate_subtitle'),
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.60),
            _SuggestionBlock(
              label:
                  AppStrings.t(context, 'investment_step_moderate_ipca_label'),
              percent: 0.25,
            ),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_equity_label'),
              percent: 0.15,
            ),
          ],
          notes: [
            if (safetyNote != null) safetyNote,
            AppStrings.t(context, 'investment_step_moderate_note'),
          ],
        ),
        _SuggestionCard(
          title: AppStrings.t(context, 'investment_step_moderate_ipca_title'),
          subtitle:
              AppStrings.t(context, 'investment_step_moderate_ipca_subtitle'),
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.55),
            _SuggestionBlock(
              label:
                  AppStrings.t(context, 'investment_step_moderate_ipca_label'),
              percent: 0.30,
            ),
            _SuggestionBlock(
              label: AppStrings.t(
                  context, 'investment_step_aggressive_equity_label'),
              percent: 0.15,
            ),
          ],
          notes: [if (safetyNote != null) safetyNote],
        ),
      ];
    }

    return [
      _SuggestionCard(
        title: AppStrings.t(context, 'investment_step_conservative_title'),
        subtitle:
            AppStrings.t(context, 'investment_step_conservative_subtitle'),
        blocks: [
          _SuggestionBlock(label: commonFixedLiquid, percent: 1.0),
        ],
        notes: [
          if (safetyNote != null) safetyNote,
          AppStrings.t(context, 'investment_step_conservative_note'),
        ],
      ),
      _SuggestionCard(
        title: AppStrings.t(context, 'investment_step_conservative_long_title'),
        subtitle: AppStrings.t(
          context,
          'investment_step_conservative_long_subtitle',
        ),
        blocks: [
          _SuggestionBlock(label: commonFixedLiquid, percent: 0.80),
          _SuggestionBlock(
            label: AppStrings.t(context, 'investment_step_moderate_ipca_label'),
            percent: 0.20,
          ),
        ],
        notes: [
          if (safetyNote != null) safetyNote,
          AppStrings.t(context, 'investment_step_conservative_long_note'),
        ],
      ),
    ];
  }

  Future<void> _savePlanTargets({
    required String uid,
    required String monthYear,
    required InvestmentPlanDoc? existingPlan,
    required String? risk,
  }) async {
    if (_savingPlan) return;
    _stopEditing();

    final emergencyRaw = _emergencyMonthsController.text.trim();
    final monthlyRaw = _monthlyContributionController.text.trim();

    final emergencyMonths = emergencyRaw.isEmpty
        ? null
        : int.tryParse(emergencyRaw.replaceAll(RegExp(r'[^0-9]'), ''));

    final monthlyContribution =
        monthlyRaw.isEmpty ? null : parseMoneyInput(monthlyRaw);

    if (emergencyMonths != null &&
        (emergencyMonths <= 0 || emergencyMonths > 24)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(context, 'investment_plan_reserve_range_error'),
            ),
          ),
        );
      }
      return;
    }

    if (monthlyContribution != null &&
        (!monthlyContribution.isFinite || monthlyContribution < 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(context, 'investment_plan_monthly_amount_error'),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _savingPlan = true);
    try {
      await FirestoreService.saveInvestmentPlanTargets(
        uid: uid,
        monthYear: monthYear,
        emergencyMonthsTarget: emergencyMonths,
        monthlyContributionTarget: monthlyContribution,
        risk: risk,
        createdAtIso: existingPlan?.createdAt?.toIso8601String(),
      );
      if (mounted) {
        _stopEditing();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.t(context, 'investment_plan_saved'))),
        );
        setState(() => _showPlanEditor = false);
      }
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
  }

  Future<void> _saveAllocationChoice({
    required String uid,
    required String monthYear,
    required InvestmentPlanDoc? existingPlan,
    required String? risk,
    required List<_SuggestionCard> suggestions,
  }) async {
    if (_savingAllocation) return;
    _stopEditing();
    final title = _selectedSuggestionTitle;
    if (title == null || title.isEmpty) return;

    final chosen = suggestions.where((c) => c.title == title).toList();
    if (chosen.isEmpty) return;
    final card = chosen.first;

    final amount = parseMoneyInput(_investNowController.text.trim());
    final fallback =
        parseMoneyInput(_monthlyContributionController.text.trim());
    final selectedAmount = amount > 0
        ? amount
        : (existingPlan?.monthlyContributionTarget ?? fallback);

    if (selectedAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(context, 'investment_allocation_define_value'),
            ),
          ),
        );
      }
      return;
    }

    final selectedAllocation = InvestmentPlanSelectedAllocation(
      title: card.title,
      subtitle: card.subtitle,
      blocks: card.blocks
          .map((b) =>
              InvestmentPlanAllocationBlock(label: b.label, percent: b.percent))
          .toList(),
      notes: card.notes,
    );

    setState(() => _savingAllocation = true);
    try {
      await FirestoreService.saveInvestmentPlanAllocationChoice(
        uid: uid,
        monthYear: monthYear,
        risk: risk,
        selectedMonthlyAmount: selectedAmount,
        selectedAllocation: selectedAllocation,
        createdAtIso: existingPlan?.createdAt?.toIso8601String(),
      );
      if (mounted) {
        _stopEditing();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppStrings.t(context, 'investment_plan_choice_saved_snack'))),
        );
        setState(() => _showPlanEditor = false);
      }
    } finally {
      if (mounted) setState(() => _savingAllocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = LocalStorageService.currentUserId;
    final user = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(user, 'investment_plan');
    final monthYear = _monthYearNow();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'investments_plan'))),
      body: PremiumGate(
        isPremium: isPremium,
        title: AppStrings.t(context, 'investment_plan_title'),
        subtitle: AppStrings.t(context, 'investment_plan_subtitle'),
        perks: [
          AppStrings.t(context, 'investment_plan_perk_1'),
          AppStrings.t(context, 'investment_plan_perk_2'),
          AppStrings.t(context, 'investment_plan_perk_3')
        ],
        child: uid == null
            ? Center(
                child: Text(
                  AppStrings.t(context, 'login_required_missions'),
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              )
            : Padding(
                padding: Responsive.pagePadding(context),
                child: StreamBuilder<InvestmentProfile?>(
                  stream: FirestoreService.watchInvestmentProfile(uid),
                  builder: (context, snap) {
                    final profile = snap.data;

                    if (profile != null &&
                        !_hydratedFromProfile &&
                        profile.answers.length == _answers.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          for (var i = 0; i < _answers.length; i++) {
                            _answers[i] = profile.answers[i];
                          }
                          _hydratedFromProfile = true;
                        });
                      });
                    }

                    final answeredCount =
                        _answers.where((a) => a != null).length;
                    final hasAllAnswers = answeredCount == _answers.length;
                    final showEditor = profile == null || _showEditor;

                    return StreamBuilder<InvestmentPlanDoc?>(
                      stream: FirestoreService.watchInvestmentPlan(uid),
                      builder: (context, planSnap) {
                        final plan = planSnap.data;
                        _latestPlan = plan;

                        if (plan != null && !_hydratedFromPlan) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _emergencyMonthsController.text =
                                  plan.emergencyMonthsTarget?.toString() ?? '';
                              _monthlyContributionController.text =
                                  plan.monthlyContributionTarget != null
                                      ? formatMoneyInput(
                                          plan.monthlyContributionTarget!,
                                        )
                                      : '';
                              if (plan.selectedMonthlyAmount != null &&
                                  plan.selectedMonthlyAmount! > 0) {
                                _investNowController.text = formatMoneyInput(
                                  plan.selectedMonthlyAmount!,
                                );
                              }
                              _selectedSuggestionTitle =
                                  plan.selectedAllocation?.title;
                              _hydratedFromPlan = true;
                            });
                          });
                        }

                        if (plan == null &&
                            profile != null &&
                            !_hydratedFromPlan) {
                          final targets = _defaultTargetsForRisk(profile.risk);
                          final suggestedEmergency =
                              (targets['emergencyMonths'] as int?) ?? 6;
                          final investPct =
                              (targets['investPct'] as num?)?.toDouble() ??
                                  0.10;
                          final income =
                              LocalStorageService.incomeTotalForMonth(
                            DateTime.now(),
                          );
                          final suggestedMonthly =
                              income > 0 ? income * investPct : 0.0;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _emergencyMonthsController.text =
                                  '$suggestedEmergency';
                              if (suggestedMonthly > 0 &&
                                  _monthlyContributionController.text
                                      .trim()
                                      .isEmpty) {
                                _monthlyContributionController.text =
                                    formatMoneyInput(suggestedMonthly);
                              }
                              _hydratedFromPlan = true;
                            });
                          });
                        }

                        final effectiveAnswers =
                            _answers.map((a) => a ?? 0).toList();
                        final localProfile =
                            _computeLocalProfile(effectiveAnswers);
                        final effectiveRisk = profile?.risk ??
                            (hasAllAnswers
                                ? localProfile.risk
                                : 'conservative');
                        final hasEmergencyFund = (_answers.length >= 4)
                            ? ((_answers[3] ?? 0) >= 2)
                            : false;

                        final investNow =
                            parseMoneyInput(_investNowController.text);
                        final fallbackMonthly = parseMoneyInput(
                            _monthlyContributionController.text);
                        final amountForSuggestions = investNow > 0
                            ? investNow
                            : (plan?.monthlyContributionTarget ??
                                (fallbackMonthly > 0 ? fallbackMonthly : 0.0));

                        final suggestions = _buildSimpleSuggestions(
                          context: context,
                          risk: effectiveRisk,
                          amount: amountForSuggestions,
                          hasEmergencyFund: hasEmergencyFund,
                        );

                        if ((_selectedSuggestionTitle == null ||
                                _selectedSuggestionTitle!.isEmpty) &&
                            suggestions.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _selectedSuggestionTitle =
                                  plan?.selectedAllocation?.title ??
                                      suggestions.first.title;
                            });
                          });
                        }

                        final showPlanSummary =
                            plan != null && !_showPlanEditor;

                        return ListView(
                          children: [
                            if (showPlanSummary) ...[
                              _planSummaryCard(
                                plan: plan!,
                                fallbackRisk: effectiveRisk,
                                onEdit: () =>
                                    setState(() => _showPlanEditor = true),
                              ),
                            ] else ...[
                              if (profile != null && !showEditor) ...[
                                _resultCard(profile),
                                const SizedBox(height: 14),
                                _amountCard(),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              AppStrings.t(context,
                                                  'investment_plan_goals_title'),
                                              style: TextStyle(
                                                color: AppTheme.textPrimary(
                                                    context),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: _savingPlan
                                                ? null
                                                : () => _savePlanTargets(
                                                      uid: uid,
                                                      monthYear: monthYear,
                                                      existingPlan: plan,
                                                      risk: effectiveRisk,
                                                    ),
                                            child: Text(_savingPlan
                                                ? 'Salvando…'
                                                : AppStrings.t(context,
                                                    'investment_plan_save_button')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        AppStrings.t(context,
                                            'investment_plan_setup_help'),
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _emergencyMonthsController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: AppStrings.t(
                                            context,
                                            'investment_reserve_emergency_months_label',
                                          ),
                                          hintText: AppStrings.t(context,
                                              'investment_plan_reserve_months_hint'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller:
                                            _monthlyContributionController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: const [
                                          MoneyTextInputFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: AppStrings.t(context,
                                              'investment_plan_target_input_label'),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.t(
                                          context,
                                          'investment_plan_suggestions_title',
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppStrings.tr(
                                          context,
                                          'investment_plan_profile_summary',
                                          {
                                            'risk': _riskLabel(
                                                context, effectiveRisk),
                                            'amount': CurrencyUtils.format(
                                              amountForSuggestions,
                                            ),
                                          },
                                        ),
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _investNowController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: const [
                                          MoneyTextInputFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: AppStrings.t(context,
                                              'investment_plan_simulate_label'),
                                          hintText: AppStrings.t(context,
                                              'investment_plan_simulate_hint'),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 12),
                                      if (suggestions.isEmpty)
                                        Text(
                                          AppStrings.t(context,
                                              'investment_plan_suggestions_empty'),
                                          style: TextStyle(
                                            color:
                                                AppTheme.textSecondary(context),
                                          ),
                                        )
                                      else ...[
                                        ...suggestions.map((s) {
                                          final selected =
                                              _selectedSuggestionTitle ==
                                                  s.title;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.45)
                                                    : Colors.white10,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RadioListTile<String>(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  value: s.title,
                                                  groupValue:
                                                      _selectedSuggestionTitle,
                                                  onChanged: (v) => setState(() =>
                                                      _selectedSuggestionTitle =
                                                          v),
                                                  title: Text(
                                                    s.title,
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.textPrimary(
                                                              context),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    s.subtitle,
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .textSecondary(
                                                              context),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ...s.blocks.map((b) {
                                                  final pct =
                                                      (b.percent * 100).round();
                                                  final amount =
                                                      amountForSuggestions *
                                                          b.percent;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 6),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${b.label} ($pct%)',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .textSecondary(
                                                                      context),
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          CurrencyUtils.format(
                                                              amount),
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .textPrimary(
                                                                    context),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                                if (s.notes.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  ...s.notes.map(
                                                    (n) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 4),
                                                      child: Text(
                                                        '• $n',
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .textSecondary(
                                                                  context),
                                                          fontSize: 12,
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _savingAllocation
                                                ? null
                                                : () => _saveAllocationChoice(
                                                      uid: uid,
                                                      monthYear: monthYear,
                                                      existingPlan: plan,
                                                      risk: effectiveRisk,
                                                      suggestions: suggestions,
                                                    ),
                                            child: Text(_savingAllocation
                                                ? 'Salvando…'
                                                : AppStrings.t(context,
                                                    'investment_plan_save_choice')),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.t(context,
                                                  'investment_plan_choice_saved'),
                                              style: TextStyle(
                                                color: AppTheme.textPrimary(
                                                    context),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppStrings.t(context,
                                                  'investment_profile_saved_hint'),
                                              style: TextStyle(
                                                color: AppTheme.textSecondary(
                                                    context),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () =>
                                            setState(() => _showEditor = true),
                                        child: Text(AppStrings.t(
                                            context, 'profile_edit_short')),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (showEditor) ...[
                                if (profile != null) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Missão: definir seu perfil',
                                          style: TextStyle(
                                            color:
                                                AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _saving
                                            ? null
                                            : () => setState(
                                                  () => _showEditor = false,
                                                ),
                                        child: Text(
                                            AppStrings.t(context, 'cancel')),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Text(
                                    'Missão: definir seu perfil',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _missionCard(
                                  answeredCount: answeredCount,
                                  total: _answers.length,
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(
                                  _answers.length,
                                  (i) => _questionTile(i),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_saving || !hasAllAnswers)
                                        ? null
                                        : _compute,
                                    child: Text(_saving
                                        ? AppStrings.t(context,
                                            'investment_profile_calculating')
                                        : AppStrings.t(context,
                                            'investment_profile_calculate_button')),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _resultCard(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'investment_calculator'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'investment_projection_title'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String pctStr(String key) {
    final allocation = _currentAllocation();
    final value = allocation[key] ?? 0.0;
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String amountStr(String key) {
    final allocation = _currentAllocation();
    final monthly = parseMoneyInput(_monthlyContributionController.text);
    final value = allocation[key] ?? 0.0;
    final amount = monthly * value;
    return '\n${CurrencyUtils.format(amount)}';
  }

  Map<String, double> _currentAllocation() {
    final selected = _latestPlan?.selectedAllocation;
    if (selected != null && selected.blocks.isNotEmpty) {
      return {for (final b in selected.blocks) b.label: b.percent};
    }
    return _computeLocalProfile(_answers.whereType<int>().toList()).allocation;
  }

  Widget _planSummaryCard({
    required InvestmentPlanDoc plan,
    required String fallbackRisk,
    required VoidCallback onEdit,
  }) {
    final risk = plan.risk ?? fallbackRisk;
    final emergencyText = plan.emergencyMonthsTarget != null
        ? '${plan.emergencyMonthsTarget}'
        : '-';
    final monthlyTarget = plan.monthlyContributionTarget;
    final monthlyTargetText =
        monthlyTarget != null ? CurrencyUtils.format(monthlyTarget) : '-';
    final selectedAmount =
        plan.selectedMonthlyAmount ?? plan.monthlyContributionTarget ?? 0.0;
    final selectedAmountText =
        selectedAmount > 0 ? CurrencyUtils.format(selectedAmount) : '-';
    final allocation = plan.selectedAllocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.t(context, 'investment_plan_title'),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child:
                    Text(AppStrings.t(context, 'investment_plan_edit_button')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'investment_plan_quick_summary_label'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  label: AppStrings.t(context, 'investment_plan_target_label'),
                  value: monthlyTargetText,
                  icon: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: AppStrings.t(context, 'investment_allocate_now'),
                  value: selectedAmountText,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  label: AppStrings.t(context, 'investment_plan_profile_label'),
                  value: _riskLabel(context, risk),
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: AppStrings.t(context, 'investment_plan_reserve_label'),
                  value: emergencyText == '-' ? '-' : '$emergencyText meses',
                  icon: Icons.health_and_safety_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.t(context, 'investment_allocation_title'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _allocRow(
            AppStrings.t(context, 'investment_fixed_liquid_label'),
            '${pctStr('fixedLiquid')}${amountStr('fixedLiquid')}',
          ),
          _allocRow(
            AppStrings.t(context, 'investment_fixed_long_label'),
            '${pctStr('fixedLong')}${amountStr('fixedLong')}',
          ),
          _allocRow(
            AppStrings.t(context, 'investment_variable_diversified_label'),
            '${pctStr('equity')}${amountStr('equity')}',
          ),
          _allocRow(
            AppStrings.t(context, 'investment_high_risk_label'),
            '${pctStr('highRisk')}${amountStr('highRisk')}',
          ),
        ],
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'investment_plan_simulate_label'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'investment_plan_simulate_hint'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [MoneyTextInputFormatter()],
            decoration: InputDecoration(
              labelText:
                  AppStrings.t(context, 'investment_monthly_contribution'),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _allocRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionTile(int i) {
    final questionKeys = [
      'investment_question_1',
      'investment_question_2',
      'investment_question_3',
      'investment_question_4',
      'investment_question_5',
      'investment_question_6',
    ];

    final optionKeys = [
      [
        'investment_question_1_option_1',
        'investment_question_1_option_2',
        'investment_question_1_option_3',
      ],
      [
        'investment_question_2_option_1',
        'investment_question_2_option_2',
        'investment_question_2_option_3',
      ],
      [
        'investment_question_3_option_1',
        'investment_question_3_option_2',
        'investment_question_3_option_3',
      ],
      [
        'investment_question_4_option_1',
        'investment_question_4_option_2',
        'investment_question_4_option_3',
      ],
      [
        'investment_question_5_option_1',
        'investment_question_5_option_2',
        'investment_question_5_option_3',
      ],
      [
        'investment_question_6_option_1',
        'investment_question_6_option_2',
        'investment_question_6_option_3',
      ],
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, questionKeys[i]),
            style: TextStyle(color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              3,
              (v) => ChoiceChip(
                label: Text(AppStrings.t(context, optionKeys[i][v])),
                selected: _answers[i] == v,
                onSelected: (_) => setState(() => _answers[i] = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionCard({
    required int answeredCount,
    required int total,
  }) {
    final pct = total <= 0 ? 0.0 : (answeredCount / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.t(context, 'investment_plan_progress_label'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '$answeredCount/$total',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete para desbloquear suas sugestões de alocação.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
