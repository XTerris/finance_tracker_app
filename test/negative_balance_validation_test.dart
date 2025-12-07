import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/services/database_service.dart';
import 'package:finance_tracker_app/models/money.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await DatabaseService.resetForTesting();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  group('Account Creation Validation', () {
    test('Cannot create account with negative initial balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      expect(
        () => dbService.createAccount('Checking', Money.rub(-100.0)),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('отрицательным'),
          ),
        ),
      );

      final accounts = await dbService.getAllAccounts();
      expect(accounts.length, 0);
    });

    test('Can create account with zero initial balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(0.0));
      expect(account.balance.amount, 0.0);

      final accounts = await dbService.getAllAccounts();
      expect(accounts.length, 1);
      expect(accounts[0].balance.amount, 0.0);
    });

    test('Can create account with positive initial balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(1000.0));
      expect(account.balance.amount, 1000.0);

      final accounts = await dbService.getAllAccounts();
      expect(accounts.length, 1);
      expect(accounts[0].balance.amount, 1000.0);
    });
  });

  group('Account Update Validation', () {
    test('Cannot update account balance to negative value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      expect(
        () => dbService.updateAccount(id: account.id, balance: -500.0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('отрицательным'),
          ),
        ),
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 1000.0);
    });

    test('Can update account balance to zero', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      await dbService.updateAccount(id: account.id, balance: 0.0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 0.0);
    });

    test('Can update account balance to positive value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      await dbService.updateAccount(id: account.id, balance: 2000.0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 2000.0);
    });

    test('Can update account name without changing balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      await dbService.updateAccount(id: account.id, name: 'Savings');

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.name, 'Savings');
      expect(updatedAccount.balance.amount, 1000.0);
    });
  });

  group('Goal Creation Validation', () {
    test('Cannot create goal with negative target amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));

      expect(
        () => dbService.createGoal(
          accountId: account.id,
          targetAmount: -500.0,
          deadline: DateTime.now().add(const Duration(days: 30)),
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final goals = await dbService.getAllGoals();
      expect(goals.length, 0);
    });

    test('Cannot create goal with zero target amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));

      expect(
        () => dbService.createGoal(
          accountId: account.id,
          targetAmount: Money.rub(0.0),
          deadline: DateTime.now().add(const Duration(days: 30)),
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final goals = await dbService.getAllGoals();
      expect(goals.length, 0);
    });

    test('Can create goal with positive target amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));
      final deadline = DateTime.now().add(const Duration(days: 30));

      final goal = await dbService.createGoal(
        accountId: account.id,
        targetAmount: Money.rub(5000.0),
        deadline: deadline,
      );

      expect(goal.targetAmount, 5000.0);

      final goals = await dbService.getAllGoals();
      expect(goals.length, 1);
      expect(goals[0].targetAmount, 5000.0);
    });
  });

  group('Goal Update Validation', () {
    test('Cannot update goal target amount to negative value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));
      final goal = await dbService.createGoal(
        accountId: account.id,
        targetAmount: Money.rub(5000.0),
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      expect(
        () => dbService.updateGoal(id: goal.id, targetAmount: -1000.0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final goals = await dbService.getAllGoals();
      final updatedGoal = goals.firstWhere((g) => g.id == goal.id);
      expect(updatedGoal.targetAmount, 5000.0);
    });

    test('Cannot update goal target amount to zero', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));
      final goal = await dbService.createGoal(
        accountId: account.id,
        targetAmount: Money.rub(5000.0),
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      expect(
        () => dbService.updateGoal(id: goal.id, targetAmount: 0.0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final goals = await dbService.getAllGoals();
      final updatedGoal = goals.firstWhere((g) => g.id == goal.id);
      expect(updatedGoal.targetAmount, 5000.0);
    });

    test('Can update goal target amount to positive value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Savings', Money.rub(1000.0));
      final goal = await dbService.createGoal(
        accountId: account.id,
        targetAmount: Money.rub(5000.0),
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      await dbService.updateGoal(id: goal.id, targetAmount: 10000.0);

      final goals = await dbService.getAllGoals();
      final updatedGoal = goals.firstWhere((g) => g.id == goal.id);
      expect(updatedGoal.targetAmount, 10000.0);
    });
  });

  group('Transaction Creation Validation', () {
    test('Cannot create transaction with negative amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      expect(
        () => dbService.createTransaction(
          title: 'Invalid Transaction',
          amount: -50.0,
          categoryId: category.id,
          fromAccountId: account.id,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 1000.0);
    });

    test('Cannot create transaction with zero amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      expect(
        () => dbService.createTransaction(
          title: 'Invalid Transaction',
          amount: Money.rub(0.0),
          categoryId: category.id,
          fromAccountId: account.id,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 1000.0);
    });

    test('Can create transaction with positive amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      final transaction = await dbService.createTransaction(
        title: 'Valid Transaction',
        amount: Money.rub(50.0),
        categoryId: category.id,
        fromAccountId: account.id,
      );

      expect(transaction.amount, 50.0);

      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 1);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 950.0);
    });
  });

  group('Transaction Update Validation', () {
    test('Cannot update transaction amount to negative value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: Money.rub(50.0),
        categoryId: category.id,
        fromAccountId: account.id,
      );

      expect(
        () => dbService.updateTransaction(id: transaction.id, amount: -100.0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final updatedTransaction = await dbService.getTransaction(transaction.id);
      expect(updatedTransaction.amount, 50.0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 950.0);
    });

    test('Cannot update transaction amount to zero', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: Money.rub(50.0),
        categoryId: category.id,
        fromAccountId: account.id,
      );

      expect(
        () => dbService.updateTransaction(id: transaction.id, amount: 0.0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('больше нуля'),
          ),
        ),
      );

      final updatedTransaction = await dbService.getTransaction(transaction.id);
      expect(updatedTransaction.amount, 50.0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 950.0);
    });

    test('Can update transaction amount to positive value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(1000.0));

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: Money.rub(50.0),
        categoryId: category.id,
        fromAccountId: account.id,
      );

      await dbService.updateTransaction(id: transaction.id, amount: 100.0);

      final updatedTransaction = await dbService.getTransaction(transaction.id);
      expect(updatedTransaction.amount, 100.0);

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 900.0);
    });
  });

  group('Balance History Validation - Verification', () {
    test('Transaction still rejected if it would cause negative balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', Money.rub(100.0));

      expect(
        () => dbService.createTransaction(
          title: 'Expensive Item',
          amount: Money.rub(150.0),
          categoryId: category.id,
          fromAccountId: account.id,
        ),
        throwsA(isA<Exception>()),
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance.amount, 100.0);
    });

    test(
      'Transaction still rejected if it would cause historical negative balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Food');
        final account = await dbService.createAccount('Checking', Money.rub(1000.0));

        final now = DateTime.now();

        await dbService.createTransaction(
          title: 'Current Expense',
          amount: Money.rub(900.0),
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now,
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance.amount, 100.0);

        expect(
          () => dbService.createTransaction(
            title: 'Past Expense',
            amount: Money.rub(950.0),
            categoryId: category.id,
            fromAccountId: account.id,
            doneAt: now.subtract(const Duration(days: 1)),
          ),
          throwsA(isA<Exception>()),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance.amount, 100.0);

        final transactions = await dbService.getAllTransactions();
        expect(transactions.length, 1);
      },
    );

    test(
      'Can still add historical transaction if balance stays non-negative',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Food');
        final account = await dbService.createAccount('Checking', Money.rub(1000.0));

        final now = DateTime.now();

        await dbService.createTransaction(
          title: 'Current Expense',
          amount: Money.rub(100.0),
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now,
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance.amount, 900.0);

        await dbService.createTransaction(
          title: 'Past Expense',
          amount: Money.rub(50.0),
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 1)),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance.amount, 850.0);

        final transactions = await dbService.getAllTransactions();
        expect(transactions.length, 2);
      },
    );
  });
}
