import 'package:flutter_test/flutter_test.dart';
import 'package:shared_expense_app/models/expense.dart';
import 'package:shared_expense_app/models/user_profile.dart';
import 'package:shared_expense_app/models/category.dart';
import 'package:shared_expense_app/helpers/calculations.dart';

void main() {
  group('Expense model', () {
    test('toMap / fromMap roundtrip with equal split', () {
      final e = Expense(
        description: 'Groceries',
        date: DateTime(2026, 6, 1),
        totalAmount: 100,
        paidById: 'a',
        categoryId: 'cat1',
        participantIds: ['a', 'b'],
        splits: {'a': 50, 'b': 50},
      );
      final map = e.toMap();
      final restored = Expense.fromMap(map);
      expect(restored.description, 'Groceries');
      expect(restored.totalAmount, 100);
      expect(restored.paidById, 'a');
      expect(restored.participantIds, ['a', 'b']);
      expect(restored.splits, {'a': 50.0, 'b': 50.0});
      expect(restored.notes, '');
      expect(restored.receiptUrl, '');
    });

    test('toMap / fromMap roundtrip with custom splits', () {
      final e = Expense(
        description: 'Dinner',
        date: DateTime(2026, 6, 5),
        totalAmount: 90,
        paidById: 'b',
        categoryId: 'cat2',
        splitMode: SplitMode.custom,
        notes: 'treat',
        receiptUrl: 'https://example.com/receipt',
        participantIds: ['a', 'b', 'c'],
        splits: {'a': 30, 'b': 30, 'c': 30},
      );
      final map = e.toMap();
      final restored = Expense.fromMap(map);
      expect(restored.description, 'Dinner');
      expect(restored.splitMode, SplitMode.custom);
      expect(restored.participantIds, ['a', 'b', 'c']);
      expect(restored.notes, 'treat');
      expect(restored.receiptUrl, 'https://example.com/receipt');
    });

    test('shareFor returns correct split', () {
      final e = Expense(
        description: 'Test',
        date: DateTime(2026, 1, 1),
        totalAmount: 60,
        paidById: 'a',
        categoryId: 'cat',
        participantIds: ['a', 'b', 'c'],
        splits: {'a': 20, 'b': 30, 'c': 10},
      );
      expect(e.shareFor('a'), 20);
      expect(e.shareFor('b'), 30);
      expect(e.shareFor('z'), 0);
    });

    test('fromMap handles legacy fields', () {
      final map = {
        'description': 'Legacy',
        'date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'total_amount': 50.0,
        'split_mode': 'equal',
        'paid_by_id': 'user_a',
        'category_id': 'cat',
        'is_recurring': false,
        'recurring_interval': 'none',
        'notes': '',
        'receipt_url': '',
        'legacy_user_a_id': 'user_a',
        'legacy_user_b_id': 'user_b',
        'split_percentage_a': 50,
        'split_percentage_b': 50,
      };
      final e = Expense.fromMap(map);
      expect(e.description, 'Legacy');
      expect(e.participantIds, ['user_a', 'user_b']);
      expect(e.splits['user_a'], 25.0);
      expect(e.splits['user_b'], 25.0);
    });

    test('fromMap handles empty participant_ids string', () {
      final map = {
        'description': 'Empty parts',
        'date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'total_amount': 30.0,
        'split_mode': 'equal',
        'paid_by_id': 'x',
        'category_id': 'cat',
        'is_recurring': false,
        'recurring_interval': 'none',
        'notes': '',
        'receipt_url': '',
        'participant_ids': '',
        'splits': '{}',
      };
      final e = Expense.fromMap(map);
      expect(e.participantIds, []);
      expect(e.splits, {});
    });
  });

  group('UserProfile model', () {
    test('toMap / fromMap roundtrip', () {
      final u = UserProfile(id: 'test_id', name: 'Alice', colorValue: 0xFF006D77);
      final map = u.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored.id, 'test_id');
      expect(restored.name, 'Alice');
      expect(restored.colorValue, 0xFF006D77);
    });

    test('color getter returns Color from colorValue', () {
      final u = UserProfile(id: 'x', name: 'Bob', colorValue: 0xFFFF0000);
      expect(u.color.value, 0xFFFF0000);
    });
  });

  group('Category model', () {
    test('toMap / fromMap roundtrip', () {
      final c = Category(id: 'cat1', name: 'Groceries', iconCodePoint: 0xe8cc, colorValue: 0xFF006D77, monthlyBudget: 500);
      final map = c.toMap();
      final restored = Category.fromMap(map);
      expect(restored.id, 'cat1');
      expect(restored.name, 'Groceries');
      expect(restored.iconCodePoint, 0xe8cc);
      expect(restored.monthlyBudget, 500);
    });

    test('fromMap defaults colorValue', () {
      final map = {
        'name': 'Test',
        'icon_code_point': 0xe404,
        'monthly_budget': null,
      };
      final c = Category.fromMap(map);
      expect(c.colorValue, 0xFF006D77);
      expect(c.monthlyBudget, null);
    });
  });

  group('Calculations', () {
    test('currency formats correctly', () {
      expect(Calculations.currency(12.345), 'RM12.35');
      expect(Calculations.currency(0), 'RM0.00');
      expect(Calculations.currency(1000), 'RM1,000.00');
      expect(Calculations.currency(99.9), 'RM99.90');
    });

    test('categorySpending groups by category', () {
      final expenses = [
        Expense(description: 'a', date: DateTime(2026, 1, 1), totalAmount: 10, paidById: 'x', categoryId: 'cat1'),
        Expense(description: 'b', date: DateTime(2026, 1, 1), totalAmount: 20, paidById: 'x', categoryId: 'cat2'),
        Expense(description: 'c', date: DateTime(2026, 1, 1), totalAmount: 30, paidById: 'x', categoryId: 'cat1'),
      ];
      final result = Calculations.categorySpending(expenses);
      expect(result['cat1'], 40);
      expect(result['cat2'], 20);
    });

    test('summary with equal split across 3 users', () {
      final users = [
        UserProfile(id: 'a', name: 'Alice'),
        UserProfile(id: 'b', name: 'Bob'),
        UserProfile(id: 'c', name: 'Charlie'),
      ];
      final expenses = [
        Expense(
          description: 'Dinner',
          date: DateTime(2026, 1, 1),
          totalAmount: 60,
          paidById: 'a',
          categoryId: 'cat',
          participantIds: ['a', 'b', 'c'],
          splits: {'a': 20, 'b': 20, 'c': 20},
        ),
        Expense(
          description: 'Drinks',
          date: DateTime(2026, 1, 2),
          totalAmount: 30,
          paidById: 'b',
          categoryId: 'cat',
          participantIds: ['a', 'b', 'c'],
          splits: {'a': 10, 'b': 10, 'c': 10},
        ),
      ];
      final s = Calculations.summary(expenses: expenses, users: users);
      expect(s.totalSpent, 90);
      expect(s.balanceFor('a')!.paid, 60);
      expect(s.balanceFor('a')!.share, 30);
      expect(s.balanceFor('a')!.balance, 30);
      expect(s.balanceFor('b')!.paid, 30);
      expect(s.balanceFor('b')!.share, 30);
      expect(s.balanceFor('b')!.balance, 0);
      expect(s.balanceFor('c')!.paid, 0);
      expect(s.balanceFor('c')!.share, 30);
      expect(s.balanceFor('c')!.balance, -30);
    });

    test('summary with custom splits', () {
      final users = [
        UserProfile(id: 'a', name: 'Alice'),
        UserProfile(id: 'b', name: 'Bob'),
      ];
      final expenses = [
        Expense(
          description: 'Rent',
          date: DateTime(2026, 1, 1),
          totalAmount: 100,
          paidById: 'a',
          categoryId: 'cat',
          splitMode: SplitMode.custom,
          participantIds: ['a', 'b'],
          splits: {'a': 60, 'b': 40},
        ),
      ];
      final s = Calculations.summary(expenses: expenses, users: users);
      expect(s.balanceFor('a')!.balance, 40);
      expect(s.balanceFor('b')!.balance, -40);
    });

    test('settlementTexts with 3 users', () {
      final summary = MonthlySummary(
        totalSpent: 200,
        userBalances: [
          UserBalance(userId: 'a', userName: 'Alice', paid: 100, share: 50),
          UserBalance(userId: 'b', userName: 'Bob', paid: 30, share: 70),
          UserBalance(userId: 'c', userName: 'Charlie', paid: 70, share: 80),
        ],
        users: [
          UserProfile(id: 'a', name: 'Alice'),
          UserProfile(id: 'b', name: 'Bob'),
          UserProfile(id: 'c', name: 'Charlie'),
        ],
      );
      final texts = summary.settlementTexts();
      expect(texts.length, 2);
      expect(texts[0], contains('Bob owes Alice'));
      expect(texts[1], contains('Charlie owes Alice'));
    });

    test('settlementTexts all settled', () {
      final summary = MonthlySummary(
        totalSpent: 100,
        userBalances: [
          UserBalance(userId: 'a', userName: 'Alice', paid: 50, share: 50),
          UserBalance(userId: 'b', userName: 'Bob', paid: 50, share: 50),
        ],
        users: [
          UserProfile(id: 'a', name: 'Alice'),
          UserProfile(id: 'b', name: 'Bob'),
        ],
      );
      expect(summary.settlementTexts(), ['All settled']);
    });

    test('settlementTexts empty users', () {
      final summary = MonthlySummary(
        totalSpent: 0,
        userBalances: [],
        users: [],
      );
      expect(summary.settlementTexts(), ['All settled']);
    });
  });
}
