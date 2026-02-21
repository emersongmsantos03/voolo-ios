import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/core/theme/app_theme.dart';
import 'package:jetx/core/ui/formatters/money_text_input_formatter.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/core/utils/currency_utils.dart';
import 'package:jetx/core/utils/money_input.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/widgets/premium_gate.dart';
import 'package:jetx/widgets/premium_tour_widgets.dart';

class InvestmentCalculatorPage extends StatefulWidget {
  const InvestmentCalculatorPage({super.key});

  @override
  State<InvestmentCalculatorPage> createState() =>
      _InvestmentCalculatorPageState();
}

class _InvestmentCalculatorPageState extends State<InvestmentCalculatorPage> {
  final contributionController = TextEditingController(text: '500');
  final rateController = TextEditingController(text: '12');
  late final VoidCallback _userListener;
  bool _tourMode = false;
  int _years = 10;

  @override
  void initState() {
    super.initState();
    _userListener = () {
      if (mounted) setState(() {});
    };
    LocalStorageService.userNotifier.addListener(_userListener);
    final user = LocalStorageService.getUserProfile();
    if (user != null && user.isPremium) {
      LocalStorageService.markCalculatorOpened();
    }
  }

  @override
  void dispose() {
    LocalStorageService.userNotifier.removeListener(_userListener);
    contributionController.dispose();
    rateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final enable = args is Map &&
        args['premiumTour'] == true &&
        args['tourStep'] == 'calculator';
    if (enable != _tourMode) {
      setState(() => _tourMode = enable);
    }
  }

  double get _contribution => parseMoneyInput(contributionController.text);
  double get _rate =>
      double.tryParse(rateController.text.replaceAll(',', '.')) ?? 0;

  List<_ProjectionPoint> _buildProjection() {
    final monthly = _contribution <= 0 ? 0 : _contribution;
    final annual = _rate <= 0 ? 0 : _rate;
    final monthlyRate = annual / 100 / 12;
    final months = _years * 12;

    double total = 0;
    double invested = 0;
    final points = <_ProjectionPoint>[
      const _ProjectionPoint(year: 0, total: 0, invested: 0)
    ];

    for (var month = 1; month <= months; month++) {
      total = (total + monthly) * (1 + monthlyRate);
      invested += monthly;

      final isTick = month % 12 == 0 || month == months;
      if (isTick) {
        points.add(
          _ProjectionPoint(
            year: month ~/ 12,
            total: total,
            invested: invested,
          ),
        );
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalStorageService.getUserProfile();
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppStrings.t(context, 'login_required_calculator'),
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    if (!user.isPremium) {
      return Scaffold(
        appBar:
            AppBar(title: Text(AppStrings.t(context, 'investment_calculator'))),
        body: PremiumGate(
          title: AppStrings.t(context, 'premium_calc_title'),
          subtitle: AppStrings.t(context, 'premium_calc_subtitle'),
          perks: const [],
        ),
      );
    }

    final invalid = _contribution <= 0 || _rate <= 0 || _years <= 0;
    final points = invalid ? const <_ProjectionPoint>[] : _buildProjection();
    final last = points.isEmpty ? null : points.last;
    final total = last?.total ?? 0;
    final invested = last?.invested ?? 0;
    final profit = total - invested;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'calc_title')),
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: PremiumTourOverlay(
          active: _tourMode,
          spotlight: PremiumTourSpotlight(
            icon: Icons.calculate_rounded,
            title: AppStrings.t(context, 'premium_tour_calculator_title'),
            body: AppStrings.t(context, 'premium_tour_calculator_body'),
            location: AppStrings.t(context, 'premium_tour_calculator_location'),
            tip: AppStrings.t(context, 'premium_tour_calculator_tip'),
          ),
          child: ListView(
            children: [
              Text(
                AppStrings.t(context, 'calc_subtitle'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 18),
              PremiumTourHighlight(
                active: _tourMode,
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: contributionController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: const [MoneyTextInputFormatter()],
                        decoration: InputDecoration(
                          labelText:
                              AppStrings.t(context, 'monthly_contribution'),
                          hintText: 'Ex: 500',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppStrings.t(context, 'annual_rate'),
                          hintText: 'Ex: 12',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.t(context, 'period_years'),
                        style:
                            TextStyle(color: AppTheme.textSecondary(context)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [5, 10, 20, 30]
                            .map(
                              (y) => OutlinedButton(
                                onPressed: () => setState(() => _years = y),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _years == y
                                      ? AppTheme.primary(context)
                                          .withOpacity(0.12)
                                      : null,
                                  side: BorderSide(
                                    color: _years == y
                                        ? AppTheme.primary(context)
                                        : Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.6),
                                  ),
                                ),
                                child: Text('$y'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.t(context, 'calc_disclaimer'),
                              style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _summaryCard(
                context: context,
                total: total,
                invested: invested,
                profit: profit,
                invalid: invalid,
              ),
              const SizedBox(height: 18),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'equity_evolution'),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: invalid
                          ? Center(
                              child: Text(
                                AppStrings.t(
                                    context, 'investment_invalid_inputs'),
                                style: TextStyle(
                                    color: AppTheme.textMuted(context)),
                              ),
                            )
                          : _projectionChart(context, points),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _legendDot(color: AppTheme.primary(context)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                AppStrings.t(context, 'total_with_interest'))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _legendDot(color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                AppStrings.t(context, 'invested_capital'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required double total,
    required double invested,
    required double profit,
    required bool invalid,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final gradient = LinearGradient(
      colors: isLight
          ? const [AppTheme.gold, AppTheme.yellow]
          : const [AppTheme.gold, Color(0xFF00A67E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'final_total'),
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            invalid ? '—' : CurrencyUtils.format(total),
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              color: (isLight ? Colors.black : Colors.white).withOpacity(0.2)),
          const SizedBox(height: 12),
          _summaryRow(
            label: AppStrings.t(context, 'total_invested'),
            value: invalid ? '—' : CurrencyUtils.format(invested),
            isLight: isLight,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            label: AppStrings.t(context, 'profit'),
            value: invalid ? '—' : CurrencyUtils.format(profit),
            isLight: isLight,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required bool isLight,
  }) {
    final color = isLight ? Colors.black : Colors.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.85))),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _legendDot({required Color color}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _projectionChart(BuildContext context, List<_ProjectionPoint> points) {
    final totalMax = points.fold<double>(0, (m, p) => math.max(m, p.total));
    final investedMax =
        points.fold<double>(0, (m, p) => math.max(m, p.invested));
    final maxY = math.max(totalMax, investedMax) * 1.12;

    final totalSpots =
        points.map((p) => FlSpot(p.year.toDouble(), p.total)).toList();
    final investedSpots =
        points.map((p) => FlSpot(p.year.toDouble(), p.invested)).toList();

    final axisTextStyle =
        TextStyle(color: AppTheme.textMuted(context), fontSize: 11);

    String formatCompactCurrency(double v) {
      if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
      return 'R\$ ${v.toStringAsFixed(0)}';
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.isEmpty ? 0 : points.last.year.toDouble(),
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                final last = points.isEmpty ? 0 : points.last.year;
                if (i < 0 || i > last) return const SizedBox.shrink();
                if (i % 5 != 0 && i != last) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${AppStrings.t(context, 'year_label')} $i',
                      style: axisTextStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) =>
                  Text(formatCompactCurrency(value), style: axisTextStyle),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface,
            tooltipBorder: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
            getTooltipItems: (spots) {
              return spots.map((s) {
                final label = s.barIndex == 0
                    ? AppStrings.t(context, 'total_with_interest')
                    : AppStrings.t(context, 'invested_capital');
                return LineTooltipItem(
                  '$label\n${CurrencyUtils.format(s.y)}',
                  TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w600),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: totalSpots,
            color: AppTheme.primary(context),
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary(context).withOpacity(0.25),
                  AppTheme.primary(context).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: investedSpots,
            color: AppTheme.textSecondary(context),
            isCurved: true,
            barWidth: 2,
            dashArray: [6, 6],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }
}

class _ProjectionPoint {
  final int year;
  final double total;
  final double invested;

  const _ProjectionPoint({
    required this.year,
    required this.total,
    required this.invested,
  });
}
