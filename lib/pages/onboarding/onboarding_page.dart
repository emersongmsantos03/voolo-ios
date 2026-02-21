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
  final PageController _controller = PageController();
  final professionController = TextEditingController();
  final List<Map<String, dynamic>> _incomeSources = [
    {
      'id': 'main_income',
      'label': 'Salario principal',
      'value': '',
    }
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
          });
        }
      } else if (_user!.monthlyIncome > 0) {
        _incomeSources[0]['value'] = formatMoneyInput(_user!.monthlyIncome);
      }
      _selectedObjectives.addAll(_user!.objectives);
    }

    if (_selectedObjectives.isEmpty && objectives.isNotEmpty) {
      _selectedObjectives
          .add(objectives.contains('save') ? 'save' : objectives.first);
    }
    if (_incomeSources.first['label'].toString().trim().isEmpty) {
      _incomeSources.first['label'] = 'Salario principal';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    professionController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next() {
    if (_step == 1 && _selectedObjectives.isEmpty) {
      _snack(
          'Escolha pelo menos um objetivo para comecar. Exemplo: Guardar dinheiro.');
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
    _controller.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _controller.animateToPage(
      _step,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
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

    final primaryAmount =
        parseMoneyInput(normalizedSources.first['value'].toString());
    final primaryIncome = IncomeSource(
      id: 'main_income',
      title: normalizedSources.first['label'].toString(),
      amount: primaryAmount,
      type: 'fixed',
      isPrimary: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final existingIncomes = LocalStorageService.getIncomes();
    for (final income
        in existingIncomes.where((i) => i.isPrimary && i.id != 'main_income')) {
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
      final extraIncome = IncomeSource(
        id: src['id'].toString(),
        title: src['label'].toString(),
        amount: parseMoneyInput(src['value'].toString()),
        type: 'fixed',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'onboarding_title')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr(context, 'onboarding_step_progress',
                      {'step': '${_step + 1}', 'total': '$_totalSteps'}),
                  style: TextStyle(color: AppTheme.textSecondary(context)),
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
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const _WelcomeStep(),
                _ObjectivesStep(
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
                ),
                _TextStep(
                  title: AppStrings.t(context, 'onboarding_profession_title'),
                  subtitle:
                      AppStrings.t(context, 'onboarding_profession_subtitle'),
                  controller: professionController,
                  label: AppStrings.t(context, 'onboarding_profession_label'),
                  hint: AppStrings.t(context, 'onboarding_profession_hint'),
                ),
                _IncomeStep(
                  incomeSources: _incomeSources,
                  onQuickValue: (value) {
                    setState(() {
                      _incomeSources[0]['value'] = formatMoneyInput(value);
                    });
                  },
                  onAdd: () {
                    setState(() {
                      _incomeSources.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': AppStrings.t(
                            context, 'onboarding_extra_income_label'),
                        'value': '',
                      });
                    });
                  },
                  onRemove: (id) {
                    setState(() {
                      _incomeSources.removeWhere((src) => src['id'] == id);
                    });
                  },
                  onChange: (id, field, val) {
                    setState(() {
                      final idx =
                          _incomeSources.indexWhere((src) => src['id'] == id);
                      if (idx >= 0) {
                        _incomeSources[idx][field] = val;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _saving ? null : _back,
                    child: Text(AppStrings.t(context, 'back')),
                  )
                else
                  const SizedBox(width: 80),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _step == 3
                              ? AppStrings.t(context, 'finish')
                              : AppStrings.t(context, 'continue'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  size: 64, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Vamos fazer juntos, passo a passo.',
            style: TextStyle(
                color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Agora voce responde 3 perguntas simples. Leva menos de 2 minutos.',
            style: TextStyle(
                color: AppTheme.textPrimary(context).withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 18),
          _realExample(context,
              'Exemplo real: quem ganha R\$ 2.500 e quer guardar R\$ 300 por mes.'),
          const SizedBox(height: 8),
          _realExample(context,
              'Com isso, o app ja monta sugestoes de proximos passos automaticamente.'),
        ],
      ),
    );
  }

  Widget _realExample(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child:
              Icon(Icons.check_circle_outline, size: 18, color: Colors.amber),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                TextStyle(color: AppTheme.textSecondary(context), height: 1.4),
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
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Qual objetivo voce quer focar agora?',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: Colors.amber,
                backgroundColor: const Color(0xFF1E1E1E),
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
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
    );
  }
}

class _IncomeStep extends StatelessWidget {
  final List<Map<String, dynamic>> incomeSources;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final void Function(String id, String field, String val) onChange;
  final void Function(double value) onQuickValue;

  const _IncomeStep({
    required this.incomeSources,
    required this.onAdd,
    required this.onRemove,
    required this.onChange,
    required this.onQuickValue,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = Responsive.width(context) < 430;
    double total = 0;
    for (final src in incomeSources) {
      total += parseMoneyInput(src['value'].toString());
    }

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Qual e sua renda mensal?',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
                  label: 'R\$ 2.000', onTap: () => onQuickValue(2000)),
              _QuickValueChip(
                  label: 'R\$ 3.000', onTap: () => onQuickValue(3000)),
              _QuickValueChip(
                  label: 'R\$ 5.000', onTap: () => onQuickValue(5000)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: incomeSources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final src = incomeSources[index];
                final label = src['label'].toString();
                final value = src['value'].toString();

                final labelField = TextField(
                  onChanged: (val) =>
                      onChange(src['id'].toString(), 'label', val),
                  decoration: InputDecoration(
                    hintText:
                        AppStrings.t(context, 'onboarding_income_source_hint'),
                    isDense: true,
                  ),
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: label,
                      selection: TextSelection.collapsed(offset: label.length),
                    ),
                  ),
                );

                final valueField = TextField(
                  onChanged: (val) =>
                      onChange(src['id'].toString(), 'value', val),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const <TextInputFormatter>[
                    MoneyTextInputFormatter()
                  ],
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: '0,00',
                    isDense: true,
                    prefixText: 'R\$ ',
                  ),
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: value,
                      selection: TextSelection.collapsed(offset: value.length),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      labelField,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: valueField),
                          if (incomeSources.length > 1)
                            IconButton(
                              onPressed: () => onRemove(src['id'].toString()),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                            ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: labelField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: valueField),
                    if (incomeSources.length > 1)
                      IconButton(
                        onPressed: () => onRemove(src['id'].toString()),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.t(context, 'onboarding_add_extra_income')),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
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
