import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';
import 'add_expense_screen.dart';

enum SortMode { dateDesc, dateAsc, amountDesc, amountAsc, category }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = createStorage();
  DateTime _selectedMonth = DateTime.now();
  String? _selectedCategoryId;
  List<Expense> _expenses = [];
  List<UserProfile> _users = [];
  List<Category> _categories = [];
  bool _loading = true;
  SortMode _sortMode = SortMode.dateDesc;
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        _loading = true;
      });
      _load();
    }
  }

  List<Expense> get _filtered {
    var result = _expenses.where((e) {
      if (_selectedCategoryId != null && e.categoryId != _selectedCategoryId) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.description.toLowerCase().contains(q) &&
            !e.notes.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortMode) {
      case SortMode.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortMode.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortMode.amountDesc:
        result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case SortMode.amountAsc:
        result.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case SortMode.category:
        result.sort((a, b) => a.categoryId.compareTo(b.categoryId));
        break;
    }
    return result;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            _monthNav(monthText),
            _filterBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${_filtered.length} expense${_filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  DropdownButton<SortMode>(
                    value: _sortMode,
                    isDense: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, size: 18),
                    items: const [
                      DropdownMenuItem(value: SortMode.dateDesc, child: Text('Newest', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: SortMode.dateAsc, child: Text('Oldest', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: SortMode.amountDesc, child: Text('Amount ↓', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: SortMode.amountAsc, child: Text('Amount ↑', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: SortMode.category, child: Text('Category', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sortMode = v);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategoryId != null
                            ? 'No matching expenses'
                            : 'No expenses',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ..._filtered.map((e) => _expenseTile(context, e)),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    Text(Calculations.currency(_total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
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
          GestureDetector(
            onTap: _pickMonth,
            child: Text(monthText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
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

  Widget _chip(String label, String? id) {
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

  Widget _expenseTile(BuildContext context, Expense expense) {
    final cat = _categories.where((c) => c.id == expense.categoryId).firstOrNull;
    final catName = cat?.name ?? '';
    final userName = _users.where((u) => u.id == expense.paidById).firstOrNull?.name ?? '';
    final dateStr = DateFormat('MMM d').format(expense.date);
    final splitStr = expense.splitMode == SplitMode.percentage
        ? '${expense.splitPercentageA?.toInt() ?? 50}/${expense.splitPercentageB?.toInt() ?? 50}'
        : 'Split';

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _storage.deleteExpense(expense.id!);
        _load();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${expense.description} deleted'),
              action: SnackBarAction(label: 'Undo', onPressed: () async {
                _storage.insertExpense(expense);
                _load();
              }),
            ),
          );
        }
      },
      child: ListTile(
        onTap: () => _editExpense(context, expense),
        leading: Icon(IconData(cat?.iconCodePoint ?? 0xe3e9, fontFamily: 'MaterialIcons'), color: Colors.grey[600]),
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
      ),
    );
  }

  Future<void> _editExpense(BuildContext context, Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(existingExpense: expense)),
    );
    _load();
  }

  Future<void> _addExpense(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    _load();
  }
}
