import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = createStorage();
  DateTime _selectedMonth = DateTime.now();
  int? _selectedCategoryId;
  List<Expense> _expenses = [];
  List<UserProfile> _users = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _storage.getUsers();
    final categories = await _storage.getCategories();
    final expenses = await _storage.getExpensesForMonth(_selectedMonth);
    setState(() {
      _users = users;
      _categories = categories;
      _expenses = expenses;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
      _loading = true;
    });
    _load();
  }

  List<Expense> get _filtered {
    if (_selectedCategoryId == null) return _expenses;
    return _expenses.where((e) => e.categoryId == _selectedCategoryId).toList();
  }

  double get _total => _filtered.fold(0.0, (s, e) => s + e.totalAmount);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthText = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          _monthNav(monthText),
          _filterBar(),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No expenses'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Spacer(),
                            Text('Total: ${Calculations.currency(_total)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _expenseTile(_filtered[i]),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _monthNav(String monthText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
          Text(monthText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', null),
          ..._categories.map((c) => _chip(c.name, c.id)),
        ],
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategoryId = id),
      ),
    );
  }

  Widget _expenseTile(Expense expense) {
    final catName = _categories.where((c) => c.id == expense.categoryId).firstOrNull?.name ?? '';
    final userName = _users.where((u) => u.id == expense.paidById).firstOrNull?.name ?? '';
    final dateStr = DateFormat('MMM d').format(expense.date);
    final splitStr = expense.splitMode == SplitMode.percentage
        ? '${expense.splitPercentageA?.toInt() ?? 50}/${expense.splitPercentageB?.toInt() ?? 50}'
        : 'Split';

    return ListTile(
      leading: Icon(Icons.category, color: Colors.grey[600]),
      title: Text(expense.description),
      subtitle: Text('$userName · $dateStr · $catName'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Calculations.currency(expense.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(splitStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
