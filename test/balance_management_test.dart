import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/services/database_service.dart';
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

  group('Account Balance Updates', () {
    test('Creating an expense transaction updates account balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      expect(account.balance, 1000.0);

      await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);
    });

    test('Creating an income transaction updates account balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Salary');
      final account = await dbService.createAccount('Checking', 1000.0);

      await dbService.createTransaction(
        title: 'Monthly Salary',
        amount: 3000.0,
        categoryId: category.id,
        toAccountId: account.id,
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 4000.0);
    });

    test('Creating a transfer updates both account balances', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Transfer');
      final account1 = await dbService.createAccount('Checking', 1000.0);
      final account2 = await dbService.createAccount('Savings', 500.0);

      await dbService.createTransaction(
        title: 'Save money',
        amount: 200.0,
        categoryId: category.id,
        fromAccountId: account1.id,
        toAccountId: account2.id,
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount1 = accounts.firstWhere((a) => a.id == account1.id);
      final updatedAccount2 = accounts.firstWhere((a) => a.id == account2.id);

      expect(updatedAccount1.balance, 800.0);
      expect(updatedAccount2.balance, 700.0);
    });

    test('Deleting a transaction reverses balance changes', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);

      await dbService.deleteTransaction(transaction.id);

      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 1000.0);
    });
  });

  group('Balance History Validation', () {
    test('Transaction rejected if it would cause negative balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 100.0);

      expect(
        () => dbService.createTransaction(
          title: 'Expensive Item',
          amount: 150.0,
          categoryId: category.id,
          fromAccountId: account.id,
        ),
        throwsA(isA<Exception>()),
      );

      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 100.0);
    });

    test(
      'Transaction rejected if it would cause historical negative balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Food');
        final account = await dbService.createAccount('Checking', 1000.0);

        final now = DateTime.now();

        await dbService.createTransaction(
          title: 'Current Expense',
          amount: 900.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now,
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 100.0);

        expect(
          () => dbService.createTransaction(
            title: 'Past Expense',
            amount: 950.0,
            categoryId: category.id,
            fromAccountId: account.id,
            doneAt: now.subtract(const Duration(days: 1)),
          ),
          throwsA(isA<Exception>()),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 100.0);

        final transactions = await dbService.getAllTransactions();
        expect(transactions.length, 1);
      },
    );

    test('Can add historical transaction if balance stays positive', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final now = DateTime.now();

      await dbService.createTransaction(
        title: 'Current Expense',
        amount: 100.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      await dbService.createTransaction(
        title: 'Past Expense',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now.subtract(const Duration(days: 1)),
      );

      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 850.0);

      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 2);
    });

    test(
      'Deletion rejected if it would cause historical negative balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Income');
        final account = await dbService.createAccount('Checking', 0.0);

        final now = DateTime.now();

        final incomeTransaction = await dbService.createTransaction(
          title: 'Past Income',
          amount: 100.0,
          categoryId: category.id,
          toAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 2)),
        );

        await dbService.createTransaction(
          title: 'Current Expense',
          amount: 90.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 1)),
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 10.0);

        expect(
          () => dbService.deleteTransaction(incomeTransaction.id),
          throwsA(isA<Exception>()),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 10.0);

        final transactions = await dbService.getAllTransactions();
        expect(transactions.length, 2);
      },
    );

    test(
      'Multiple transactions in complex order maintain valid balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Mixed');
        final account = await dbService.createAccount('Checking', 500.0);

        final now = DateTime.now();

        await dbService.createTransaction(
          title: 'Transaction 3',
          amount: 100.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 1)),
        );

        await dbService.createTransaction(
          title: 'Transaction 1',
          amount: 50.0,
          categoryId: category.id,
          toAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 5)),
        );

        await dbService.createTransaction(
          title: 'Transaction 2',
          amount: 30.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 3)),
        );

        final accounts = await dbService.getAllAccounts();
        final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 420.0);
      },
    );
  });

  group('Account Deletion Prevention', () {
    test('Cannot delete account with linked transactions', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      expect(
        () => dbService.deleteAccount(account.id),
        throwsA(isA<Exception>()),
      );

      final accounts = await dbService.getAllAccounts();
      expect(accounts.any((a) => a.id == account.id), true);
    });

    test('Can delete account without linked transactions', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', 1000.0);

      await dbService.deleteAccount(account.id);

      final accounts = await dbService.getAllAccounts();
      expect(accounts.any((a) => a.id == account.id), false);
    });

    test('Cannot delete account linked as fromAccount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      await dbService.createTransaction(
        title: 'Expense',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      expect(
        () => dbService.deleteAccount(account.id),
        throwsA(isA<Exception>()),
      );
    });

    test('Cannot delete account linked as toAccount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Salary');
      final account = await dbService.createAccount('Checking', 1000.0);

      await dbService.createTransaction(
        title: 'Income',
        amount: 500.0,
        categoryId: category.id,
        toAccountId: account.id,
      );

      expect(
        () => dbService.deleteAccount(account.id),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Transaction Amount Update', () {
    test('Can update transaction amount when balance stays positive', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);

      await dbService.updateTransaction(id: transaction.id, amount: 100.0);

      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      final updatedTransaction = await dbService.getTransaction(transaction.id);
      expect(updatedTransaction.amount, 100.0);
    });

    test(
      'Cannot update transaction amount if it causes negative balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Food');
        final account = await dbService.createAccount('Checking', 100.0);

        final transaction = await dbService.createTransaction(
          title: 'Groceries',
          amount: 50.0,
          categoryId: category.id,
          fromAccountId: account.id,
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 50.0);

        expect(
          () => dbService.updateTransaction(id: transaction.id, amount: 150.0),
          throwsA(isA<Exception>()),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 50.0);

        final unchangedTransaction = await dbService.getTransaction(
          transaction.id,
        );
        expect(unchangedTransaction.amount, 50.0);
      },
    );

    test(
      'Cannot update amount if it causes historical negative balance',
      () async {
        await DatabaseService.init();
        final dbService = DatabaseService();

        final category = await dbService.createCategory('Food');
        final account = await dbService.createAccount('Checking', 1000.0);

        final now = DateTime.now();

        final transaction1 = await dbService.createTransaction(
          title: 'Past Expense',
          amount: 50.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now.subtract(const Duration(days: 2)),
        );

        await dbService.createTransaction(
          title: 'Current Expense',
          amount: 900.0,
          categoryId: category.id,
          fromAccountId: account.id,
          doneAt: now,
        );

        var accounts = await dbService.getAllAccounts();
        var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 50.0);

        expect(
          () => dbService.updateTransaction(id: transaction1.id, amount: 200.0),
          throwsA(isA<Exception>()),
        );

        accounts = await dbService.getAllAccounts();
        updatedAccount = accounts.firstWhere((a) => a.id == account.id);
        expect(updatedAccount.balance, 50.0);
      },
    );

    test('Can update amount to smaller value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 100.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      await dbService.updateTransaction(id: transaction.id, amount: 50.0);

      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);
    });

    test('Can update transaction amount for income', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Salary');
      final account = await dbService.createAccount('Checking', 0.0);

      final transaction = await dbService.createTransaction(
        title: 'Monthly Salary',
        amount: 1000.0,
        categoryId: category.id,
        toAccountId: account.id,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 1000.0);

      await dbService.updateTransaction(id: transaction.id, amount: 1500.0);

      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 1500.0);
    });

    test('Can update transfer amount', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Transfer');
      final account1 = await dbService.createAccount('Checking', 1000.0);
      final account2 = await dbService.createAccount('Savings', 500.0);

      final transaction = await dbService.createTransaction(
        title: 'Save money',
        amount: 200.0,
        categoryId: category.id,
        fromAccountId: account1.id,
        toAccountId: account2.id,
      );

      var accounts = await dbService.getAllAccounts();
      var updatedAccount1 = accounts.firstWhere((a) => a.id == account1.id);
      var updatedAccount2 = accounts.firstWhere((a) => a.id == account2.id);
      expect(updatedAccount1.balance, 800.0);
      expect(updatedAccount2.balance, 700.0);

      await dbService.updateTransaction(id: transaction.id, amount: 300.0);

      accounts = await dbService.getAllAccounts();
      updatedAccount1 = accounts.firstWhere((a) => a.id == account1.id);
      updatedAccount2 = accounts.firstWhere((a) => a.id == account2.id);
      expect(updatedAccount1.balance, 700.0);
      expect(updatedAccount2.balance, 800.0);
    });
  });
}
