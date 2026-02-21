import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../utils/currency_utils.dart';

typedef ApplyBudgetFn = Future<void> Function(
  String categoryKey,
  double value,
  bool replicateFuture,
);

class SuggestBudgetsDialog extends StatefulWidget {
  const SuggestBudgetsDialog({
    super.key,
    required this.uid,
    required this.monthYear,
    required this.suggestions,
    required this.source,
    required this.applyBudget,
    this.error,
  });

  final String uid;
  final String monthYear;
  final Map<String, double> suggestions;
  final String source;
  final String? error;
  final ApplyBudgetFn applyBudget;

  @override
  State<SuggestBudgetsDialog> createState() => _SuggestBudgetsDialogState();
}

class _SuggestBudgetsDialogState extends State<SuggestBudgetsDialog> {
  static const List<String> _categoryKeys = [
    'MORADIA',
    'ALIMENTACAO',
    'TRANSPORTE',
    'EDUCACAO',
    'SAUDE',
    'LAZER',
    'ASSINATURAS',
    'OUTROS',
  ];

  final Map<String, bool> _apply = {};
  final Map<String, bool> _replicate = {};
  bool _saving = false;

  String _categoryLabel(String key) {
    switch (key) {
      case 'MORADIA':
        return 'Moradia';
      case 'ALIMENTACAO':
        return 'Alimentação';
      case 'TRANSPORTE':
        return 'Transporte';
      case 'EDUCACAO':
        return 'Educação';
      case 'SAUDE':
        return 'Saúde';
      case 'LAZER':
        return 'Lazer';
      case 'ASSINATURAS':
        return 'Assinaturas';
      default:
        return 'Outros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = <String, double>{};
    for (final k in _categoryKeys) {
      final v = widget.suggestions[k];
      if (v == null) continue;
      if (!v.isFinite || v <= 0) continue;
      suggestions[k] = v;
    }

    return AlertDialog(
      title: const Text('Aplicar sugestões'),
      content: SizedBox(
        width: 480,
        child: suggestions.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.error != null && widget.error!.isNotEmpty) ...[
                    Text(
                      'Não consegui buscar sugestões do servidor.',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.error!,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Nenhuma sugestão disponível para este mês ainda.',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dica: registre renda e algumas despesas e tente novamente.',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final key = suggestions.keys.elementAt(i);
                  final value = suggestions[key] ?? 0.0;
                  _apply.putIfAbsent(key, () => true);
                  _replicate.putIfAbsent(key, () => false);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _categoryLabel(key),
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyUtils.format(value),
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Pode colocar'),
                          subtitle: const Text('Define o limite no mês atual.'),
                          value: _apply[key] ?? true,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                    _apply[key] = v ?? false;
                                    if (_apply[key] != true) {
                                      _replicate[key] = false;
                                    }
                                  }),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title:
                              const Text('Pode colocar para os próximos meses'),
                          subtitle: const Text('Replica o limite (até 12 meses).'),
                          value: _replicate[key] ?? false,
                          onChanged: (_saving || _apply[key] != true)
                              ? null
                              : (v) => setState(() {
                                    _replicate[key] = v ?? false;
                                  }),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_saving || suggestions.isEmpty)
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    for (final entry in _apply.entries) {
                      if (entry.value != true) continue;
                      final categoryKey = entry.key;
                      final replicateFuture = _replicate[categoryKey] == true;
                      final value =
                          (suggestions[categoryKey] ?? 0).toDouble();
                      if (value <= 0) continue;
                      await widget.applyBudget(
                        categoryKey,
                        value,
                        replicateFuture,
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: Text(_saving ? 'Aplicando…' : 'Aplicar'),
        ),
      ],
    );
  }
}
