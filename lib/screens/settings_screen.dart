import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../services/storage_provider.dart';
import '../helpers/calculations.dart';
import '../main.dart';

const String kBudgetRollover = 'budget_rollover';

/// Settings screen for managing users, categories, appearance, and data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

const _iconChoices = [
  0xe8cc, 0xe56c, 0xe3b3, 0xe530, 0xe404, 0xe3e9, 0xe54e, 0xe558,
  0xe541, 0xe5c8, 0xe32a, 0xe87e, 0xe8b8, 0xe324, 0xe334, 0xe335,
  0xe307, 0xe30a, 0xe31b, 0xe8d5, 0xe8d7, 0xe86c, 0xe85c, 0xe8a0,
  0xe6de, 0xe8ba, 0xe8d0, 0xe355, 0xe555, 0xe549,
];

const _catColors = [
  0xFF006D77, 0xFFFF8C42, 0xFF2D6A4F, 0xFF4A6FA5, 0xFFD4A373,
  0xFF6B9080, 0xFFE29578, 0xFF83C5BE, 0xFFA0522D, 0xFF5D7A9E,
  0xFFB8860B, 0xFFC44536, 0xFF2E86AB, 0xFFF18F01, 0xFFA23B72,
];

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = createStorage();
  List<UserProfile> _users = [];
  List<Category> _categories = [];
  bool _loading = true;
  bool _budgetRollover = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _storage.getUsers();
    final categories = await _storage.getCategories();
    final prefs = await SharedPreferences.getInstance();
    final rollover = prefs.getBool(kBudgetRollover) ?? true;
    setState(() {
      _users = users;
      _categories = categories;
      _budgetRollover = rollover;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appState = SharedExpenseApp.of(context);

    return Scaffold(
      appBar: AppBar(title: _appTitle(Icons.settings, 'Settings', 'Manage your data')),
      body: ListView(
        children: [
          _usersSection(),
          _categoriesSection(),
          _appearanceSection(appState),
          _budgetSection(),
          _actionsSection(),
        ],
      ),
    );
  }

  Widget _appearanceSection(SharedExpenseAppState? appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
            ],
            selected: {appState?.themeMode ?? ThemeMode.system},
            onSelectionChanged: (v) => appState?.setThemeMode(v.first),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _budgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Budget'),
        SwitchListTile(
          secondary: const Icon(Icons.autorenew),
          title: const Text('Rollover unused budget'),
          subtitle: const Text('Carry over leftover budget to next month'),
          value: _budgetRollover,
          onChanged: (v) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(kBudgetRollover, v);
            setState(() => _budgetRollover = v);
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _usersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Users'),
        ..._users.map((u) => ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: u.color,
                child: Text(u.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              title: TextField(
                controller: TextEditingController(text: u.name),
                decoration: const InputDecoration(border: InputBorder.none),
                onSubmitted: (v) {
                  u.name = v;
                  _storage.updateUser(u);
                },
              ),
              trailing: _users.length > 2
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteUser(u),
                    )
                  : null,
            )),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add User'),
          onTap: _addUser,
        ),
        const Divider(),
      ],
    );
  }

  void _addUser() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                _storage.insertUser(UserProfile(
                  name: nameCtrl.text,
                  colorValue: _catColors[_users.length % _catColors.length],
                ));
                _load();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(UserProfile user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${user.name}?'),
        content: const Text('Expenses paid by this user will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _storage.deleteUser(user.id!);
              _load();
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: Color(category.colorValue),
        child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
            size: 16, color: Colors.white),
      ),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
    );
  }

  /// Opens a dialog to add a new category with name, budget, icon, and color picker.
  void _addCategory() {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    int selectedIcon = _iconChoices[0];
    int selectedColor = _catColors[0];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetCtrl,
                decoration: const InputDecoration(labelText: 'Monthly Budget (optional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              _iconGrid(selectedIcon, (icon) => setDialogState(() => selectedIcon = icon)),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              _colorGrid(selectedColor, (c) => setDialogState(() => selectedColor = c)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  _storage.insertCategory(Category(
                    name: nameCtrl.text,
                    monthlyBudget: double.tryParse(budgetCtrl.text),
                    iconCodePoint: selectedIcon,
                    colorValue: selectedColor,
                  ));
                  _load();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a dialog to edit an existing category's name, budget, icon, and color.
  void _editCategory(Category category) {
    final nameCtrl = TextEditingController(text: category.name);
    final budgetCtrl = TextEditingController(
      text: category.monthlyBudget?.toStringAsFixed(0) ?? '',
    );
    int selectedIcon = category.iconCodePoint;
    int selectedColor = category.colorValue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetCtrl,
                decoration: const InputDecoration(labelText: 'Monthly Budget'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              _iconGrid(selectedIcon, (icon) => setDialogState(() => selectedIcon = icon)),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              _colorGrid(selectedColor, (c) => setDialogState(() => selectedColor = c)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                category.name = nameCtrl.text;
                category.monthlyBudget = double.tryParse(budgetCtrl.text);
                category.iconCodePoint = selectedIcon;
                category.colorValue = selectedColor;
                _storage.updateCategory(category);
                _load();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid of selectable Material Icons for category icon picker.
  Widget _iconGrid(int selected, ValueChanged<int> onSelected) {
    return SizedBox(
      height: 160,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _iconChoices.length,
        itemBuilder: (_, i) {
          final icon = _iconChoices[i];
          final isSelected = icon == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(icon),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
              ),
              child: Icon(
                IconData(icon, fontFamily: 'MaterialIcons'),
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Grid of selectable colors for category color picker.
  Widget _colorGrid(int selected, ValueChanged<int> onSelected) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _catColors.map((c) {
          final isSelected = c == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(c),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          );
        }).toList(),
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
}
