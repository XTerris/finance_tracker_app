import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../service_locator.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.doneAt.compareTo(a.doneAt));
    return sorted;
  }

  Future<void> init() async {
    _transactions = await serviceLocator.databaseService.getAllTransactions();
    notifyListeners();
  }

  Future<void> update() async {
    await init();
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required int categoryId,
    int? fromAccountId,
    int? toAccountId,
    DateTime? doneAt,
  }) async {
    final transaction = await serviceLocator.databaseService.createTransaction(
      title: title,
      amount: amount,
      categoryId: categoryId,
      doneAt: doneAt,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
    );

    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> updateTransaction({
    required int id,
    String? title,
    int? categoryId,
    double? amount,
  }) async {
    final updatedTransaction = await serviceLocator.databaseService
        .updateTransaction(
          id: id,
          title: title,
          categoryId: categoryId,
          amount: amount,
        );

    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  Future<void> removeTransaction(int id) async {
    await serviceLocator.databaseService.deleteTransaction(id);
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }
}
