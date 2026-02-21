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

  const _SuggestionBlock({required this.label, required this.percent});
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
          const SnackBar(content: Text('Perfil atualizado.')),
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
            const SnackBar(
              content: Text(
                  'Não foi possível calcular online; usei um cálculo local simples.'),
            ),
          );
        }
      } catch (_) {
        // ignore local fallback errors
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil aplicado localmente.')),
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

  String _riskLabel(String risk) {
    switch (risk) {
      case 'aggressive':
        return 'Agressivo';
      case 'moderate':
        return 'Moderado';
      default:
        return 'Conservador';
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
    required String risk,
    required double amount,
    required bool hasEmergencyFund,
  }) {
    if (!amount.isFinite || amount <= 0) return const [];

    final smallAmount = amount < 100;
    final safetyNote = hasEmergencyFund
        ? null
        : 'Antes de aumentar o risco, priorize montar uma reserva de emergência.';

    final commonFixedLiquid = smallAmount
        ? 'Tesouro Selic / CDB com liquidez diária'
        : 'Tesouro Selic / CDB 100%+ CDI (liquidez diária)';

    if (!hasEmergencyFund) {
      return [
        _SuggestionCard(
          title: 'Reserva de emergência (prioridade)',
          subtitle: 'Simples e líquido — até completar a reserva.',
          blocks: const [
            _SuggestionBlock(
                label: 'Renda fixa com liquidez (Selic/CDB)', percent: 1.0)
          ],
          notes: const [
            'Objetivo: 3–6 meses de custos essenciais em liquidez diária.',
            'Depois da reserva pronta, volte aqui e escolha uma alocação de longo prazo.',
          ],
        ),
      ];
    }

    if (risk == 'aggressive') {
      return [
        _SuggestionCard(
          title: 'Primeiro passo (simples)',
          subtitle: 'Equilíbrio entre segurança e crescimento.',
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.45),
            const _SuggestionBlock(
                label: 'Tesouro IPCA+ curto/médio / renda fixa mais longa',
                percent: 0.20),
            const _SuggestionBlock(
                label: 'ETF de ações amplo (Brasil e/ou global)',
                percent: 0.30),
            const _SuggestionBlock(
                label: 'Alto risco (opcional)', percent: 0.05),
          ],
          notes: [
            if (safetyNote != null) safetyNote,
            'Se quiser deixar ainda mais simples: reduza “alto risco” para 0% e aumente o ETF.',
          ],
        ),
        _SuggestionCard(
          title: 'Agressivo (diversificado)',
          subtitle: 'Mais volatilidade, sempre com base segura.',
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.35),
            const _SuggestionBlock(
                label: 'Tesouro IPCA+ / prefixados', percent: 0.20),
            const _SuggestionBlock(label: 'ETF de ações amplo', percent: 0.40),
            const _SuggestionBlock(
                label: 'Alto risco (opcional)', percent: 0.05),
          ],
          notes: [if (safetyNote != null) safetyNote],
        ),
      ];
    }

    if (risk == 'moderate') {
      return [
        _SuggestionCard(
          title: 'Moderado (simples)',
          subtitle: 'Para começar sem estresse.',
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.60),
            const _SuggestionBlock(
                label: 'Tesouro IPCA+ curto/médio', percent: 0.25),
            const _SuggestionBlock(
                label: 'ETF de ações amplo (Brasil e/ou global)',
                percent: 0.15),
          ],
          notes: [
            if (safetyNote != null) safetyNote,
            'Se oscilar te incomodar, aumente a parte “liquidez” e reduza o ETF.',
          ],
        ),
        _SuggestionCard(
          title: 'Moderado com IPCA',
          subtitle: 'Mais proteção de longo prazo, mantendo simplicidade.',
          blocks: [
            _SuggestionBlock(label: commonFixedLiquid, percent: 0.55),
            const _SuggestionBlock(
                label: 'Tesouro IPCA+ curto/médio', percent: 0.30),
            const _SuggestionBlock(label: 'ETF de ações amplo', percent: 0.15),
          ],
          notes: [if (safetyNote != null) safetyNote],
        ),
      ];
    }

    return [
      _SuggestionCard(
        title: 'Começo conservador',
        subtitle: 'Para sair do zero sem estresse.',
        blocks: [_SuggestionBlock(label: commonFixedLiquid, percent: 1.0)],
        notes: [
          if (safetyNote != null) safetyNote,
          'Depois que a reserva estiver pronta, você pode adicionar um pouco de IPCA+ ou ETF.',
        ],
      ),
      _SuggestionCard(
        title: 'Conservador + longo prazo',
        subtitle: 'Um toque de longo prazo, mantendo segurança.',
        blocks: [
          _SuggestionBlock(label: commonFixedLiquid, percent: 0.80),
          const _SuggestionBlock(
              label: 'Tesouro IPCA+ curto/médio', percent: 0.20),
        ],
        notes: [if (safetyNote != null) safetyNote],
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
          const SnackBar(
              content: Text('Defina uma meta de reserva entre 1 e 24 meses.')),
        );
      }
      return;
    }

    if (monthlyContribution != null &&
        (!monthlyContribution.isFinite || monthlyContribution < 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Defina um aporte mensal válido.')),
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
          const SnackBar(content: Text('Plano salvo.')),
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
          const SnackBar(content: Text('Defina um valor para alocar.')),
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
          const SnackBar(content: Text('Escolha salva.')),
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
                          final income = user?.monthlyIncome ?? 0.0;
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
                                              'Metas',
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
                                                : 'Salvar'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Defina metas simples (reserva e aporte). Você pode ajustar depois.',
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
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Reserva de emergência (meses)',
                                          hintText: 'Ex.: 3, 4, 6',
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
                                        decoration: const InputDecoration(
                                          labelText: 'Aporte mensal alvo (R\$)',
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
                                        'Sugestões para este mês',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Perfil: ${_riskLabel(effectiveRisk)} • Valor usado: ${CurrencyUtils.format(amountForSuggestions)}',
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
                                        decoration: const InputDecoration(
                                          labelText: 'Simular valor (opcional)',
                                          hintText:
                                              'Se vazio, usamos o aporte mensal alvo.',
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 12),
                                      if (suggestions.isEmpty)
                                        Text(
                                          'Defina um valor (aporte) para ver sugestões.',
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
                                                : 'Salvar esta escolha'),
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
                                              'Perfil salvo',
                                              style: TextStyle(
                                                color: AppTheme.textPrimary(
                                                    context),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Se quiser, você pode refazer o questionário.',
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
                                        child: const Text('Editar perfil'),
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
                                        child: const Text('Cancelar'),
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
                                        ? 'Calculando…'
                                        : 'Calcular perfil'),
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
                  'Seu plano de investimentos',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Editar plano'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Resumo r\u00e1pido do seu m\u00eas',
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
                  label: 'Aporte alvo',
                  value: monthlyTargetText,
                  icon: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: 'Alocar agora',
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
                  label: 'Perfil',
                  value: _riskLabel(risk),
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: 'Reserva',
                  value: emergencyText == '-' ? '-' : '$emergencyText meses',
                  icon: Icons.health_and_safety_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Aloca\u00e7\u00e3o escolhida',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (allocation == null || allocation.blocks.isEmpty)
            Text(
              'Aloca\u00e7\u00e3o ainda n\u00e3o definida.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            )
          else ...[
            Text(
              allocation.title,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...allocation.blocks.map((b) {
              final pct = (b.percent * 100).round();
              final amount =
                  selectedAmount > 0 ? selectedAmount * b.percent : 0.0;
              final amountText =
                  selectedAmount > 0 ? CurrencyUtils.format(amount) : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${b.label} ($pct%)',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      amountText,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(InvestmentProfile p) {
    final alloc = p.allocation;
    double pct(String key) =>
        ((alloc[key] ?? 0) * 100).clamp(0, 100).toDouble();

    String pctStr(String key) => '${pct(key).toStringAsFixed(0)}%';
    final baseAmount = parseMoneyInput(_amountController.text);
    String amountStr(String key) {
      if (baseAmount <= 0) return '';
      final share = (alloc[key] ?? 0) * baseAmount;
      return ' • ${CurrencyUtils.format(share)}';
    }

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
            'Seu perfil: ${_riskLabel(p.risk)}',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alocação sugerida (classes de ativos):',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _allocRow(
            'Renda fixa líquida',
            '${pctStr('fixedLiquid')}${amountStr('fixedLiquid')}',
          ),
          _allocRow(
            'Renda fixa longa',
            '${pctStr('fixedLong')}${amountStr('fixedLong')}',
          ),
          _allocRow(
            'Variável diversificada',
            '${pctStr('equity')}${amountStr('equity')}',
          ),
          _allocRow(
            'Maior risco',
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
            'Simular valor (opcional)',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Usamos esse valor apenas para exibir quanto vai para cada classe.',
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
            decoration: const InputDecoration(
              labelText: 'Aporte mensal (R\$)',
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
    const labels = [
      'Quanto tempo você pretende deixar o dinheiro investido?',
      'Como você reage a oscilações no curto prazo?',
      'Qual sua experiência com investimentos?',
      'Você tem reserva de emergência?',
      'Qual sua prioridade hoje?',
      'Se um investimento cair 10%, você…',
    ];
    const options = [
      ['Até 1 ano', '1–3 anos', '3+ anos'],
      ['Me incomoda', 'Depende', 'Tranquilo'],
      ['Nenhuma', 'Alguma', 'Boa'],
      ['Não', 'Parcial', 'Sim'],
      ['Segurança', 'Equilíbrio', 'Crescimento'],
      ['Vendo', 'Espero', 'Aporto mais'],
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
            labels[i],
            style: TextStyle(color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              3,
              (v) => ChoiceChip(
                label: Text(options[i][v]),
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
                  'Progresso',
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
