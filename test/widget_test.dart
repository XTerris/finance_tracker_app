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

  test('Database service initializes correctly', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    final categories = await dbService.getAllCategories();
    expect(categories, isA<List>());
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

    final account = await dbService.createAccount('Test Account', Money.rub(100.0));
    expect(account.name, 'Test Account');
    expect(account.balance.amount, 100.0);

    final accounts = await dbService.getAllAccounts();
    expect(accounts, isNotEmpty);

    await dbService.deleteAccount(account.id);
  });

  test('Can create and retrieve transactions', () async {
    await DatabaseService.init();
    final dbService = DatabaseService();

    final category = await dbService.createCategory('Test Category');

    final transaction = await dbService.createTransaction(
      title: 'Test Transaction',
      amount: Money.rub(50.0),
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
