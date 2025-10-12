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
    
    // Try to update from server, but don't fail if offline
    try {
      await update();
    } catch (e) {
      debugPrint('Could not update transactions from server: $e');
    }
  }

  Future<void> update() async {
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
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required int categoryId,
    int? fromAccountId,
    int? toAccountId,
    DateTime? doneAt,
  }) async {
    try {
      final transaction = await serviceLocator.apiService.createTransaction(
        title: title,
        amount: amount,
        categoryId: categoryId,
        doneAt: doneAt,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
      );

      _transactions.add(transaction);
      await serviceLocator.hiveService.saveTransactions([transaction]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      throw Exception(
        'Не удалось создать транзакцию. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> removeTransaction(int id) async {
    try {
      await serviceLocator.apiService.deleteTransaction(id);
      _transactions.removeWhere((transaction) => transaction.id == id);
      await serviceLocator.hiveService.deleteTransaction(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing transaction: $e');
      throw Exception(
        'Не удалось удалить транзакцию. Проверьте подключение к интернету.',
      );
    }
  }
}
