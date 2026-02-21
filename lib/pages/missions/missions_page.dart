import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/gamification/gamification.dart';
import '../../core/gamification/mission_engine.dart';
import '../../core/gamification/mission_progress.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/responsive.dart';
import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../core/plans/user_plan.dart';
import '../../routes/app_routes.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/premium_tour_widgets.dart';

bool _looksMojibake(String value) {
  return value.contains('Ã') ||
      value.contains('Â') ||
      value.contains('â') ||
      value.contains('�');
}

String _fixMojibakeIfNeeded(String value) {
  if (!_looksMojibake(value)) return value;
  try {
    return utf8.decode(latin1.encode(value));
  } catch (_) {
    const cp1252ToByte = <int, int>{
      0x20AC: 0x80, // €
      0x201A: 0x82, // ‚
      0x0192: 0x83, // ƒ
      0x201E: 0x84, // „
      0x2026: 0x85, // …
      0x2020: 0x86, // †
      0x2021: 0x87, // ‡
      0x02C6: 0x88, // ˆ
      0x2030: 0x89, // ‰
      0x0160: 0x8A, // Š
      0x2039: 0x8B, // ‹
      0x0152: 0x8C, // Œ
      0x017D: 0x8E, // Ž
      0x2018: 0x91, // ‘
      0x2019: 0x92, // ’
      0x201C: 0x93, // “
      0x201D: 0x94, // ”
      0x2022: 0x95, // •
      0x2013: 0x96, // –
      0x2014: 0x97, // —
      0x02DC: 0x98, // ˜
      0x2122: 0x99, // ™
      0x0161: 0x9A, // š
      0x203A: 0x9B, // ›
      0x0153: 0x9C, // œ
      0x017E: 0x9E, // ž
      0x0178: 0x9F, // Ÿ
    };
    try {
      final bytes = <int>[];
      for (final rune in value.runes) {
        if (rune <= 0xFF) {
          bytes.add(rune);
          continue;
        }
        final mapped = cp1252ToByte[rune];
        if (mapped == null) return value;
        bytes.add(mapped);
      }
      return utf8.decode(bytes);
    } catch (_) {
      return value;
    }
  }
}

class _FixedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const _FixedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _fixMojibakeIfNeeded(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

AppBar _missionsAppBar(BuildContext context) {
  final canPop = Navigator.of(context).canPop();
  return AppBar(
    automaticallyImplyLeading: canPop,
    leading: canPop
        ? null
        : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (route) => false,
              );
            },
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
    title: _FixedText(AppStrings.t(context, 'missions')),
  );
}

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  UserProfile? _user;
  List<_MissionView> _monthly = [];
  List<_MissionView> _weekly = [];
  List<_MissionView> _daily = [];
  String? _missionsCatalogMessage;
  final Set<String> _autoClaimed = {};
  late final VoidCallback _userListener;
  bool _tourMode = false;
  FinancialLevel? _currentLevel;
  int _minXp = 0;
  int _maxXp = 1000;
  double _progress = 0.0;
  late final VoidCallback _goalsListener;

  // Minimal fallback catalog matching Web's Missions.js defaults.
  static const _defaultMissions = <Mission>[
    // Daily (need at least 1)
    Mission(
      code: 'daily_log_expense',
      title: 'Registre um gasto',
      desc: 'Mantenha seu registro em dia.',
      xp: 15,
      type: 'daily',
      minLevel: 1,
      category: 'habit',
    ),
    Mission(
      code: 'daily_review_expense',
      title: 'Revise 1 gasto',
      desc: 'Confira se o valor está correto.',
      xp: 10,
      type: 'daily',
      minLevel: 1,
      category: 'curiosity',
    ),
    Mission(
      code: 'daily_check_balance',
      title: 'Cheque seu saldo',
      desc: 'Veja quanto ainda tem para gastar no mês.',
      xp: 10,
      type: 'daily',
      minLevel: 1,
      category: 'awareness',
    ),
    Mission(
      code: 'daily_balance_repair',
      title: 'Ajuste o mês',
      desc: 'Saldo negativo? Ajuste para o azul.',
      xp: 20,
      type: 'daily',
      minLevel: 1,
      category: 'recovery',
    ),

    // Weekly (need at least 2)
    Mission(
      code: 'weekly_budget',
      title: 'Foco no Orçamento',
      desc: 'Registre gastos em 3 dias da semana.',
      xp: 40,
      type: 'weekly',
      minLevel: 1,
      category: 'consistency',
    ),
    Mission(
      code: 'weekly_category_review',
      title: 'Revisão por Categoria',
      desc: 'Descubra qual categoria consumiu mais.',
      xp: 35,
      type: 'weekly',
      minLevel: 1,
      category: 'discovery',
    ),
    Mission(
      code: 'weekly_receipt_cleanup',
      title: 'Organização da Semana',
      desc: 'Organize comprovantes e gastos da semana.',
      xp: 30,
      type: 'weekly',
      minLevel: 1,
      category: 'organization',
    ),

    // Monthly (need at least 2)
    Mission(
      code: 'monthly_simple_plan',
      title: 'Defina um Plano',
      desc: 'Crie seu plano de gastos do mês.',
      xp: 120,
      type: 'monthly',
      minLevel: 1,
      category: 'planning',
    ),
    Mission(
      code: 'monthly_savings_goal',
      title: 'Meta de Poupança',
      desc: 'Poupe pelo menos 5% da renda.',
      xp: 150,
      type: 'monthly',
      minLevel: 1,
      category: 'habit',
    ),
    Mission(
      code: 'monthly_fixed_bill_check',
      title: 'Giro de Contas Fixas',
      desc: 'Verifique suas contas fixas do mês.',
      xp: 100,
      type: 'monthly',
      minLevel: 1,
      category: 'control',
    ),
    Mission(
      code: 'monthly_budget_limits',
      title: 'Crie seus Orçamentos',
      desc: 'Defina limites por categoria e acompanhe o progresso.',
      xp: 130,
      type: 'monthly',
      minLevel: 1,
      category: 'budget',
      criteria: {'kind': 'budgets_defined'},
    ),
    Mission(
      code: 'monthly_invest_profile',
      title: 'Descubra seu Perfil de Risco',
      desc: 'Responda ao questionário e veja a alocação sugerida.',
      xp: 90,
      type: 'monthly',
      minLevel: 1,
      category: 'investment',
      criteria: {'kind': 'investment_profile_set'},
    ),
    Mission(
      code: 'monthly_debt_plan',
      title: 'Plano para Sair das Dívidas',
      desc: 'Cadastre dívidas e gere um plano de quitação.',
      xp: 150,
      type: 'monthly',
      minLevel: 1,
      category: 'debt',
      criteria: {'kind': 'debt_plan_generated'},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _userListener = () {
      if (mounted) _load();
    };
    LocalStorageService.userNotifier.addListener(_userListener);
    _goalsListener = () {
      if (mounted) _load();
    };
    LocalStorageService.goalNotifier.addListener(_goalsListener);
    _load();
  }

  @override
  void dispose() {
    LocalStorageService.userNotifier.removeListener(_userListener);
    LocalStorageService.goalNotifier.removeListener(_goalsListener);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final enable = args is Map &&
        args['premiumTour'] == true &&
        args['tourStep'] == 'missions';
    if (enable != _tourMode) {
      setState(() => _tourMode = enable);
    }
  }

  Future<void> _autoClaimCompletedAutoMissions(List<_MissionView> views) async {
    final user = _user;
    final uid = LocalStorageService.currentUserId;
    if (user == null || uid == null) return;

    bool changed = false;

    for (final view in views) {
      if (view.mission.completionMode != 'auto') continue;
      if (!view.progress.completed) continue;
      if (view.completed) continue;
      if (_autoClaimed.contains(view.id)) continue;
      _autoClaimed.add(view.id);

      final ok = await FirestoreService.addXp(
        uid,
        view.mission.xp,
        view.id,
        completionType: 'auto',
      );

      if (!ok) {
        _autoClaimed.remove(view.id);
        continue;
      }

      if (!user.completedMissions.contains(view.id)) {
        user.completedMissions.add(view.id);
        user.totalXp += view.mission.xp;
        user.missionCompletionType[view.id] = 'auto';
        changed = true;
      }

      view.completed = true;
    }

    if (changed) {
      await LocalStorageService.saveUserProfile(user);
    }
  }

  Future<void> _load() async {
    _user = LocalStorageService.getUserProfile();
    if (_user == null || !_user!.isPremium) {
      if (mounted) setState(() {});
      return;
    }

    // Fetch missions from Firestore (global catalog). This is the single source of truth for Web + Flutter.
    List<Mission> dbMissions = const [];
    try {
      final rawMissions = await FirestoreService.getMissions();
      dbMissions = rawMissions
          .map((m) => Mission.fromJson(m))
          .where((m) => m.code.isNotEmpty && m.type.isNotEmpty)
          .toList();
      _missionsCatalogMessage = null;
    } catch (e) {
      debugPrint('MissionsPage: Error fetching missions: $e');
      dbMissions = const [];
      _missionsCatalogMessage =
          'Não foi possível carregar o catálogo de missões do servidor (/missions). Verifique se está no mesmo Firebase project e se as regras permitem leitura.';
    }

    if (dbMissions.isEmpty) {
      _missionsCatalogMessage ??=
          'Catálogo de missões vazio em Firestore (/missions). Rode o seed para sincronizar Web + Flutter.';
    }

    final userLevel = GamificationEngine.currentLevel(
      xp: _user!.totalXp,
      isPremium: _user!.isPremium,
    ).level;

    final now = DateTime.now();
    final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonth = DateTime(now.year, now.month, 1);

    final currentExpenses = await LocalStorageService.watchTransactions(
      currentMonth.month,
      currentMonth.year,
    ).first;

    final baseDashboard = LocalStorageService.getDashboard(
      currentMonth.month,
      currentMonth.year,
    );
    final salary = baseDashboard?.salary ?? _user!.monthlyIncome;
    final dashboard = MonthlyDashboard(
      month: currentMonth.month,
      year: currentMonth.year,
      salary: salary,
      expenses: currentExpenses,
      creditCardPayments: baseDashboard?.creditCardPayments ?? const {},
    );

    _currentLevel = GamificationEngine.currentLevel(
      xp: _user!.totalXp,
      isPremium: _user!.isPremium,
    );
    final nextLevel = GamificationEngine.nextLevel(
      xp: _user!.totalXp,
      isPremium: _user!.isPremium,
    );
    _minXp = _currentLevel!.minXp;
    _maxXp = nextLevel?.minXp ?? (_currentLevel!.minXp + 1000);
    _progress = ((_user!.totalXp - _minXp) / (_maxXp - _minXp)).clamp(0.0, 1.0);

    final goals = LocalStorageService.getGoals();

    final uid = LocalStorageService.currentUserId;
    bool budgetsDefinedThisMonth = false;
    bool investmentProfileSet = false;
    bool debtPlanGeneratedThisMonth = false;

    if (uid != null) {
      try {
        final results = await Future.wait([
          FirestoreService.watchBudgets(uid, monthYear).first,
          FirestoreService.watchInvestmentProfile(uid).first,
          FirestoreService.hasDebtPlanForMonth(uid, monthYear),
        ]);

        final budgets = results[0] as List;
        budgetsDefinedThisMonth =
            budgets.any((b) => (b as dynamic).limitAmount > 0);

        investmentProfileSet = results[1] != null;

        debtPlanGeneratedThisMonth = results[2] == true;
      } catch (e) {
        debugPrint('MissionsPage: error loading advanced module flags: $e');
      }
    }
    final ctx = MissionEngineContext(
      today: now,
      user: _user!,
      dashboard: dashboard,
      expenses: currentExpenses,
      goals: goals,
      budgetsDefinedThisMonth: budgetsDefinedThisMonth,
      investmentProfileSet: investmentProfileSet,
      debtPlanGeneratedThisMonth: debtPlanGeneratedThisMonth,
    );

    final rotatedV2 = MissionEngine.selectRotated(
      defaults: const [],
      dbMissions: dbMissions,
      ctx: ctx,
      userLevel: userLevel,
      dailyCount: 1,
      weeklyCount: 2,
      monthlyCount: 2,
    );

    _daily = rotatedV2.daily
        .map(
          (m) => _MissionView(
            mission: m,
            id: MissionEngine.missionIdFor(m, now),
            completed: _user?.completedMissions
                    .contains(MissionEngine.missionIdFor(m, now)) ??
                false,
            progress: MissionEngine.progressFor(m, ctx),
          ),
        )
        .toList();
    _weekly = rotatedV2.weekly
        .map(
          (m) => _MissionView(
            mission: m,
            id: MissionEngine.missionIdFor(m, now),
            completed: _user?.completedMissions
                    .contains(MissionEngine.missionIdFor(m, now)) ??
                false,
            progress: MissionEngine.progressFor(m, ctx),
          ),
        )
        .toList();
    _monthly = rotatedV2.monthly
        .map(
          (m) => _MissionView(
            mission: m,
            id: MissionEngine.missionIdFor(m, now),
            completed: _user?.completedMissions
                    .contains(MissionEngine.missionIdFor(m, now)) ??
                false,
            progress: MissionEngine.progressFor(m, ctx),
          ),
        )
        .toList();

    await _autoClaimCompletedAutoMissions([..._daily, ..._weekly, ..._monthly]);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: _missionsAppBar(context),
        body: Center(
          child: _FixedText(
            AppStrings.t(context, 'login_required_missions'),
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    final isPremium = !UserPlan.isFeatureLocked(_user, 'missions');
    final content = _MissionsBody(
      monthly: _monthly,
      weekly: _weekly,
      daily: _daily,
      catalogMessage: _missionsCatalogMessage,
      onComplete: _completeMission,
      tourMode: _tourMode,
      userLevel: _currentLevel?.level ?? 1,
      userXp: _user!.totalXp,
      minXp: _minXp,
      maxXp: _maxXp,
      progress: _progress,
    );

    return Scaffold(
      appBar: _missionsAppBar(context),
      body: PremiumGate(
        isPremium: isPremium,
        title: AppStrings.t(context, 'missions_premium_title'),
        subtitle: AppStrings.t(context, 'missions_premium_subtitle'),
        perks: [
          AppStrings.t(context, 'missions_premium_perk1'),
          AppStrings.t(context, 'missions_premium_perk2'),
          AppStrings.t(context, 'missions_premium_perk3'),
        ],
        child: content,
      ),
    );
  }

  Future<void> _completeMission(_MissionView view) async {
    if (_user == null) return;
    if (view.completed) return;
    if (view.mission.completionMode == 'auto') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missão automática: concluída por ações no app.')),
      );
      return;
    }

    final user = _user!;
    final uid = LocalStorageService.currentUserId;

    Future<void> completeWith({String? note}) async {
      if (uid == null) return;

      final ok = await FirestoreService.addXp(
        uid,
        view.mission.xp,
        view.id,
        note: note,
        completionType: view.mission.completionMode,
      );

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir agora.')),
        );
        return;
      }

      if (!user.completedMissions.contains(view.id)) {
        user.completedMissions.add(view.id);
        user.totalXp += view.mission.xp;
        if (note != null && note.trim().isNotEmpty) {
          user.missionNotes[view.id] = note.trim();
          user.missionCompletionType[view.id] = 'note';
        } else {
          user.missionCompletionType[view.id] = view.mission.completionMode;
        }
      }
      await LocalStorageService.saveUserProfile(user);
      _load();
    }

    if (view.mission.completionMode == 'note') {
      final controller = TextEditingController();
      final minChars = view.mission.noteMinChars ?? 80;
      final note = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: _FixedText(view.mission.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((view.mission.notePrompt ?? '').trim().isNotEmpty) ...[
                Text(
                  view.mission.notePrompt!,
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Escreva aqui...',
                  helperText: 'Mínimo: $minChars caracteres',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.t(context, 'close')),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.length < minChars) return;
                Navigator.pop(context, text);
              },
              child: const Text('Concluir'),
            ),
          ],
        ),
      );
      if (note == null) return;
      await completeWith(note: note);
      return;
    }

    await completeWith();
  }
}

class _MissionsBody extends StatelessWidget {
  final List<_MissionView> monthly;
  final List<_MissionView> weekly;
  final List<_MissionView> daily;
  final String? catalogMessage;
  final Future<void> Function(_MissionView view) onComplete;
  final bool tourMode;
  final int userLevel;
  final int userXp;
  final int minXp;
  final int maxXp;
  final double progress;

  const _MissionsBody({
    required this.monthly,
    required this.weekly,
    required this.daily,
    this.catalogMessage,
    required this.onComplete,
    required this.tourMode,
    required this.userLevel,
    required this.userXp,
    required this.minXp,
    required this.maxXp,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTourOverlay(
      active: tourMode,
      spotlight: PremiumTourSpotlight(
        icon: Icons.auto_awesome_rounded,
        title: AppStrings.t(context, 'premium_tour_missions_title'),
        body: AppStrings.t(context, 'premium_tour_missions_body'),
        location: AppStrings.t(context, 'premium_tour_missions_location'),
        tip: AppStrings.t(context, 'premium_tour_missions_tip'),
      ),
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: ListView(
            children: [
              _FixedText(
                AppStrings.t(context, 'missions_tagline'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              if (catalogMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  catalogMessage!,
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // --- XP DASHBOARD (Web Style) ---
              Container(
                padding: Responsive.pagePadding(context),
                decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$userXp',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FixedText(
                                AppStrings.t(context, 'xp_total'),
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37),
                              const Color(0xFFa855f7)
                            ], // var(--primary) to purple
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            _FixedText(
                              'Nível $userLevel',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$minXp XP',
                              style: TextStyle(
                                  color: AppTheme.textMuted(context),
                                  fontSize: 12)),
                          Text('$maxXp XP',
                              style: TextStyle(
                                  color: AppTheme.textMuted(context),
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              const Color(0xFF33C587)), // Success Green
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FixedText(
                        'Faltam ${maxXp - userXp} XP para Nível ${userLevel + 1}',
                        style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- MISSIONS LIST ---
            PremiumTourHighlight(
              active: tourMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'missions_month').toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...monthly.map(
                    (m) => _MissionTile(
                      view: m,
                      onComplete: onComplete,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.t(context, 'missions_week').toUpperCase(),
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...weekly.map((m) => _MissionTile(view: m, onComplete: onComplete)),
            const SizedBox(height: 24),
            Text(
              AppStrings.t(context, 'missions_day').toUpperCase(),
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...daily.map((m) => _MissionTile(view: m, onComplete: onComplete)),
          ],
        ),
      ),
    );
  }
}

class _MissionView {
  final Mission mission;
  final String id;
  bool completed;
  final MissionProgress progress;

  _MissionView({
    required this.mission,
    required this.id,
    required this.completed,
    required this.progress,
  });
}

class _MissionTile extends StatelessWidget {
  final _MissionView view;
  final Future<void> Function(_MissionView view) onComplete;

  const _MissionTile({
    required this.view,
    required this.onComplete,
  });

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
                child: _FixedText(view.mission.title,
                    style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: _FixedText(
          view.mission.desc,
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.t(context, 'close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = view.completed
        ? const Color(0xFF10b981).withOpacity(0.05)
        : const Color(0xFF1e1b4b).withOpacity(0.6);
    final borderColor = view.completed
        ? const Color(0xFF10b981).withOpacity(0.2)
        : Colors.white.withOpacity(0.08);

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                view.completed ? Icons.check_circle : Icons.bolt,
                color: view.completed ? const Color(0xFF33C587) : Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          view.mission.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${view.mission.xp} XP',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    view.mission.desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _progressLabel(view),
                    style: TextStyle(
                      color: AppTheme.textMuted(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Action/Status
            if (view.completed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Concluída',
                    style: TextStyle(
                      color: Color(0xFF33C587),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle,
                      color: Color(0xFF33C587), size: 16),
                ],
              )
            else if (view.mission.completionMode == 'auto')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppTheme.textMuted(context)),
                  const SizedBox(width: 6),
                  Text(
                    'Automática',
                    style: TextStyle(
                      color: AppTheme.textMuted(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            else if (view.mission.completionMode == 'note' &&
                !view.progress.completed)
              TextButton(
                onPressed: () => onComplete(view),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary(context),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Escrever',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              )
            else
              TextButton(
                onPressed:
                    view.progress.completed ? () => onComplete(view) : null,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary(context),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Coletar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(_MissionView view) {
    final c = view.mission.criteria;
    if (view.mission.completionMode == 'note') {
      return view.progress.completed
          ? 'Pronta para coletar'
          : 'Escreva para concluir';
    }
    if (view.mission.completionMode == 'auto') {
      return view.progress.completed
          ? 'Concluída automaticamente'
          : 'Automática';
    }
    if (c == null || c['kind'] == null) {
      return view.progress.completed ? 'Pronta para coletar' : 'Em progresso';
    }
    if (c['kind'] == 'ratio_at_least' || c['kind'] == 'ratio_at_most') {
      final metric = (c['metric'] as String?) ?? '';
      final target = (c['target'] as num?)?.toDouble() ?? 0.0;
      final label = metric == 'variable'
          ? 'Variáveis'
          : metric == 'fixed'
              ? 'Fixos'
              : metric == 'invest'
                  ? 'Invest.'
                  : metric == 'buffer'
                      ? 'Sobra'
                      : metric == 'housing'
                          ? 'Moradia'
                          : metric;
      final op = c['kind'] == 'ratio_at_least' ? '≥' : '≤';
      final tgt = (target * 100).round();
      return '$label $op $tgt%';
    }
    if (view.progress.total <= 1) {
      return view.progress.completed ? 'Feito' : 'Pendente';
    }
    return '${view.progress.current}/${view.progress.total}';
  }
}
