import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';

class HiveService {
  static const String _kvBoxName = 'key_value_store';
  static const String _userBoxName = 'user';
  static const String _transactionBoxName = 'transactions';
  static const String _categoryBoxName = 'categories';
  static const String _accountBoxName = 'accounts';

  static const String _currentUserKey = "currentUser";
  static const String _transactionsUpdateKey = "transactionsUpdate";

  static late Box<User> _userBox;
  static late Box<dynamic> _kvBox;
  static late Box<Transaction> _transactionBox;
  static late Box<Category> _categoryBox;
  static late Box<Account> _accountBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountAdapter());
    }

    // Open boxes with types
    _userBox = await _openBoxSafely<User>(_userBoxName);
    _kvBox = await _openBoxSafely<dynamic>(_kvBoxName);
    _transactionBox = await _openBoxSafely<Transaction>(_transactionBoxName);
    _categoryBox = await _openBoxSafely<Category>(_categoryBoxName);
    _accountBox = await _openBoxSafely<Account>(_accountBoxName);
  }

  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      if (e is HiveError && e.message.contains('unknown typeId')) {
        // Delete the corrupted box and try again
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName);
      } else {
        rethrow;
      }
    }
  }

  Future<User?> getCurrentUser() async {
    final user = _userBox.get(_currentUserKey);
    return user;
  }

  Future<void> saveCurrentUser(User user) async {
    await _userBox.put(_currentUserKey, user);
  }

  Future<void> clearCurrentUser() async {
    // Clear all data in all boxes
    await _userBox.clear();
    await _kvBox.clear();
    await _transactionBox.clear();
  }

  Future<void> setUpdateTransactionsTimestamp(int timestamp) async {
    await _kvBox.put(_transactionsUpdateKey, timestamp);
  }

  Future<int?> getUpdateTransactionsTimestamp() async {
    final timestamp = _kvBox.get(_transactionsUpdateKey) as int?;
    return timestamp;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    for (var transaction in transactions) {
      final key = transaction.id;
      await _transactionBox.put(key, transaction);
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    final transactions = _transactionBox.values.toList();
    return transactions;
  }

  Future<void> deleteTransaction(int id) async {
    await _transactionBox.delete(id);
  }

  Future<void> clearAllTransactions() async {
    await _transactionBox.clear();
  }

  Future<void> saveCategories(List<Category> categories) async {
    for (var category in categories) {
      final key = category.id;
      await _categoryBox.put(key, category);
    }
  }

  Future<List<Category>> getAllCategories() async {
    final categories = _categoryBox.values.toList();
    return categories;
  }

  Future<void> clearAllCategories() async {
    await _categoryBox.clear();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryBox.delete(id);
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    for (var account in accounts) {
      final key = account.id;
      await _accountBox.put(key, account);
    }
  }

  Future<List<Account>> getAllAccounts() async {
    final accounts = _accountBox.values.toList();
    return accounts;
  }

  Future<void> clearAllAccounts() async {
    await _accountBox.clear();
  }

  Future<void> deleteAccount(int id) async {
    await _accountBox.delete(id);
  }

  Future<void> dispose() async {
    await _userBox.close();
    await _kvBox.close();
    await _transactionBox.close();
    await _categoryBox.close();
    await _accountBox.close();
  }
}
