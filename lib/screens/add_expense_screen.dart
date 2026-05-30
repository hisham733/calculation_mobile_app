import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _individualAController = TextEditingController();
  final _individualBController = TextEditingController();

  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  UserProfile? _paidBy;
  SplitMode _splitMode = SplitMode.percentage;
  double _percentageA = 50;
  double _percentageB = 50;

  List<UserProfile> _users = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _db.getUsers();
    final categories = await _db.getCategories();
    setState(() {
      _users = users;
      _categories = categories;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _individualAController.dispose();
    _individualBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Total Amount'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              trailing: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserProfile>(
              initialValue: _paidBy,
              decoration: const InputDecoration(labelText: 'Paid By'),
              items: _users
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: u.color),
                            ),
                            const SizedBox(width: 8),
                            Text(u.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            const Text('Split Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<SplitMode>(
              segments: const [
                ButtonSegment(value: SplitMode.percentage, label: Text('Percentage')),
                ButtonSegment(value: SplitMode.individual, label: Text('Individual')),
              ],
              selected: {_splitMode},
              onSelectionChanged: (v) => setState(() => _splitMode = v.first),
            ),
            const SizedBox(height: 20),
            if (_splitMode == SplitMode.percentage)
              _percentageFields()
            else
              _individualFields(),
          ],
        ),
      ),
    );
  }

  Widget _percentageFields() {
    return Column(
      children: [
        if (_users.isNotEmpty) ...[
          _percentageSlider(_users[0].name, _users[0].color, _percentageA, (v) {
            setState(() {
              _percentageA = v;
              _percentageB = 100 - v;
            });
          }),
          const SizedBox(height: 12),
          _percentageSlider(_users.length > 1 ? _users[1].name : 'User B',
              _users.length > 1 ? _users[1].color : Colors.orange, _percentageB, (v) {
            setState(() {
              _percentageB = v;
              _percentageA = 100 - v;
            });
          }),
        ],
      ],
    );
  }

  Widget _percentageSlider(String label, Color color, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
            Text('$label: ${value.toInt()}%'),
          ],
        ),
        Slider(value: value, onChanged: onChanged, min: 0, max: 100, divisions: 20),
      ],
    );
  }

  Widget _individualFields() {
    return Column(
      children: [
        if (_users.isNotEmpty) ...[
          TextField(
            controller: _individualAController,
            decoration: InputDecoration(labelText: '${_users[0].name}\'s amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          ),
          const SizedBox(height: 12),
          if (_users.length > 1)
            TextField(
              controller: _individualBController,
              decoration: InputDecoration(labelText: '${_users[1].name}\'s amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            ),
        ],
        if (_individualAController.text.isNotEmpty && _individualBController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Total: \$${_calculateIndividualTotal().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  double _calculateIndividualTotal() {
    final a = double.tryParse(_individualAController.text) ?? 0;
    final b = double.tryParse(_individualBController.text) ?? 0;
    return a + b;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _paidBy == null) return;

    final total = double.parse(_amountController.text);

    if (_splitMode == SplitMode.individual) {
      final a = double.tryParse(_individualAController.text) ?? 0;
      final b = double.tryParse(_individualBController.text) ?? 0;
      if (a + b != total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Individual amounts must add up to the total')),
        );
        return;
      }
    }

    final expense = Expense(
      description: _descController.text,
      date: _date,
      totalAmount: total,
      splitMode: _splitMode,
      splitPercentageA: _splitMode == SplitMode.percentage ? _percentageA : null,
      splitPercentageB: _splitMode == SplitMode.percentage ? _percentageB : null,
      amountA: _splitMode == SplitMode.individual ? (double.tryParse(_individualAController.text) ?? 0) : null,
      amountB: _splitMode == SplitMode.individual ? (double.tryParse(_individualBController.text) ?? 0) : null,
      paidById: _paidBy!.id!,
      categoryId: _selectedCategory!.id!,
    );

    _db.insertExpense(expense);
    Navigator.pop(context);
  }
}
