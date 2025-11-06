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
    // Initialize with data from database
    final accounts = await serviceLocator.databaseService.getAllAccounts();
    _accounts = {for (var account in accounts) account.id: account};
    notifyListeners();
  }

  Future<void> update() async {
    // Reload data from database
    await init();
  }

  Future<void> addAccount(String accountName, double initialBalance) async {
    final account = await serviceLocator.databaseService.createAccount(
      accountName,
      initialBalance,
    );
    _accounts[account.id] = account;
    notifyListeners();
  }

  Future<void> updateAccount({
    required int id,
    String? name,
    double? balance,
  }) async {
    final updatedAccount = await serviceLocator.databaseService.updateAccount(
      id: id,
      name: name,
      balance: balance,
    );

    _accounts[id] = updatedAccount;
    notifyListeners();
  }

  Future<void> removeAccount(int id) async {
    await serviceLocator.databaseService.deleteAccount(id);
    _accounts.remove(id);
    notifyListeners();
  }
}
