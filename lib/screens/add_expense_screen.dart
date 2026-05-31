import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';

/// Form screen for adding or editing an expense.
class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _storage = createStorage();
  final _formKey = GlobalKey<FormState>();

  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _receiptUrlController = TextEditingController();

  late DateTime _date;
  Category? _selectedCategory;
  UserProfile? _paidBy;
  SplitMode _splitMode = SplitMode.equal;
  bool _isRecurring = false;

  bool get _isEditing => widget.existingExpense != null;

  List<UserProfile> _users = [];
  List<Category> _categories = [];
  bool _loading = true;
  List<Map<String, dynamic>> _splitData = [];

  @override
  void initState() {
    super.initState();
    _date = widget.existingExpense?.date ?? DateTime.now();
    if (_isEditing) {
      final e = widget.existingExpense!;
      _descController.text = e.description;
      _amountController.text = e.totalAmount.toStringAsFixed(2);
      _splitMode = e.splitMode;
      _isRecurring = e.isRecurring;
      _notesController.text = e.notes;
      _receiptUrlController.text = e.receiptUrl;
    }
    _load();
  }

  Future<void> _load() async {
    final users = await _storage.getUsers();
    final categories = await _storage.getCategories();
    if (_isEditing) {
      _selectedCategory = categories.where((c) => c.id == widget.existingExpense!.categoryId).firstOrNull;
      _paidBy = users.where((u) => u.id == widget.existingExpense!.paidById).firstOrNull;
      _initSplitData(users);
    }
    setState(() {
      _users = users;
      _categories = categories;
      if (!_isEditing) _initSplitData(users);
      _loading = false;
    });
  }

  void _initSplitData(List<UserProfile> users) {
    final existing = widget.existingExpense;
    _splitData = users.map((u) {
      final savedAmount = existing?.splits[u.id!];
      return <String, dynamic>{
        'user': u,
        'included': existing?.participantIds.contains(u.id) ?? true,
        'controller': TextEditingController(
          text: savedAmount != null ? savedAmount.toStringAsFixed(2) : '',
        ),
      };
    }).toList();
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _receiptUrlController.dispose();
    for (final sd in _splitData) {
      (sd['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Load template',
              onPressed: _loadTemplate,
            ),
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _sectionCard([
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(_date),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(IconData(c.iconCodePoint, fontFamily: 'MaterialIcons'), size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                decoration: const InputDecoration(
                  labelText: 'Paid By',
                  prefixIcon: Icon(Icons.person_outline),
                ),
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
            ]),
            const SizedBox(height: 16),
            _sectionCard([
              const Text('Split Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SegmentedButton<SplitMode>(
                segments: const [
                  ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
                  ButtonSegment(value: SplitMode.custom, label: Text('Custom')),
                ],
                selected: {_splitMode},
                onSelectionChanged: (v) => setState(() => _splitMode = v.first),
              ),
              const SizedBox(height: 16),
              ..._splitData.asMap().entries.map((entry) => _userSplitRow(entry.key, entry.value)),
              if (_splitMode == SplitMode.custom) ...[
                const SizedBox(height: 8),
                _totalCheck(),
              ],
            ]),
            const SizedBox(height: 16),
            _sectionCard([
              SwitchListTile(
                title: const Text('Repeat monthly'),
                subtitle: const Text('Auto-generate this expense each month'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiptUrlController,
                decoration: const InputDecoration(
                  labelText: 'Receipt URL (optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _userSplitRow(int index, Map<String, dynamic> data) {
    final user = data['user'] as UserProfile;
    final included = data['included'] as bool;
    final controller = data['controller'] as TextEditingController;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: included,
              onChanged: (v) {
                setState(() => _splitData[index]['included'] = v);
              },
            ),
          ),
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: user.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (_splitMode == SplitMode.custom)
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                enabled: included,
              ),
            )
          else
            Text('Equal share', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _totalCheck() {
    final total = double.tryParse(_amountController.text) ?? 0;
    final sum = _splitData
        .where((d) => d['included'] as bool)
        .fold(0.0, (s, d) => s + (double.tryParse((d['controller'] as TextEditingController).text) ?? 0));
    final ok = (sum - total).abs() < 0.01;

    if (_amountController.text.isEmpty || sum == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: ok
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ok ? 'Total: ${Calculations.currency(sum)}' : 'Split total (${Calculations.currency(sum)}) does not match ${Calculations.currency(total)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: ok ? null : Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
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

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'expense_templates';
    final raw = prefs.getString(key);
    if (raw == null || raw == '[]') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No templates saved')),
        );
      }
      return;
    }
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    if (!context.mounted) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose a template'),
        children: list.map((t) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, t),
          child: ListTile(
            dense: true,
            title: Text(t['description'] as String? ?? ''),
            subtitle: Text(Calculations.currency((t['total_amount'] as num?)?.toDouble() ?? 0)),
          ),
        )).toList(),
      ),
    );
    if (selected == null) return;

    _descController.text = selected['description'] as String? ?? '';
    _amountController.text = (selected['total_amount'] as num?)?.toStringAsFixed(2) ?? '';
    final catId = selected['category_id'] as String?;
    if (catId != null) {
      _selectedCategory = _categories.where((c) => c.id == catId).firstOrNull;
    }
    final payerId = selected['paid_by_id'] as String?;
    if (payerId != null) {
      _paidBy = _users.where((u) => u.id == payerId).firstOrNull;
    }
    final pids = (selected['participant_ids'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
    final splitsRaw = selected['splits'] as String?;
    Map<String, double> splits = {};
    if (splitsRaw != null && splitsRaw.isNotEmpty) {
      final decoded = jsonDecode(splitsRaw) as Map<String, dynamic>;
      splits = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    for (final sd in _splitData) {
      final uid = (sd['user'] as UserProfile).id!;
      sd['included'] = pids.contains(uid);
      if (splits.containsKey(uid)) {
        (sd['controller'] as TextEditingController).text = splits[uid]!.toStringAsFixed(2);
      }
    }
    final modeName = selected['split_mode'] as String?;
    if (modeName != null) {
      _splitMode = modeName == 'equal' ? SplitMode.equal : SplitMode.custom;
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _paidBy == null) return;

    final total = double.parse(_amountController.text);
    final included = _splitData.where((d) => d['included'] as bool).toList();
    if (included.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    Map<String, double> splits;
    if (_splitMode == SplitMode.equal) {
      final share = total / included.length;
      splits = {for (final d in included) (d['user'] as UserProfile).id!: share};
    } else {
      splits = {};
      for (final d in included) {
        final amount = double.tryParse((d['controller'] as TextEditingController).text) ?? 0;
        splits[(d['user'] as UserProfile).id!] = amount;
      }
      final sum = splits.values.fold(0.0, (s, v) => s + v);
      if ((sum - total).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Individual amounts must add up to the total')),
        );
        return;
      }
    }

    final expense = Expense(
      id: _isEditing ? widget.existingExpense!.id : null,
      description: _descController.text,
      date: _date,
      totalAmount: total,
      splitMode: _splitMode,
      paidById: _paidBy!.id!,
      categoryId: _selectedCategory!.id!,
      isRecurring: _isRecurring,
      recurringInterval: _isRecurring ? 'monthly' : 'none',
      notes: _notesController.text,
      receiptUrl: _receiptUrlController.text,
      participantIds: splits.keys.toList(),
      splits: splits,
    );

    try {
      if (_isEditing) {
        await _storage.updateExpense(expense);
      } else {
        await _storage.insertExpense(expense);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Expense updated' : 'Expense added'),
        duration: const Duration(milliseconds: 800),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (context.mounted) Navigator.pop(context);
  }
}
