import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
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
  List<Expense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _storage.getUsers();
    final now = DateTime.now();
    final expenses = await _storage.getExpensesForMonth(now);
    setState(() {
      _users = users;
      _expenses = expenses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_users.length < 2) {
      return const Scaffold(body: Center(child: Text('Set up users in Settings')));
    }

    final summary = Calculations.summary(
      expenses: _expenses,
      userA: _users[0],
      userB: _users[1],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addExpense(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _totalSpentCard(summary),
            const SizedBox(height: 12),
            _perUserRow(summary),
            const SizedBox(height: 12),
            _settlementCard(summary),
            const SizedBox(height: 24),
            Text('Recent Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No expenses this month')),
              )
            else
              ..._expenses.take(5).map((e) => _expenseTile(e)),
          ],
        ),
      ),
    );
  }

  Widget _totalSpentCard(MonthlySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('Total Spent This Month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(Calculations.currency(summary.totalSpent),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: user.color),
                ),
                const SizedBox(width: 6),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Paid', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(Calculations.currency(paid),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Share', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(Calculations.currency(share), style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _settlementCard(MonthlySummary summary) {
    final settled = summary.balanceA == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settled ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, color: settled ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Text(
            summary.settlementText(_users[0].name, _users[1].name),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense expense) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(Icons.category, color: Colors.grey[600]),
      title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${_userName(expense.paidById)} · ${expense.date.toString().split(' ')[0]}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(Calculations.currency(expense.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  String _userName(int id) {
    return _users.where((u) => u.id == id).firstOrNull?.name ?? '';
  }

  Future<void> _addExpense(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    _load();
  }
}
