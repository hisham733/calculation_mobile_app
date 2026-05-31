import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = createStorage();
  List<UserProfile> _users = [];
  List<Category> _categories = [];
  List<Expense> _expenses = [];
  bool _loading = true;
  DateTime? _settledAt;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final users = await _storage.getUsers();
      final categories = await _storage.getCategories();
      final now = DateTime.now();
      final expenses = await _storage.getExpensesForMonth(now);
      final prefs = await SharedPreferences.getInstance();
      final monthKey = DateFormat('yyyy-MM').format(now);
      final settledTs = prefs.getInt('settled_$monthKey');
      setState(() {
        _users = users;
        _categories = categories;
        _expenses = expenses;
        _settledAt = settledTs != null ? DateTime.fromMillisecondsSinceEpoch(settledTs) : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  List<Expense> get _filtered {
    if (_searchQuery.isEmpty) return _expenses;
    final q = _searchQuery.toLowerCase();
    return _expenses.where((e) =>
      e.description.toLowerCase().contains(q) ||
      e.notes.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_users.length < 2) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Set up users in Settings',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final summary = Calculations.summary(
      expenses: _expenses,
      users: _users,
    );

    return Scaffold(
      appBar: AppBar(title: _appTitle(Icons.dashboard_rounded, 'Dashboard', 'Monthly overview')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            _settlementCard(summary),
            const SizedBox(height: 12),
            _totalSpentCard(summary),
            const SizedBox(height: 12),
            _userCards(summary),
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 20),
              _spendingChart(),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                text: 'Recent Expenses',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: '  ${_filtered.length > 10 ? '10 of ' : ''}${_filtered.length}',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_filtered.isEmpty)
              _emptyState()
            else ...[
              ..._filtered.take(10).map((e) => _expenseTile(context, e)),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                    const Spacer(),
                    Text(Calculations.currency(_filtered.fold(0.0, (s, e) => s + e.totalAmount)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _emptyState() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(_searchQuery.isNotEmpty
                ? 'No matching expenses'
                : 'No expenses this month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add your first expense'),
                onPressed: () => _addExpense(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalSpentCard(MonthlySummary summary) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Text('Total Spent This Month',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(Calculations.currency(summary.totalSpent),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.onSurface, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(height: 3, decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          )),
        ],
      ),
    );
  }

  Widget _userCards(MonthlySummary summary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _users.map((user) {
          final bal = summary.balanceFor(user.id!);
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 180,
              child: _userCard(user, bal?.paid ?? 0, bal?.share ?? 0),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _spendingChart() {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final dailyTotals = List.filled(daysInMonth, 0.0);
    for (final e in _expenses) {
      final day = e.date.day - 1;
      if (day >= 0 && day < daysInMonth) {
        dailyTotals[day] += e.totalAmount;
      }
    }

    final maxVal = dailyTotals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    final spots = dailyTotals.asMap().entries
        .where((e) => e.value > 0)
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Spending', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(now),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          if (v == 1 || v == daysInMonth / 2 || v == daysInMonth) {
                            return Text('${v.toInt()}', style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.08)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(UserProfile user, double paid, double share) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: user.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: user.color,
                  child: Text(user.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _labelValue('Paid', Calculations.currency(paid), cs),
                    Container(width: 1, height: 30, color: cs.outlineVariant),
                    _labelValue('Share', Calculations.currency(share), cs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value, ColorScheme cs) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _settlementCard(MonthlySummary summary) {
    final settled = _settledAt != null;
    final texts = summary.settlementTexts();
    final isBalanced = texts.length == 1 && texts.first == 'All settled';
    final cs = Theme.of(context).colorScheme;

    Color bgColor, iconColor;
    IconData icon;
    Widget content;
    if (settled) {
      bgColor = cs.primary.withValues(alpha: 0.08);
      iconColor = cs.primary;
      icon = Icons.check_circle_outline;
      content = Text('All settled this month',
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface));
    } else if (isBalanced) {
      bgColor = cs.tertiary.withValues(alpha: 0.08);
      iconColor = cs.tertiary;
      icon = Icons.balance;
      content = Text('Balanced \u2014 nothing to settle',
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface));
    } else {
      bgColor = cs.secondary.withValues(alpha: 0.08);
      iconColor = cs.secondary;
      icon = Icons.swap_horiz;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: texts.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u2022  ', style: TextStyle(color: cs.onSurface, fontSize: 13)),
              Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            ],
          ),
        )).toList(),
      );
    }

    return Card(
      color: bgColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: content),
            if (!settled && !isBalanced)
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final prefs = await SharedPreferences.getInstance();
                  final monthKey = DateFormat('yyyy-MM').format(now);
                  await prefs.setInt('settled_$monthKey', now.millisecondsSinceEpoch);
                  setState(() => _settledAt = now);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as settled')),
                    );
                  }
                },
                child: Text('Settle', style: TextStyle(color: iconColor, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _expenseTile(BuildContext context, Expense expense) {
    final cat = _categories.where((c) => c.id == expense.categoryId).firstOrNull;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          try {
            await _storage.deleteExpense(expense.id!);
            _load();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${expense.description} deleted'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(label: 'Undo', onPressed: () async {
                    try {
                      await _storage.insertExpense(expense);
                      _load();
                    } catch (_) {}
                  }),
                ),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete')),
              );
            }
          }
        },
        child: Row(
          children: [
            Container(width: 4,
              color: cat != null
                  ? _colorForCategory(cat.name)
                  : cs.primary.withValues(alpha: 0.4)),
            Expanded(
              child: ListTile(
                onTap: () => _showExpenseDetail(context, expense),
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(IconData(cat?.iconCodePoint ?? 0xe3e9, fontFamily: 'MaterialIcons'),
                      color: cs.onPrimaryContainer, size: 20),
                ),
                title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '${_userName(expense.paidById)} \u00b7 ${DateFormat('MMM d').format(expense.date)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                trailing: Text(Calculations.currency(expense.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, Expense expense) {
    final cat = _categories.where((c) => c.id == expense.categoryId).firstOrNull;
    final user = _users.where((u) => u.id == expense.paidById).firstOrNull;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(IconData(cat?.iconCodePoint ?? 0xe3e9, fontFamily: 'MaterialIcons'),
                        color: cs.onPrimaryContainer, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(expense.description,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _detailRow(Icons.attach_money, 'Amount', Calculations.currency(expense.totalAmount)),
                  const SizedBox(height: 16),
                  _detailRow(Icons.calendar_today, 'Date', DateFormat('MMM d, yyyy').format(expense.date)),
                  const SizedBox(height: 16),
                  _detailRow(Icons.category_outlined, 'Category', cat?.name ?? ''),
                  const SizedBox(height: 16),
                  _detailRow(Icons.person_outline, 'Paid by', user?.name ?? ''),
                  const SizedBox(height: 16),
                  _splitDetail(expense),
                  if (expense.isRecurring) ...[
                    const SizedBox(height: 16),
                    _detailRow(Icons.repeat, 'Recurring',
                        expense.recurringInterval == 'monthly' ? 'Monthly' : 'Weekly'),
                  ],
                  if (expense.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(expense.notes),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (expense.receiptUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.image_outlined, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Receipt', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {},
                                child: Text(expense.receiptUrl,
                                    style: TextStyle(fontSize: 12, color: cs.primary, decoration: TextDecoration.underline),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Template'),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final key = 'expense_templates';
                        final existing = prefs.getString(key);
                        final list = existing != null ? (jsonDecode(existing) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
                        list.add({
                          'description': expense.description,
                          'total_amount': expense.totalAmount,
                          'category_id': expense.categoryId,
                          'paid_by_id': expense.paidById,
                          'participant_ids': expense.participantIds.join(','),
                          'splits': jsonEncode(expense.splits),
                          'split_mode': expense.splitMode.name,
                        });
                        await prefs.setString(key, jsonEncode(list));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Saved as template'), duration: Duration(milliseconds: 800)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editExpense(context, expense);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _splitDetail(Expense expense) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.compare_arrows, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Split', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              ...expense.participantIds.map((pid) {
                final u = _users.where((u) => u.id == pid).firstOrNull;
                final amount = expense.shareFor(pid);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: u?.color ?? cs.primary)),
                      const SizedBox(width: 6),
                      Text('${u?.name ?? pid}: ${Calculations.currency(amount)}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Text('$label ', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }

  String _userName(String id) {
    return _users.where((u) => u.id == id).firstOrNull?.name ?? '';
  }

  Color _colorForCategory(String name) {
    final cat = _categories.where((c) => c.name == name).firstOrNull;
    return Color(cat?.colorValue ?? 0xFF006D77);
  }

  Future<void> _addExpense(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    _load();
  }

  Future<void> _editExpense(BuildContext context, Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(existingExpense: expense)),
    );
    _load();
  }
}
