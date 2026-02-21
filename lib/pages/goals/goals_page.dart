import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/ui/responsive.dart';
import '../../models/goal.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../core/plans/user_plan.dart';
import '../../widgets/premium_gate.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  int _selectedYear = DateTime.now().year;

  // We no longer need local _goals list, we use stream data

  @override
  void initState() {
    super.initState();
    // No initialization needed for stream
  }

  String _currentUid() {
    return LocalStorageService.currentUserId ?? '';
  }

  // --- Logic Helpers ---

  String _weeklyPrefix() {
    final now = DateTime.now();
    // Simple week calculation
    final week = ((now.day - 1) ~/ 7) + 1;
    return 'weekly_${now.year}_${now.month}_${week}_';
  }

  bool _isWeekly(Goal g) => g.id.startsWith('weekly_');

  // This helps ensuring we don't spam create mandatory goals
  // We will do this check inside the builder or in a separate effect if needed.
  // For simplicity/performance in Flutter Build, we can check "if missing, add it"
  // but we must be careful not to trigger recursive builds.
  // Better approach: User tries to load, if vital goals missing, we add them once.

  String _slug(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _ensureMandatoryGoals(List<Goal> currentGoals) async {
    final uid = _currentUid();
    if (uid.isEmpty) return;

    // 1. Income Goal
    final incomeGoalId = 'income_$_selectedYear';
    if (!currentGoals.any((g) => g.id == incomeGoalId)) {
      final mandatory = Goal(
        id: incomeGoalId,
        title: 'goal_income_title', // Translation key
        type: GoalType.income,
        targetYear: _selectedYear,
        description: 'goal_income_desc', // Translation key
        completed: false,
      );
      await FirestoreService.addGoal(uid, mandatory, customId: incomeGoalId);
    }

    // 2. Weekly Challenges
    await _ensureWeeklyChallenges(currentGoals);
  }

  Future<void> _ensureWeeklyChallenges(List<Goal> currentGoals) async {
    final uid = _currentUid();
    if (uid.isEmpty) return;

    // Get current dashboard for balance check
    final dashboard = LocalStorageService.getDashboard(
        DateTime.now().month, DateTime.now().year);
    final balance = dashboard?.remainingSalary ?? 0;

    final templates = [
      {
        'title': 'goal_weekly_finance_content_title',
        'type': GoalType.education,
        'desc': 'goal_weekly_finance_content_desc'
      },
      {
        'title': 'goal_weekly_review_expenses_title',
        'type': GoalType.personal,
        'desc': 'goal_weekly_review_expenses_desc'
      },
    ];

    if (balance >= 0) {
      templates.add({
        'title': 'goal_weekly_invest_10_title',
        'type': GoalType.income,
        'desc': 'goal_weekly_invest_10_desc'
      });
    } else {
      templates.add({
        'title': 'goal_weekly_spend_limit_title',
        'type': GoalType.personal,
        'desc': 'goal_weekly_spend_limit_desc'
      });
    }

    templates.add({
      'title': 'goal_weekly_start_finance_book_title',
      'type': GoalType.education,
      'desc': 'goal_weekly_start_finance_book_desc'
    });

    final prefix = _weeklyPrefix();

    for (final tpl in templates) {
      final titleKey = tpl['title'] as String;
      final slug = _slug(titleKey);
      final id = '$prefix$slug';

      if (!currentGoals.any((g) => g.id == id)) {
        final goal = Goal(
          id: id,
          title: titleKey,
          type: tpl['type'] as GoalType,
          targetYear: DateTime.now().year,
          description: tpl['desc'] as String,
          completed: false,
        );
        await FirestoreService.addGoal(uid, goal, customId: id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid();
    if (uid.isEmpty) return const Center(child: CircularProgressIndicator());

    final profile = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(profile, 'goals');

    final content = SafeArea(
      child: StreamBuilder<List<Goal>>(
        stream: FirestoreService.watchGoals(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(AppStrings.t(context, 'goals_load_error'),
                    style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGoals = snapshot.data ?? [];

          // Filter
          final yearGoals = allGoals
              .where((g) => g.targetYear == _selectedYear && !_isWeekly(g))
              .toList();
          final weeklyGoals =
              allGoals.where((g) => g.id.startsWith(_weeklyPrefix())).toList();

          // Run check for mandatory goals (fire and forget)
          // We use a microtask to avoid setState during build
          Future.microtask(() => _ensureMandatoryGoals(allGoals));

          // Calc Progress
          final total = yearGoals.length;
          final completed = yearGoals.where((g) => g.completed).length;
          final progress = total == 0 ? 0.0 : completed / total;

          final suggestions = _getSuggestions(allGoals);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(context, 'goals_title'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddGoalModal(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.plus,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.t(context, 'goals_quick_tip'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // YEAR SELECTOR
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft,
                              color: Colors.white70),
                          onPressed: () => setState(() => _selectedYear--),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_selectedYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight,
                              color: Colors.white70),
                          onPressed: () => setState(() => _selectedYear++),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // PROGRESS CARD
                _buildSectionTitle(
                    AppStrings.t(context, 'goals_progress_section')),
                const SizedBox(height: 12),
                _buildProgressCard(completed, total, progress),

                // SUGGESTIONS
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      AppStrings.t(context, 'goals_suggestions_section')),
                  const SizedBox(height: 12),
                  ...suggestions.map((s) => _buildSuggestionCard(uid, s)),
                ],

                // WEEKLY
                const SizedBox(height: 32),
                _buildSectionTitle(
                    AppStrings.t(context, 'goals_weekly_section')),
                const SizedBox(height: 12),
                if (weeklyGoals.isEmpty)
                  _buildEmptyState(AppStrings.t(context, 'goals_weekly_empty'),
                      LucideIcons.zap)
                else
                  ...weeklyGoals.map((g) => _buildGoalItem(uid, g)),

                const SizedBox(height: 32),

                // YEARLY GOALS
                _buildSectionTitle(AppStrings.t(context, 'goals_section_year')),
                const SizedBox(height: 12),
                if (yearGoals.isEmpty)
                  _buildEmptyState(AppStrings.t(context, 'goals_empty_year'),
                      LucideIcons.target)
                else
                  ...yearGoals.map((g) => _buildGoalItem(uid, g)),

                const SizedBox(height: 80), // Fab spacing
              ],
            ),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PremiumGate(
        isPremium: isPremium,
        title: AppStrings.t(context, 'goals_premium_title'),
        subtitle: AppStrings.t(context, 'goals_premium_subtitle'),
        perks: [
          AppStrings.t(context, 'goals_premium_perk1'),
          AppStrings.t(context, 'goals_premium_perk2'),
          AppStrings.t(context, 'goals_premium_perk3'),
        ],
        child: content,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.t(context, 'completed_label'),
                  style: const TextStyle(color: Colors.white70)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.tr(context, 'goals_completed_count',
                  {'done': '$completed', 'total': '$total'}),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String uid, Goal goal) {
    final isIncome = goal.type == GoalType.income;
    final color = isIncome
        ? AppColors.green
        : (goal.type == GoalType.education
            ? AppColors.blue
            : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translate(goal.title),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppStrings.t(
                                  context, 'goals_type_${goal.type.name}'),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ACTIONS
                    IconButton(
                      icon: Icon(
                        goal.completed
                            ? LucideIcons.checkCircle
                            : LucideIcons.circle,
                        color:
                            goal.completed ? AppColors.green : Colors.white24,
                      ),
                      onPressed: () async {
                        final newVal = !goal.completed;
                        if (goal.id.startsWith('weekly_')) {
                          await FirestoreService.toggleChallenge(
                              uid, goal.id, newVal);
                        } else {
                          await FirestoreService.toggleGoal(
                              uid, goal.id, newVal);
                        }

                        // Local optimistic update for totalXp if completing a challenge
                        if (newVal && goal.id.startsWith('weekly_')) {
                          final user = LocalStorageService.getUserProfile();
                          if (user != null) {
                            user.totalXp += 25;
                            await LocalStorageService.saveUserProfile(user);
                          }
                        }
                      },
                    ),
                    if (!goal.id
                        .startsWith('income_')) // Prevent deleting mandatory
                      IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            color: Colors.white24, size: 18),
                        onPressed: () =>
                            FirestoreService.deleteGoal(uid, goal.id),
                      ),
                  ],
                ),
                if (goal.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 40),
                    child: Text(
                      _translate(goal.description),
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String uid, Map<String, dynamic> s) {
    final type = s['type'] as GoalType;
    final color = type == GoalType.income
        ? AppColors.green
        : (type == GoalType.education ? AppColors.blue : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(s['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate(s['titleKey'] as String),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Text(
                  _translate(s['descriptionKey'] as String),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _handleAddSuggestion(uid, s),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(AppStrings.t(context, 'goal_action_add')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddSuggestion(String uid, Map<String, dynamic> s) async {
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: s['titleKey'] as String, // Store key for sync parity if possible
      type: s['type'] as GoalType,
      targetYear: _selectedYear,
      description: s['descriptionKey'] as String,
      completed: false,
    );
    await FirestoreService.addGoal(uid, goal);

    // Local optimistic update for totalXp (adding a goal = 50 XP)
    final user = LocalStorageService.getUserProfile();
    if (user != null) {
      user.totalXp += 50;
      await LocalStorageService.saveUserProfile(user);
    }
  }

  List<Map<String, dynamic>> _getSuggestions(List<Goal> currentGoals) {
    final dashboard = LocalStorageService.getDashboard(
        DateTime.now().month, DateTime.now().year);

    if (dashboard == null || dashboard.salary <= 0) {
      return [
        {
          'titleKey': 'goal_suggest_income_title',
          'descriptionKey': 'goal_suggest_income_desc',
          'type': GoalType.income,
          'icon': LucideIcons.wallet,
        }
      ];
    }

    final list = <Map<String, dynamic>>[];
    final balance = dashboard.remainingSalary;

    if (balance < 0) {
      list.add({
        'titleKey': 'goal_suggest_reduce_variable_title',
        'descriptionKey': 'goal_suggest_reduce_variable_desc',
        'type': GoalType.personal,
        'icon': LucideIcons.trendingDown,
      });
    } else {
      list.add({
        'titleKey': 'goal_suggest_invest_title',
        'descriptionKey': 'goal_suggest_invest_desc',
        'type': GoalType.income,
        'icon': LucideIcons.trendingUp,
      });
    }

    list.add({
      'titleKey': 'goal_suggest_emergency_title',
      'descriptionKey': 'goal_suggest_emergency_desc',
      'type': GoalType.personal,
      'icon': LucideIcons.shield,
    });

    list.add({
      'titleKey': 'goal_suggest_education_title',
      'descriptionKey': 'goal_suggest_education_desc',
      'type': GoalType.education,
      'icon': LucideIcons.bookOpen,
    });

    // Filter out suggestions already in goals
    return list.where((s) {
      final title = _translate(s['titleKey'] as String);
      return !currentGoals.any((g) => _translate(g.title) == title);
    }).toList();
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isCompactPhone(context) ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          style: BorderStyle
              .none, // dashed border hard in flutter without packages
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 32),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }

  String _translate(String key) {
    return AppStrings.t(context, key);
  }

  void _showAddGoalModal(BuildContext context) {
    final uid = _currentUid();
    if (uid.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddGoalSheet(
        uid: uid,
        selectedYear: _selectedYear,
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final String uid;
  final int selectedYear;

  const _AddGoalSheet({
    required this.uid,
    required this.selectedYear,
  });

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  GoalType _selectedType = GoalType.personal;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'goals_add_new'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: AppStrings.t(context, 'goals_title_label'),
              hintText: AppStrings.t(context, 'goals_title_hint'),
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GoalType.values.map((type) {
                final selected = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      AppStrings.t(context, 'goals_type_${type.name}')
                          .toUpperCase(),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppStrings.t(context, 'goals_description_optional'),
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppStrings.t(context, 'goals_title_required')),
                          ),
                        );
                        return;
                      }

                      setState(() => _saving = true);
                      final newGoal = Goal(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        type: _selectedType,
                        targetYear: widget.selectedYear,
                        description: _descController.text.trim(),
                        completed: false,
                      );

                      await FirestoreService.addGoal(widget.uid, newGoal);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
              child: Text(
                AppStrings.t(context, 'save_goal'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
