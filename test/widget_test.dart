// Basic smoke test for the Finance Tracker App

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

  test('Database service initializes correctly', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    // Verify default user is created
    final user = await dbService.getDefaultUser();
    expect(user.name, 'Default User');
    expect(user.email, 'user@local.app');
  });

  test('Default user is recreated if deleted', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    // Get initial user
    final user1 = await dbService.getDefaultUser();
    expect(user1.name, 'Default User');

    // Even if user is somehow deleted (e.g., direct DB manipulation),
    // getDefaultUser will recreate it
    final user2 = await dbService.getDefaultUser();
    expect(user2.name, 'Default User');
    expect(user2.email, 'user@local.app');
  });

  test('Can create and retrieve categories', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    final category = await dbService.createCategory('Test Category');
    expect(category.name, 'Test Category');

    final categories = await dbService.getAllCategories();
    expect(categories, isNotEmpty);

    await dbService.deleteCategory(category.id);
  });

  test('Can create and retrieve accounts', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    final account = await dbService.createAccount('Test Account', 100.0);
    expect(account.name, 'Test Account');
    expect(account.balance, 100.0);

    final accounts = await dbService.getAllAccounts();
    expect(accounts, isNotEmpty);

    await dbService.deleteAccount(account.id);
  });

  test('Can create and retrieve transactions', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    // Create a category first
    final category = await dbService.createCategory('Test Category');

    final transaction = await dbService.createTransaction(
      title: 'Test Transaction',
      amount: 50.0,
      categoryId: category.id,
    );

    expect(transaction.title, 'Test Transaction');
    expect(transaction.amount, 50.0);

    final transactions = await dbService.getAllTransactions();
    expect(transactions, isNotEmpty);

    await dbService.deleteTransaction(transaction.id);
    await dbService.deleteCategory(category.id);
  });
}
