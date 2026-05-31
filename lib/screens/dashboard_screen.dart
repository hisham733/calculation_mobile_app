import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';
import 'add_expense_screen.dart';

/// Main dashboard screen showing current month's expense summary.
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
      userA: _users[0],
      userB: _users[1],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
            _perUserRow(summary),
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
            Text('Recent Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (_filtered.isEmpty)
              _emptyState()
            else
              ..._filtered.take(10).map((e) => _expenseTile(context, e)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_searchQuery.isNotEmpty
                ? 'No matching expenses'
                : 'No expenses this month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Text('Total Spent This Month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            Text(Calculations.currency(summary.totalSpent),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }

  Widget _perUserRow(MonthlySummary summary) {
    return Row(
      children: [
        Expanded(child: _userCard(_users[0], summary.userAPaid, summary.userAShare)),
        const SizedBox(width: 12),
        Expanded(child: _userCard(_users[1], summary.userBPaid, summary.userBShare)),
      ],
    );
  }

  Widget _userCard(UserProfile user, double paid, double share) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: user.color,
              child: Text(user.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _labelValue('Paid', Calculations.currency(paid), cs),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _labelValue('Share', Calculations.currency(share), cs),
              ],
            ),
          ],
        ),
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
    final balanced = summary.balanceA == 0;
    final cs = Theme.of(context).colorScheme;

    Color bgColor, iconColor;
    IconData icon;
    String text;
    if (settled) {
      bgColor = Colors.green.withValues(alpha: 0.12);
      iconColor = Colors.green;
      icon = Icons.check_circle;
      text = 'All settled this month';
    } else if (balanced) {
      bgColor = Colors.green.withValues(alpha: 0.12);
      iconColor = Colors.green;
      icon = Icons.balance;
      text = 'Balanced — nothing to settle';
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.12);
      iconColor = Colors.orange;
      icon = Icons.swap_horiz;
      text = summary.settlementText(_users[0].name, _users[1].name);
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.15),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.start),
            ),
            if (!settled && !balanced)
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final prefs = await SharedPreferences.getInstance();
                  final monthKey = DateFormat('yyyy-MM').format(now);
                  await prefs.setInt('settled_$monthKey', now.millisecondsSinceEpoch);
                  setState(() => _settledAt = now);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as settled'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                child: const Text('Settle'),
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
      child: Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          await _storage.deleteExpense(expense.id!);
          _load();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${expense.description} deleted'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(label: 'Undo', onPressed: () async {
                  _storage.insertExpense(expense);
                  _load();
                }),
              ),
            );
          }
        },
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
                color: Colors.grey[300],
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
                  _detailRow(Icons.compare_arrows, 'Split',
                      expense.splitMode == SplitMode.percentage
                          ? '${expense.splitPercentageA?.toInt() ?? 50}% / ${expense.splitPercentageB?.toInt() ?? 50}%'
                          : '${Calculations.currency(expense.amountA ?? 0)} / ${Calculations.currency(expense.amountB ?? 0)}'),
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
                        Icon(Icons.notes, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(expense.notes),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text('$label ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
