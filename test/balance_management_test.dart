// Tests for account balance management and transaction history validation

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    // Reset database before each test for isolation
    await DatabaseService.resetForTesting();
  });

  tearDown(() async {
    // Clean up after each test
    await DatabaseService.resetForTesting();
  });

  group('Account Balance Updates', () {
    test('Creating an expense transaction updates account balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      // Create a category and an account
      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      // Initial balance should be 1000
      expect(account.balance, 1000.0);

      // Create an expense transaction
      await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Check that balance was updated
      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);
    });

    test('Creating an income transaction updates account balance', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Salary');
      final account = await dbService.createAccount('Checking', 1000.0);

      // Create an income transaction
      await dbService.createTransaction(
        title: 'Monthly Salary',
        amount: 3000.0,
        categoryId: category.id,
        toAccountId: account.id,
      );

      // Check that balance was updated
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

      // Create a transfer transaction
      await dbService.createTransaction(
        title: 'Save money',
        amount: 200.0,
        categoryId: category.id,
        fromAccountId: account1.id,
        toAccountId: account2.id,
      );

      // Check both balances were updated
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

      // Create a transaction
      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Balance should be 950 after transaction
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);

      // Delete the transaction
      await dbService.deleteTransaction(transaction.id);

      // Balance should be back to 1000
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

      // Try to create a transaction that exceeds balance
      expect(
        () => dbService.createTransaction(
          title: 'Expensive Item',
          amount: 150.0,
          categoryId: category.id,
          fromAccountId: account.id,
        ),
        throwsA(isA<Exception>()),
      );

      // Balance should remain unchanged
      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 100.0);
    });

    test('Transaction rejected if it would cause historical negative balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final now = DateTime.now();

      // Create transaction at current time (expense of 900)
      await dbService.createTransaction(
        title: 'Current Expense',
        amount: 900.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now,
      );

      // Current balance should be 100
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 100.0);

      // Try to create a transaction in the past that would cause negative balance
      // at that historical point (expense of 950 when balance was 1000)
      // This should fail because after this historical transaction, 
      // the balance would be 50, but the later transaction needs 900,
      // which would result in -850
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

      // Balance should remain 100
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 100.0);

      // Verify only one transaction exists
      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 1);
    });

    test('Can add historical transaction if balance stays positive', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final now = DateTime.now();

      // Create transaction at current time (expense of 100)
      await dbService.createTransaction(
        title: 'Current Expense',
        amount: 100.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now,
      );

      // Current balance should be 900
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      // Add a historical transaction that doesn't cause negative balance
      await dbService.createTransaction(
        title: 'Past Expense',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now.subtract(const Duration(days: 1)),
      );

      // Balance should now be 850 (1000 - 50 - 100)
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 850.0);

      // Verify two transactions exist
      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 2);
    });

    test('Deletion rejected if it would cause historical negative balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Income');
      final account = await dbService.createAccount('Checking', 0.0);

      final now = DateTime.now();

      // Create an income transaction in the past
      final incomeTransaction = await dbService.createTransaction(
        title: 'Past Income',
        amount: 100.0,
        categoryId: category.id,
        toAccountId: account.id,
        doneAt: now.subtract(const Duration(days: 2)),
      );

      // Create an expense transaction that depends on the income
      await dbService.createTransaction(
        title: 'Current Expense',
        amount: 90.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now.subtract(const Duration(days: 1)),
      );

      // Balance should be 10
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 10.0);

      // Try to delete the income transaction - this should fail
      // because it would make the balance -90 at the time of the expense
      expect(
        () => dbService.deleteTransaction(incomeTransaction.id),
        throwsA(isA<Exception>()),
      );

      // Balance should remain 10
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 10.0);

      // Verify both transactions still exist
      final transactions = await dbService.getAllTransactions();
      expect(transactions.length, 2);
    });

    test('Multiple transactions in complex order maintain valid balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Mixed');
      final account = await dbService.createAccount('Checking', 500.0);

      final now = DateTime.now();

      // Create transactions in non-chronological order
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

      // Final balance should be: 500 + 50 - 30 - 100 = 420
      final accounts = await dbService.getAllAccounts();
      final updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 420.0);
    });
  });

  group('Account Deletion Prevention', () {
    test('Cannot delete account with linked transactions', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      // Create a transaction linked to the account
      await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Try to delete the account - should fail
      expect(
        () => dbService.deleteAccount(account.id),
        throwsA(isA<Exception>()),
      );

      // Verify account still exists
      final accounts = await dbService.getAllAccounts();
      expect(accounts.any((a) => a.id == account.id), true);
    });

    test('Can delete account without linked transactions', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final account = await dbService.createAccount('Checking', 1000.0);

      // Delete the account - should succeed
      await dbService.deleteAccount(account.id);

      // Verify account is deleted
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

      // Create a transaction with 50
      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Balance should be 950
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);

      // Update amount to 100
      await dbService.updateTransaction(
        id: transaction.id,
        amount: 100.0,
      );

      // Balance should now be 900
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      // Verify transaction amount was updated
      final updatedTransaction = await dbService.getTransaction(transaction.id);
      expect(updatedTransaction.amount, 100.0);
    });

    test('Cannot update transaction amount if it causes negative balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 100.0);

      // Create a transaction with 50
      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Balance should be 50
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 50.0);

      // Try to update amount to 150 - should fail
      expect(
        () => dbService.updateTransaction(
          id: transaction.id,
          amount: 150.0,
        ),
        throwsA(isA<Exception>()),
      );

      // Balance should remain 50
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 50.0);

      // Verify transaction amount unchanged
      final unchangedTransaction = await dbService.getTransaction(transaction.id);
      expect(unchangedTransaction.amount, 50.0);
    });

    test('Cannot update amount if it causes historical negative balance',
        () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      final now = DateTime.now();

      // Create first transaction at past (expense of 50)
      final transaction1 = await dbService.createTransaction(
        title: 'Past Expense',
        amount: 50.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now.subtract(const Duration(days: 2)),
      );

      // Create second transaction at present (expense of 900)
      await dbService.createTransaction(
        title: 'Current Expense',
        amount: 900.0,
        categoryId: category.id,
        fromAccountId: account.id,
        doneAt: now,
      );

      // Balance should be 50
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 50.0);

      // Try to update past transaction amount to 200
      // This would make balance after past transaction 800,
      // but then the current transaction would make it -100
      expect(
        () => dbService.updateTransaction(
          id: transaction1.id,
          amount: 200.0,
        ),
        throwsA(isA<Exception>()),
      );

      // Balance should remain 50
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 50.0);
    });

    test('Can update amount to smaller value', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Food');
      final account = await dbService.createAccount('Checking', 1000.0);

      // Create a transaction with 100
      final transaction = await dbService.createTransaction(
        title: 'Groceries',
        amount: 100.0,
        categoryId: category.id,
        fromAccountId: account.id,
      );

      // Balance should be 900
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 900.0);

      // Update amount to 50 (smaller)
      await dbService.updateTransaction(
        id: transaction.id,
        amount: 50.0,
      );

      // Balance should now be 950
      accounts = await dbService.getAllAccounts();
      updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 950.0);
    });

    test('Can update transaction amount for income', () async {
      await DatabaseService.init();
      final dbService = DatabaseService();

      final category = await dbService.createCategory('Salary');
      final account = await dbService.createAccount('Checking', 0.0);

      // Create an income transaction with 1000
      final transaction = await dbService.createTransaction(
        title: 'Monthly Salary',
        amount: 1000.0,
        categoryId: category.id,
        toAccountId: account.id,
      );

      // Balance should be 1000
      var accounts = await dbService.getAllAccounts();
      var updatedAccount = accounts.firstWhere((a) => a.id == account.id);
      expect(updatedAccount.balance, 1000.0);

      // Update amount to 1500
      await dbService.updateTransaction(
        id: transaction.id,
        amount: 1500.0,
      );

      // Balance should now be 1500
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

      // Create a transfer with 200
      final transaction = await dbService.createTransaction(
        title: 'Save money',
        amount: 200.0,
        categoryId: category.id,
        fromAccountId: account1.id,
        toAccountId: account2.id,
      );

      // Balances should be 800 and 700
      var accounts = await dbService.getAllAccounts();
      var updatedAccount1 = accounts.firstWhere((a) => a.id == account1.id);
      var updatedAccount2 = accounts.firstWhere((a) => a.id == account2.id);
      expect(updatedAccount1.balance, 800.0);
      expect(updatedAccount2.balance, 700.0);

      // Update amount to 300
      await dbService.updateTransaction(
        id: transaction.id,
        amount: 300.0,
      );

      // Balances should now be 700 and 800
      accounts = await dbService.getAllAccounts();
      updatedAccount1 = accounts.firstWhere((a) => a.id == account1.id);
      updatedAccount2 = accounts.firstWhere((a) => a.id == account2.id);
      expect(updatedAccount1.balance, 700.0);
      expect(updatedAccount2.balance, 800.0);
    });
  });
}
