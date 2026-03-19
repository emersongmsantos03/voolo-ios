import '../models/expense.dart';

enum BudgetRuleDirection { max, min }

enum BudgetRuleScope { housing, fixed, variable, leisure, investment }

class BudgetRule {
  final BudgetRuleScope scope;
  final BudgetRuleDirection direction;
  final double idealShare;
  final double alertShare;

  const BudgetRule({
    required this.scope,
    required this.direction,
    required this.idealShare,
    required this.alertShare,
  });
}

const BudgetRule housingBudgetRule = BudgetRule(
  scope: BudgetRuleScope.housing,
  direction: BudgetRuleDirection.max,
  idealShare: 0.30,
  alertShare: 0.35,
);

const BudgetRule fixedBudgetRule = BudgetRule(
  scope: BudgetRuleScope.fixed,
  direction: BudgetRuleDirection.max,
  idealShare: 0.50,
  alertShare: 0.60,
);

const BudgetRule variableBudgetRule = BudgetRule(
  scope: BudgetRuleScope.variable,
  direction: BudgetRuleDirection.max,
  idealShare: 0.25,
  alertShare: 0.35,
);

const BudgetRule leisureBudgetRule = BudgetRule(
  scope: BudgetRuleScope.leisure,
  direction: BudgetRuleDirection.max,
  idealShare: 0.15,
  alertShare: 0.25,
);

const BudgetRule investmentBudgetRule = BudgetRule(
  scope: BudgetRuleScope.investment,
  direction: BudgetRuleDirection.min,
  idealShare: 0.15,
  alertShare: 0.10,
);

BudgetRule budgetRuleForEntry({
  required ExpenseType type,
  required ExpenseCategory category,
}) {
  if (type == ExpenseType.investment) return investmentBudgetRule;
  if (category == ExpenseCategory.moradia) return housingBudgetRule;
  if (category == ExpenseCategory.lazer) return leisureBudgetRule;
  if (type == ExpenseType.fixed) return fixedBudgetRule;
  return variableBudgetRule;
}

double trackedTotalForBudgetRule(
  List<Expense> expenses, {
  required ExpenseType type,
  required ExpenseCategory category,
}) {
  final rule = budgetRuleForEntry(type: type, category: category);
  return expenses
      .where((expense) => _matchesBudgetRule(expense, rule.scope))
      .fold(0.0, (sum, expense) => sum + expense.amount);
}

bool shouldShowBudgetTip(BudgetRule rule, double share) {
  switch (rule.direction) {
    case BudgetRuleDirection.max:
      return share >= rule.idealShare;
    case BudgetRuleDirection.min:
      return share < rule.idealShare;
  }
}

bool isBudgetAlert(BudgetRule rule, double share) {
  switch (rule.direction) {
    case BudgetRuleDirection.max:
      return share >= rule.alertShare;
    case BudgetRuleDirection.min:
      return share < rule.alertShare;
  }
}

bool _matchesBudgetRule(Expense expense, BudgetRuleScope scope) {
  switch (scope) {
    case BudgetRuleScope.housing:
      return expense.category == ExpenseCategory.moradia &&
          !expense.isInvestment;
    case BudgetRuleScope.fixed:
      return expense.isFixed && !expense.isInvestment;
    case BudgetRuleScope.variable:
      return expense.isVariable && !expense.isInvestment;
    case BudgetRuleScope.leisure:
      return expense.category == ExpenseCategory.lazer && !expense.isInvestment;
    case BudgetRuleScope.investment:
      return expense.isInvestment;
  }
}
