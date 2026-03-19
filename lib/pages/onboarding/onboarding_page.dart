import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/catalogs/objectives_catalog.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/income_source.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/money_input.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  UserProfile? _user;
  final professionController = TextEditingController();
  final List<Map<String, dynamic>> _incomeSources = [
    {
      'id': 'main_income',
      'label': 'Salario principal',
      'value': '',
      'type': 'fixed',
    },
  ];
  final Set<String> _selectedObjectives = {};

  bool _saving = false;
  bool _showAllObjectives = false;
  int _step = 0;
  final int _totalSteps = 4;

  final objectives = ObjectivesCatalog.codes;

  @override
  void initState() {
    super.initState();
    _user = LocalStorageService.getUserProfile();
    if (_user != null) {
      professionController.text = _user!.profession;
      if (_user!.incomeSources.isNotEmpty) {
        _incomeSources.clear();
        for (final src in _user!.incomeSources) {
          _incomeSources.add({
            'id':
                (src['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
            'label': src['label'] ?? '',
            'value': src['value'].toString(),
            'type': (src['type'] ?? 'fixed').toString(),
          });
        }
      } else if (_user!.monthlyIncome > 0) {
        _incomeSources[0]['value'] = formatMoneyInput(_user!.monthlyIncome);
      }
      _selectedObjectives.addAll(_user!.objectives);
    }

    if (_selectedObjectives.isEmpty && objectives.isNotEmpty) {
      _selectedObjectives.add(
        objectives.contains('save') ? 'save' : objectives.first,
      );
    }
    if (_incomeSources.first['label'].toString().trim().isEmpty) {
      _incomeSources.first['label'] = 'Salario principal';
    }
  }

  @override
  void dispose() {
    professionController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _next() {
    if (_step == 1 && _selectedObjectives.isEmpty) {
      _snack(
        'Escolha pelo menos um objetivo para comecar. Exemplo: Guardar dinheiro.',
      );
      return;
    }
    if (_step == 2 && professionController.text.trim().isEmpty) {
      _snack(AppStrings.t(context, 'onboarding_profession_required_hint'));
      return;
    }
    if (_step == 3) {
      _save();
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  void _exitOnboarding() {
    final target = LocalStorageService.currentUserId == null
        ? AppRoutes.login
        : AppRoutes.dashboard;
    Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
  }

  void _handleBackAction() {
    if (_step > 0) {
      _back();
      return;
    }
    _exitOnboarding();
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return const _WelcomeStep(key: ValueKey('welcome_step'));
      case 1:
        return _ObjectivesStep(
          key: const ValueKey('objectives_step'),
          objectives: objectives,
          selected: _selectedObjectives,
          showAll: _showAllObjectives,
          onToggleShowAll: () {
            setState(() => _showAllObjectives = !_showAllObjectives);
          },
          onToggle: (code) {
            setState(() {
              if (_selectedObjectives.contains(code)) {
                _selectedObjectives.remove(code);
              } else {
                _selectedObjectives.add(code);
              }
            });
          },
        );
      case 2:
        return _TextStep(
          key: const ValueKey('profession_step'),
          title: AppStrings.t(context, 'onboarding_profession_title'),
          subtitle: AppStrings.t(
            context,
            'onboarding_profession_subtitle',
          ),
          controller: professionController,
          label: AppStrings.t(context, 'onboarding_profession_label'),
          hint: AppStrings.t(context, 'onboarding_profession_hint'),
        );
      case 3:
      default:
        return _IncomeStep(
          key: const ValueKey('income_step'),
          incomeSources: _incomeSources,
          onQuickValue: (value) {
            setState(() {
              _incomeSources[0]['value'] = formatMoneyInput(value);
            });
          },
          onAdd: () async {
            final data = await _openIncomeEditor(
              initialLabel: AppStrings.t(
                context,
                'onboarding_extra_income_label',
              ),
              initialType: 'fixed',
            );
            if (data == null) return;
            setState(() {
              _incomeSources.add({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'label': data['label'] ?? '',
                'value': data['value'] ?? '',
                'type': data['type'] ?? 'fixed',
              });
            });
          },
          onRemove: (id) {
            setState(() {
              _incomeSources.removeWhere((src) => src['id'] == id);
            });
          },
          onEdit: (id) async {
            final idx = _incomeSources.indexWhere((src) => src['id'] == id);
            if (idx < 0) return;
            final src = _incomeSources[idx];
            final data = await _openIncomeEditor(
              initialLabel: src['label'].toString(),
              initialValue: src['value'].toString(),
              initialType: (src['type'] ?? 'fixed').toString(),
              isPrimary: idx == 0,
            );
            if (data == null) return;
            setState(() {
              _incomeSources[idx]['label'] = data['label'] ?? '';
              _incomeSources[idx]['value'] = data['value'] ?? '';
              _incomeSources[idx]['type'] = data['type'] ?? 'fixed';
            });
          },
        );
    }
  }

  Future<Map<String, String>?> _openIncomeEditor({
    String initialLabel = '',
    String initialValue = '',
    String initialType = 'fixed',
    bool isPrimary = false,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomeInputSheet(
        initialLabel: initialLabel,
        initialValue: initialValue,
        initialType: initialType,
        isPrimary: isPrimary,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final profession = professionController.text.trim();

    final normalizedSources = <Map<String, dynamic>>[];
    double totalIncome = 0;
    for (var i = 0; i < _incomeSources.length; i++) {
      final src = _incomeSources[i];
      final amount = parseMoneyInput(src['value'].toString());
      if (amount <= 0) continue;
      totalIncome += amount;
      normalizedSources.add({
        'id': src['id'].toString(),
        'label': src['label'].toString().trim().isEmpty
            ? 'Renda ${i + 1}'
            : src['label'].toString().trim(),
        'value': formatMoneyInput(amount),
        'type': (src['type'] ?? 'fixed').toString(),
      });
    }

    if (_selectedObjectives.isEmpty) {
      _snack(AppStrings.t(context, 'onboarding_objective_required_hint'));
      setState(() => _saving = false);
      return;
    }
    if (profession.isEmpty) {
      _snack(AppStrings.t(context, 'onboarding_profession_required_hint'));
      setState(() => _saving = false);
      return;
    }
    if (totalIncome < 1) {
      _snack(AppStrings.t(context, 'onboarding_income_required_hint'));
      setState(() => _saving = false);
      return;
    }

    if (_user == null) {
      _snack(AppStrings.t(context, 'session_expired_login'));
      setState(() => _saving = false);
      return;
    }

    final primaryAmount = parseMoneyInput(
      normalizedSources.first['value'].toString(),
    );
    final currentMonthKey = _monthKey(DateTime.now());
    final primaryType = normalizedSources.first['type'].toString();
    final primaryIsVariable = primaryType == 'variable';
    final primaryIncome = IncomeSource(
      id: 'main_income',
      title: normalizedSources.first['label'].toString(),
      amount: primaryAmount,
      type: primaryType,
      activeFrom: primaryIsVariable ? currentMonthKey : null,
      activeUntil: primaryIsVariable ? currentMonthKey : null,
      isPrimary: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final existingIncomes = LocalStorageService.getIncomes();
    final normalizedIds =
        normalizedSources.map((src) => src['id'].toString()).toSet();

    for (final income in existingIncomes.where(
      (i) => !normalizedIds.contains(i.id) && !i.isPrimary,
    )) {
      final ok = await LocalStorageService.deleteIncome(income.id);
      if (!mounted) return;
      if (!ok) {
        _snack(AppStrings.t(context, 'save_failed_try_again'));
        setState(() => _saving = false);
        return;
      }
    }

    for (final income in existingIncomes.where(
      (i) => i.isPrimary && i.id != 'main_income',
    )) {
      final ok = await LocalStorageService.saveIncome(
        income.copyWith(isPrimary: false),
      );
      if (!mounted) return;
      if (!ok) {
        _snack(AppStrings.t(context, 'save_failed_try_again'));
        setState(() => _saving = false);
        return;
      }
    }

    final primaryOk = await LocalStorageService.saveIncome(primaryIncome);
    if (!mounted) return;
    if (!primaryOk) {
      _snack(AppStrings.t(context, 'save_failed_try_again'));
      setState(() => _saving = false);
      return;
    }

    for (var i = 1; i < normalizedSources.length; i++) {
      final src = normalizedSources[i];
      final type = src['type'].toString();
      final isVariable = type == 'variable';
      final extraIncome = IncomeSource(
        id: src['id'].toString(),
        title: src['label'].toString(),
        amount: parseMoneyInput(src['value'].toString()),
        type: type,
        activeFrom: isVariable ? currentMonthKey : null,
        activeUntil: isVariable ? currentMonthKey : null,
        isPrimary: false,
        isActive: true,
        createdAt: DateTime.now(),
      );
      final ok = await LocalStorageService.saveIncome(extraIncome);
      if (!mounted) return;
      if (!ok) {
        _snack(AppStrings.t(context, 'save_failed_try_again'));
        setState(() => _saving = false);
        return;
      }
    }

    final updated = UserProfile(
      firstName: _user!.firstName,
      lastName: _user!.lastName,
      email: _user!.email,
      password: _user!.password,
      birthDate: _user!.birthDate,
      profession: profession,
      monthlyIncome: totalIncome,
      incomeSources: normalizedSources,
      gender: _user!.gender,
      photoPath: _user!.photoPath,
      objectives: _selectedObjectives.toList(),
      setupCompleted: true,
      isPremium: _user!.isPremium,
      isActive: _user!.isActive,
      totalXp: _user!.totalXp,
      completedMissions: _user!.completedMissions,
      missionNotes: _user!.missionNotes,
      missionCompletionType: _user!.missionCompletionType,
      lastReportViewedAt: _user!.lastReportViewedAt,
      lastCalculatorOpenedAt: _user!.lastCalculatorOpenedAt,
    );

    final ok = await LocalStorageService.updateUserProfile(
      previous: _user!,
      updated: updated,
    );
    if (!mounted) return;

    if (!ok) {
      _snack(AppStrings.t(context, 'save_failed_try_again'));
      setState(() => _saving = false);
      return;
    }

    setState(() => _saving = false);
    if (!mounted) return;
    _snack(AppStrings.t(context, 'onboarding_success_next'));
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _handleBackAction,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          title: Text(AppStrings.t(context, 'onboarding_title')),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                scheme.surfaceContainerLow,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.premiumCardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr(context, 'onboarding_step_progress', {
                            'step': '${_step + 1}',
                            'total': '$_totalSteps',
                          }),
                          style:
                              TextStyle(color: AppTheme.textSecondary(context)),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_step + 1) / _totalSteps,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentStep(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.premiumCardDecoration(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _next,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _step == 3
                                        ? AppStrings.t(context, 'finish')
                                        : AppStrings.t(context, 'continue'),
                                  ),
                          ),
                        ),
                        if (_step > 0) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _saving ? null : _back,
                              child: Text(AppStrings.t(context, 'back')),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: Responsive.pagePadding(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.premiumCardDecoration(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.18),
                        scheme.primary.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 64,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Seu dinheiro com mais clareza desde o primeiro dia.',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Em menos de 2 minutos, o Voolo organiza sua base e personaliza metas, insights e alertas sem complicar o resto do app.',
                style: TextStyle(
                  color: AppTheme.textPrimary(context).withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    _realExample(
                      context,
                      'Voce informa renda, objetivo e rotina. O app separa melhor o que sai agora do que vai para a fatura.',
                    ),
                    const SizedBox(height: 10),
                    _realExample(
                      context,
                      'Isso reduz confusao entre debito e credito e melhora os proximos insights automaticamente.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _realExample(
                context,
                'Exemplo real: quem ganha R\$ 2.500 e quer guardar R\$ 300 por mes.',
              ),
              const SizedBox(height: 8),
              _realExample(
                context,
                'Com isso, o app ja monta sugestoes de proximos passos automaticamente.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _realExample(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppTheme.primaryGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ObjectivesStep extends StatelessWidget {
  final List<String> objectives;
  final Set<String> selected;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final void Function(String code) onToggle;

  const _ObjectivesStep({
    super.key,
    required this.objectives,
    required this.selected,
    required this.showAll,
    required this.onToggleShowAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final visible = showAll || objectives.length <= 4
        ? objectives
        : objectives.take(4).toList();

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.premiumCardDecoration(context),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Qual objetivo voce quer focar agora?',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Escolha 1 ou 2 opcoes para comecar. Voce pode mudar depois.',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: visible.map((code) {
                final isSelected = selected.contains(code);
                return FilterChip(
                  selected: isSelected,
                  label: Text(AppStrings.t(context, 'objective_$code')),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.10),
                  ),
                  onSelected: (_) => onToggle(code),
                );
              }).toList(),
            ),
            if (objectives.length > 4) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onToggleShowAll,
                child: Text(showAll ? 'Mostrar menos' : 'Mostrar mais opcoes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String label;
  final String hint;

  const _TextStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.pagePadding(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.premiumCardDecoration(context),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label, hintText: hint),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeStep extends StatelessWidget {
  final List<Map<String, dynamic>> incomeSources;
  final Future<void> Function() onAdd;
  final void Function(String id) onRemove;
  final Future<void> Function(String id) onEdit;
  final void Function(double value) onQuickValue;

  const _IncomeStep({
    super.key,
    required this.incomeSources,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
    required this.onQuickValue,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final src in incomeSources) {
      total += parseMoneyInput(src['value'].toString());
    }

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.premiumCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Qual e sua renda mensal?',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Comece com sua renda principal. Se quiser, adicione renda extra depois.',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _QuickValueChip(
                  label: 'R\$ 2.000',
                  onTap: () => onQuickValue(2000),
                ),
                _QuickValueChip(
                  label: 'R\$ 3.000',
                  onTap: () => onQuickValue(3000),
                ),
                _QuickValueChip(
                  label: 'R\$ 5.000',
                  onTap: () => onQuickValue(5000),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label:
                    Text(AppStrings.t(context, 'onboarding_add_extra_income')),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total estimado:',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  Text(
                    CurrencyUtils.format(total),
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: incomeSources.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final src = incomeSources[index];
                  final label = src['label'].toString();
                  final value = src['value'].toString();
                  final type = (src['type'] ?? 'fixed').toString();
                  final hasValue = parseMoneyInput(value) > 0;
                  final typeLabel = type == 'variable' ? 'Variavel' : 'Fixa';
                  return Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      onTap: () => onEdit(src['id'].toString()),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        child: Icon(
                          index == 0
                              ? Icons.star
                              : Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        label.trim().isEmpty ? 'Renda ${index + 1}' : label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        hasValue
                            ? '${CurrencyUtils.format(parseMoneyInput(value))} | $typeLabel'
                            : 'Toque para informar valor e tipo',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          if (incomeSources.length > 1 && index > 0) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => onRemove(src['id'].toString()),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeInputSheet extends StatefulWidget {
  final String initialLabel;
  final String initialValue;
  final String initialType;
  final bool isPrimary;

  const _IncomeInputSheet({
    required this.initialLabel,
    required this.initialValue,
    required this.initialType,
    required this.isPrimary,
  });

  @override
  State<_IncomeInputSheet> createState() => _IncomeInputSheetState();
}

class _IncomeInputSheetState extends State<_IncomeInputSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _valueController;
  late String _type;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _valueController = TextEditingController(text: widget.initialValue);
    _type = widget.initialType == 'variable' ? 'variable' : 'fixed';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = parseMoneyInput(_valueController.text);
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero.')),
      );
      return;
    }
    final label = _labelController.text.trim().isEmpty
        ? (widget.isPrimary ? 'Salario principal' : 'Renda extra')
        : _labelController.text.trim();

    Navigator.of(
      context,
    ).pop({'label': label, 'value': formatMoneyInput(value), 'type': _type});
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final isFixed = _type == 'fixed';
    final infoBg = isFixed
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);
    final infoBorder = isFixed
        ? Colors.green.withValues(alpha: 0.35)
        : Colors.orange.withValues(alpha: 0.35);
    final infoIcon = isFixed ? Icons.event_repeat : Icons.calendar_month;
    final infoTitle = isFixed ? 'Renda Fixa' : 'Renda Variavel';
    final infoText = isFixed
        ? 'Esta renda sera replicada automaticamente para os proximos meses.'
        : 'Esta renda sera considerada somente no mes atual.';
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF151515),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isPrimary ? 'Renda principal' : 'Nova renda',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nome da renda',
                  hintText: AppStrings.t(
                    context,
                    'onboarding_income_source_hint',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _valueController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const <TextInputFormatter>[
                  MoneyTextInputFormatter(),
                ],
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Valor mensal',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tipo da renda',
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'fixed',
                    icon: Icon(Icons.lock_outline),
                    label: Text('Fixa'),
                  ),
                  ButtonSegment<String>(
                    value: 'variable',
                    icon: Icon(Icons.show_chart),
                    label: Text('Variavel'),
                  ),
                ],
                selected: <String>{_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey<String>(_type),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: infoBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: infoBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(infoIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              infoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              infoText,
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
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
                  onPressed: _submit,
                  child: const Text('Salvar renda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickValueChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickValueChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.auto_awesome, size: 16),
    );
  }
}
