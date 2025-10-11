import 'package:finance_tracker_app/services/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../service_locator.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  Future<void> init() async {
    // Initialize with data from cache
    _transactions = await serviceLocator.hiveService.getAllTransactions();
    notifyListeners();
    update();
  }

  Future<void> update() async {
    try {
      final lastUpdate =
          await serviceLocator.hiveService.getUpdateTransactionsTimestamp();
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (lastUpdate == null) {
        _transactions = await serviceLocator.apiService.getAllTransactions();
        await serviceLocator.hiveService.saveTransactions(_transactions);
        await serviceLocator.hiveService.setUpdateTransactionsTimestamp(
          timestamp,
        );
        notifyListeners();
      } else {
        final transactionIds = await serviceLocator.apiService
            .getUpdatedTransactionIds(lastUpdate);
        final updatedTransactions = <Transaction>[];
        for (final id in transactionIds) {
          try {
            final transaction = await serviceLocator.apiService.getTransaction(
              id,
            );
            updatedTransactions.add(transaction);
          } on NotFoundException {
            // If transaction not found, it means it was deleted
            serviceLocator.hiveService.deleteTransaction(id);
          }
        }
        await serviceLocator.hiveService.saveTransactions(updatedTransactions);
        await serviceLocator.hiveService.setUpdateTransactionsTimestamp(
          timestamp,
        );
        _transactions = await serviceLocator.hiveService.getAllTransactions();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required int categoryId,
    required int accountId,
    DateTime? doneAt,
  }) async {
    final transaction = await serviceLocator.apiService.createTransaction(
      title: title,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      doneAt: doneAt,
    );

    _transactions.add(transaction);
    await serviceLocator.hiveService.saveTransactions([transaction]);
    notifyListeners();
  }

  void removeTransaction(int id) async {
    await serviceLocator.apiService.deleteTransaction(id);
    _transactions.removeWhere((transaction) => transaction.id == id);
    await serviceLocator.hiveService.deleteTransaction(id);
    notifyListeners();
  }
}
