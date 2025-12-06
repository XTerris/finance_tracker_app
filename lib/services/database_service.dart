import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../models/account.dart';
import '../models/goal.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'finance_tracker.db';
  static const int _databaseVersion = 1;

  static const String _categoryTable = 'categories';
  static const String _accountTable = 'accounts';
  static const String _transactionTable = 'transactions';
  static const String _goalTable = 'goals';

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  static Future<void> init() async {
    if (_database != null) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_categoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_accountTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_transactionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        done_at TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        from_account_id INTEGER,
        to_account_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES $_categoryTable (id),
        FOREIGN KEY (from_account_id) REFERENCES $_accountTable (id),
        FOREIGN KEY (to_account_id) REFERENCES $_accountTable (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_goalTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        target_amount REAL NOT NULL,
        deadline TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES $_accountTable (id)
      )
    ''');
  }

  Database get _db {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  Future<List<Category>> getAllCategories() async {
    final List<Map<String, dynamic>> maps = await _db.query(_categoryTable);
    return List.generate(maps.length, (i) {
      return Category(id: maps[i]['id'], name: maps[i]['name']);
    });
  }

  Future<Category> createCategory(String name) async {
    final id = await _db.insert(_categoryTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return Category(id: id, name: name);
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete(_categoryTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Account>> getAllAccounts() async {
    final List<Map<String, dynamic>> maps = await _db.query(_accountTable);
    return List.generate(maps.length, (i) {
      return Account(
        id: maps[i]['id'],
        name: maps[i]['name'],
        balance: maps[i]['balance'],
      );
    });
  }

  Future<Account> createAccount(String name, double initialBalance) async {
    final id = await _db.insert(_accountTable, {
      'name': name,
      'balance': initialBalance,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return Account(id: id, name: name, balance: initialBalance);
  }

  Future<Account> updateAccount({
    required int id,
    String? name,
    double? balance,
  }) async {
    final current = await _db.query(
      _accountTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (current.isEmpty) {
      throw Exception('Account not found');
    }

    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (balance != null) updates['balance'] = balance;

    await _db.update(_accountTable, updates, where: 'id = ?', whereArgs: [id]);

    final updated = await _db.query(
      _accountTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    return Account(
      id: updated[0]['id'] as int,
      name: updated[0]['name'] as String,
      balance: updated[0]['balance'] as double,
    );
  }

  Future<void> deleteAccount(int id) async {
    final transactions = await _db.query(
      _transactionTable,
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [id, id],
      limit: 1,
    );

    if (transactions.isNotEmpty) {
      final accountName = await _getAccountName(_db, id);
      throw Exception(
        'Невозможно удалить счёт "$accountName", так как к нему привязаны операции. Удалите сначала все операции этого счёта.',
      );
    }

    await _db.delete(_accountTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    final List<Map<String, dynamic>> maps = await _db.query(_transactionTable);
    return List.generate(maps.length, (i) {
      return models.Transaction(
        id: maps[i]['id'],
        title: maps[i]['title'],
        amount: maps[i]['amount'],
        doneAt: DateTime.parse(maps[i]['done_at']),
        categoryId: maps[i]['category_id'],
        fromAccountId: maps[i]['from_account_id'],
        toAccountId: maps[i]['to_account_id'],
      );
    });
  }

  Future<models.Transaction> getTransaction(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _transactionTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      throw Exception('Transaction not found');
    }

    return models.Transaction(
      id: maps[0]['id'],
      title: maps[0]['title'],
      amount: maps[0]['amount'],
      doneAt: DateTime.parse(maps[0]['done_at']),
      categoryId: maps[0]['category_id'],
      fromAccountId: maps[0]['from_account_id'],
      toAccountId: maps[0]['to_account_id'],
    );
  }

  Future<models.Transaction> createTransaction({
    required String title,
    required double amount,
    required int categoryId,
    DateTime? doneAt,
    int? fromAccountId,
    int? toAccountId,
  }) async {
    return await _db.transaction((txn) async {
      final id = await txn.insert(_transactionTable, {
        'title': title,
        'amount': amount,
        'done_at': (doneAt ?? DateTime.now()).toIso8601String(),
        'category_id': categoryId,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (fromAccountId != null) {
        await _updateAccountBalance(txn, fromAccountId, -amount);
      }
      if (toAccountId != null) {
        await _updateAccountBalance(txn, toAccountId, amount);
      }

      final accountsToValidate = <int>{};
      if (fromAccountId != null) accountsToValidate.add(fromAccountId);
      if (toAccountId != null) accountsToValidate.add(toAccountId);

      for (final accountId in accountsToValidate) {
        final isValid = await _validateAccountBalanceHistory(txn, accountId);
        if (!isValid) {
          final accountName = await _getAccountName(txn, accountId);
          throw Exception(
            'Transaction would cause account "$accountName" balance to become negative at some point in history. Transaction rejected.',
          );
        }
      }

      final result = await txn.query(
        _transactionTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return models.Transaction(
        id: result[0]['id'] as int,
        title: result[0]['title'] as String,
        amount: result[0]['amount'] as double,
        doneAt: DateTime.parse(result[0]['done_at'] as String),
        categoryId: result[0]['category_id'] as int,
        fromAccountId: result[0]['from_account_id'] as int?,
        toAccountId: result[0]['to_account_id'] as int?,
      );
    });
  }

  Future<models.Transaction> updateTransaction({
    required int id,
    String? title,
    int? categoryId,
    double? amount,
  }) async {
    return await _db.transaction((txn) async {
      final currentTxnQuery = await txn.query(
        _transactionTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (currentTxnQuery.isEmpty) {
        throw Exception('Transaction not found');
      }

      final currentTxn = currentTxnQuery[0];
      final oldAmount = currentTxn['amount'] as double;
      final fromAccountId = currentTxn['from_account_id'] as int?;
      final toAccountId = currentTxn['to_account_id'] as int?;

      if (amount != null && amount != oldAmount) {
        if (fromAccountId != null) {
          await _updateAccountBalance(txn, fromAccountId, oldAmount);
        }
        if (toAccountId != null) {
          await _updateAccountBalance(txn, toAccountId, -oldAmount);
        }

        if (fromAccountId != null) {
          await _updateAccountBalance(txn, fromAccountId, -amount);
        }
        if (toAccountId != null) {
          await _updateAccountBalance(txn, toAccountId, amount);
        }

        final accountsToValidate = <int>{};
        if (fromAccountId != null) accountsToValidate.add(fromAccountId);
        if (toAccountId != null) accountsToValidate.add(toAccountId);

        for (final accountId in accountsToValidate) {
          final isValid = await _validateAccountBalanceHistory(txn, accountId);
          if (!isValid) {
            final accountName = await _getAccountName(txn, accountId);
            throw Exception(
              'Изменение суммы операции приведёт к отрицательному балансу счёта "$accountName" в какой-то момент времени. Изменение отклонено.',
            );
          }
        }
      }

      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (amount != null) updates['amount'] = amount;

      await txn.update(
        _transactionTable,
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      final result = await txn.query(
        _transactionTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return models.Transaction(
        id: result[0]['id'] as int,
        title: result[0]['title'] as String,
        amount: result[0]['amount'] as double,
        doneAt: DateTime.parse(result[0]['done_at'] as String),
        categoryId: result[0]['category_id'] as int,
        fromAccountId: result[0]['from_account_id'] as int?,
        toAccountId: result[0]['to_account_id'] as int?,
      );
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _db.transaction((txn) async {
      final txnQuery = await txn.query(
        _transactionTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (txnQuery.isEmpty) {
        throw Exception('Transaction not found');
      }

      final transaction = txnQuery[0];
      final amount = transaction['amount'] as double;
      final fromAccountId = transaction['from_account_id'] as int?;
      final toAccountId = transaction['to_account_id'] as int?;

      await txn.delete(_transactionTable, where: 'id = ?', whereArgs: [id]);

      if (fromAccountId != null) {
        await _updateAccountBalance(txn, fromAccountId, amount);
      }
      if (toAccountId != null) {
        await _updateAccountBalance(txn, toAccountId, -amount);
      }

      final accountsToValidate = <int>{};
      if (fromAccountId != null) accountsToValidate.add(fromAccountId);
      if (toAccountId != null) accountsToValidate.add(toAccountId);

      for (final accountId in accountsToValidate) {
        final isValid = await _validateAccountBalanceHistory(txn, accountId);
        if (!isValid) {
          final accountName = await _getAccountName(txn, accountId);
          throw Exception(
            'Deleting this transaction would cause account "$accountName" balance to become negative at some point in history. Deletion rejected.',
          );
        }
      }
    });
  }

  Future<void> _updateAccountBalance(
    DatabaseExecutor txn,
    int accountId,
    double amountChange,
  ) async {
    await txn.rawUpdate(
      '''
      UPDATE $_accountTable
      SET balance = balance + ?
      WHERE id = ?
    ''',
      [amountChange, accountId],
    );
  }

  Future<String> _getAccountName(
    DatabaseExecutor executor,
    int accountId,
  ) async {
    final accountQuery = await executor.query(
      _accountTable,
      where: 'id = ?',
      whereArgs: [accountId],
    );
    return accountQuery.isNotEmpty
        ? accountQuery[0]['name'] as String
        : 'Unknown Account';
  }

  Future<bool> _validateAccountBalanceHistory(
    DatabaseExecutor txn,
    int accountId,
  ) async {
    final accountQuery = await txn.query(
      _accountTable,
      where: 'id = ?',
      whereArgs: [accountId],
    );

    if (accountQuery.isEmpty) {
      throw Exception('Account not found');
    }

    final currentBalance = accountQuery[0]['balance'] as double;

    final transactions = await txn.query(
      _transactionTable,
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'done_at ASC',
    );

    double runningBalance = currentBalance;

    for (final txn in transactions.reversed) {
      final amount = txn['amount'] as double;
      final fromAccountId = txn['from_account_id'] as int?;
      final toAccountId = txn['to_account_id'] as int?;

      if (fromAccountId == accountId) {
        runningBalance += amount;
      }
      if (toAccountId == accountId) {
        runningBalance -= amount;
      }
    }

    double balance = runningBalance;

    if (balance < 0) {
      return false;
    }

    for (final txn in transactions) {
      final amount = txn['amount'] as double;
      final fromAccountId = txn['from_account_id'] as int?;
      final toAccountId = txn['to_account_id'] as int?;

      if (fromAccountId == accountId) {
        balance -= amount;
      }
      if (toAccountId == accountId) {
        balance += amount;
      }

      if (balance < 0) {
        return false;
      }
    }

    return true;
  }

  Future<List<Goal>> getAllGoals() async {
    final List<Map<String, dynamic>> maps = await _db.query(_goalTable);
    return List.generate(maps.length, (i) {
      return Goal(
        id: maps[i]['id'],
        accountId: maps[i]['account_id'],
        targetAmount: maps[i]['target_amount'],
        deadline: DateTime.parse(maps[i]['deadline']),
        isCompleted: maps[i]['is_completed'] == 1,
      );
    });
  }

  Future<Goal> createGoal({
    required int accountId,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final id = await _db.insert(_goalTable, {
      'account_id': accountId,
      'target_amount': targetAmount,
      'deadline': deadline.toIso8601String().split('T')[0],
      'is_completed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final result = await _db.query(
      _goalTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    return Goal(
      id: result[0]['id'] as int,
      accountId: result[0]['account_id'] as int,
      targetAmount: result[0]['target_amount'] as double,
      deadline: DateTime.parse(result[0]['deadline'] as String),
      isCompleted: result[0]['is_completed'] == 1,
    );
  }

  Future<Goal> updateGoal({
    required int id,
    int? accountId,
    double? targetAmount,
    DateTime? deadline,
    bool? isCompleted,
  }) async {
    final Map<String, dynamic> updates = {};
    if (accountId != null) updates['account_id'] = accountId;
    if (targetAmount != null) updates['target_amount'] = targetAmount;
    if (deadline != null) {
      updates['deadline'] = deadline.toIso8601String().split('T')[0];
    }
    if (isCompleted != null) updates['is_completed'] = isCompleted ? 1 : 0;

    await _db.update(_goalTable, updates, where: 'id = ?', whereArgs: [id]);

    final result = await _db.query(
      _goalTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    return Goal(
      id: result[0]['id'] as int,
      accountId: result[0]['account_id'] as int,
      targetAmount: result[0]['target_amount'] as double,
      deadline: DateTime.parse(result[0]['deadline'] as String),
      isCompleted: result[0]['is_completed'] == 1,
    );
  }

  Future<void> deleteGoal(int id) async {
    await _db.delete(_goalTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> dispose() async {
    if (_database == null) return;
    await _database!.close();
    _database = null;
  }

  static Future<void> resetForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
