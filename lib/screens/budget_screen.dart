import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';

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
    setState(() {
      _categories = categories;
      _currentExpenses = currentExpenses;
      _lastMonthExpenses = lastExpenses;
      _loading = false;
    });
  }

  double _rollover(Category cat) {
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
      appBar: AppBar(title: const Text('Budget')),
      body: _currentExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No expenses yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add expenses to see budget breakdown',
                      style: TextStyle(color: Colors.grey[500])),
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

  Widget _pieChart(Map<String?, double> spending, double total) {
    final colors = [
      Colors.indigo, Colors.orange, Colors.teal, Colors.pink,
      Colors.amber, Colors.cyan, Colors.deepPurple, Colors.lime,
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

  Widget _budgetTile(Category category, double spent) {
    final budget = category.monthlyBudget ?? 0;
    final hasBudget = budget > 0;
    final rollover = _rollover(category);
    final available = budget + rollover;
    final ratio = hasBudget ? (spent / available).clamp(0.0, 1.0) : 0.0;
    final remaining = hasBudget ? (available - spent).clamp(0.0, double.infinity) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Theme.of(context).colorScheme.primary),
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
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (rollover > 0)
                        Text('+${Calculations.currency(rollover)} rolled over',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  )
                else
                  Text(Calculations.currency(spent), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(
                    ratio > 0.9 ? Colors.red : ratio > 0.7 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${(ratio * 100).toInt()}% used',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  if (remaining > 0)
                    Text('${Calculations.currency(remaining)} remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  else
                    const Text('Over budget!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
