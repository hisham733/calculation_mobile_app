import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';
import 'settings_screen.dart';

/// Budget screen showing spending by category with pie chart and progress bars.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _storage = createStorage();
  List<Category> _categories = [];
  List<Expense> _currentExpenses = [];
  List<Expense> _lastMonthExpenses = [];
  bool _loading = true;
  bool _budgetRollover = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await _storage.getCategories();
    final now = DateTime.now();
    final currentExpenses = await _storage.getExpensesForMonth(now);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastExpenses = await _storage.getExpensesForMonth(lastMonth);
    final prefs = await SharedPreferences.getInstance();
    final rollover = prefs.getBool(kBudgetRollover) ?? true;
    setState(() {
      _categories = categories;
      _currentExpenses = currentExpenses;
      _lastMonthExpenses = lastExpenses;
      _budgetRollover = rollover;
      _loading = false;
    });
  }

  /// Computes unused budget from last month that rolls over to current month.
  double _rollover(Category cat) {
    if (!_budgetRollover) return 0;
    final budget = cat.monthlyBudget ?? 0;
    if (budget <= 0) return 0;
    final spent = _lastMonthExpenses
        .where((e) => e.categoryId == cat.id)
        .fold(0.0, (s, e) => s + e.totalAmount);
    return (budget - spent).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final spending = Calculations.categorySpending(_currentExpenses);
    final total = _currentExpenses.fold(0.0, (s, e) => s + e.totalAmount);

    return Scaffold(
      appBar: AppBar(title: _appTitle(Icons.pie_chart, 'Budget', 'Spending by category')),
      body: _currentExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No expenses yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Add expenses to see budget breakdown',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (total > 0) _pieChart(spending, total),
                  if (total > 0) const SizedBox(height: 24),
                  ..._categories.map((c) => _budgetTile(c, spending[c.id] ?? 0)),
                ],
              ),
            ),
    );
  }

  /// Pie chart showing spending distribution across categories with active expenses.
  Widget _pieChart(Map<String?, double> spending, double total) {
    final colors = [
      const Color(0xFF006D77), const Color(0xFFFF8C42), const Color(0xFF2D6A4F),
      const Color(0xFF83C5BE), const Color(0xFFE29578), const Color(0xFF6B9080),
      const Color(0xFFD4A373), const Color(0xFF4A6FA5),
    ];

    final visible = _categories.where((c) => (spending[c.id] ?? 0) > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final sections = visible.asMap().entries.map((e) {
      final pct = (spending[e.value.id]! / total) * 100;
      return PieChartSectionData(
        value: spending[e.value.id]!,
        title: '${pct.toInt()}%',
        radius: 50,
        color: colors[e.key % colors.length],
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Spending by Category',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: PieChart(PieChartData(sections: sections))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: visible.asMap().entries.map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: colors[e.key % colors.length])),
                      const SizedBox(width: 4),
                      Text('${e.value.name} (${Calculations.currency(spending[e.value.id]!)})',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Budget progress bar with rollover, color-coded by usage level, with alerts at 80%+.
  Widget _budgetTile(Category category, double spent) {
    final cs = Theme.of(context).colorScheme;
    final budget = category.monthlyBudget ?? 0;
    final hasBudget = budget > 0;
    final rollover = _rollover(category);
    final available = budget + rollover;
    final ratio = hasBudget ? (spent / available).clamp(0.0, 1.0) : 0.0;
    final remaining = hasBudget ? (available - spent).clamp(0.0, double.infinity) : 0.0;
    final over80 = ratio >= 0.8;
    final over100 = ratio >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: cs.primary),
                    if (over80)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: over100 ? cs.error : const Color(0xFFFF8C42),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (hasBudget)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: Calculations.currency(spent),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          children: [
                            TextSpan(
                              text: ' / ${Calculations.currency(available)}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (rollover > 0)
                        Text('+${Calculations.currency(rollover)} rolled over',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  )
                else
                  Text(Calculations.currency(spent), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 8),
              if (over80)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        over100 ? Icons.warning : Icons.info_outline,
                        size: 14,
                        color: over100 ? cs.error : const Color(0xFFFF8C42),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        over100
                            ? 'Over budget! Spending exceeds limit.'
                            : '${(ratio * 100).toInt()}% of budget used — ${Calculations.currency(remaining)} remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: over100 ? cs.error : const Color(0xFFFF8C42),
                        ),
                      ),
                    ],
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    over100 ? const Color(0xFFD32F2F) : over80 ? const Color(0xFFFF8C42) : const Color(0xFF2D6A4F),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${(ratio * 100).toInt()}% used',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  if (remaining > 0)
                    Text('${Calculations.currency(remaining)} remaining',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
                  else
                    Text('Over budget!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.error)),
                ],
              ),
            ],    // closes if (hasBudget) spread
          ],      // closes Column children
        ),        // closes Column
      ),          // closes Padding
    );            // closes Card
  }

  Widget _appTitle(IconData icon, String title, String subtitle) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
