import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../service_locator.dart';

class AccountProvider extends ChangeNotifier {
  Map<int, Account> _accounts = {};

  List<Account> get accounts {
    // Sort alphabetically by name
    final sorted = _accounts.values.toList();
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  Future<void> init() async {
    // Initialize with data from cache
    final accounts = await serviceLocator.hiveService.getAllAccounts();
    _accounts = {for (var account in accounts) account.id: account};
    notifyListeners();

    // Try to update from server, but don't fail if offline
    try {
      await update();
    } catch (e) {
      debugPrint('Could not update accounts from server: $e');
    }
  }

  Future<void> update() async {
    final accounts = await serviceLocator.apiService.getAllAccounts();
    _accounts = {for (var account in accounts) account.id: account};
    await serviceLocator.hiveService.clearAllAccounts();
    await serviceLocator.hiveService.saveAccounts(accounts);
    notifyListeners();
  }

  Future<void> addAccount(String accountName, double initialBalance) async {
    final account = await serviceLocator.apiService.createAccount(
      accountName,
      initialBalance,
    );
    _accounts[account.id] = account;
    await serviceLocator.hiveService.saveAccounts([account]);

    notifyListeners();
  }

  Future<void> updateAccount({
    required int id,
    String? name,
    double? balance,
  }) async {
    try {
      final updatedAccount = await serviceLocator.apiService.updateAccount(
        id: id,
        name: name,
        balance: balance,
      );

      _accounts[id] = updatedAccount;
      await serviceLocator.hiveService.saveAccounts([updatedAccount]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating account: $e');
      throw Exception(
        'Не удалось обновить счёт. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> removeAccount(int id) async {
    await serviceLocator.apiService.deleteAccount(id);
    _accounts.remove(id);
    await serviceLocator.hiveService.deleteAccount(id);
    notifyListeners();
  }
}
