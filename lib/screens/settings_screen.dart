import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = createStorage();
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
    setState(() {
      _users = users;
      _categories = categories;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _usersSection(),
          _categoriesSection(),
          _actionsSection(),
        ],
      ),
    );
  }

  Widget _usersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Users'),
        ..._users.map((u) => ListTile(
              leading: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: u.color),
              ),
              title: TextField(
                controller: TextEditingController(text: u.name),
                decoration: const InputDecoration(border: InputBorder.none),
                onSubmitted: (v) {
                  u.name = v;
                  _storage.updateUser(u);
                },
              ),
            )),
        const Divider(),
      ],
    );
  }

  Widget _categoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Categories'),
        ..._categories.map((c) => _categoryTile(c)),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Category'),
          onTap: _addCategory,
        ),
        const Divider(),
      ],
    );
  }

  Widget _categoryTile(Category category) {
    return ListTile(
      leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
      title: Text(category.name),
      subtitle: category.monthlyBudget != null && category.monthlyBudget! > 0
          ? Text('Budget: ${Calculations.currency(category.monthlyBudget!)}')
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => _editCategory(category),
      ),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Delete ${category.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  _storage.deleteCategory(category.id!);
                  _load();
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionsSection() {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Reset All Data', style: TextStyle(color: Colors.red)),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Reset All Data?'),
                content: const Text('This deletes all expenses and resets settings.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      _storage.resetAll();
                      _load();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  void _addCategory() {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Budget (optional)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                _storage.insertCategory(Category(
                  name: nameCtrl.text,
                  monthlyBudget: double.tryParse(budgetCtrl.text),
                ));
                _load();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCategory(Category category) {
    final nameCtrl = TextEditingController(text: category.name);
    final budgetCtrl = TextEditingController(
      text: category.monthlyBudget?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Budget'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              category.name = nameCtrl.text;
              category.monthlyBudget = double.tryParse(budgetCtrl.text);
              _storage.updateCategory(category);
              _load();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
