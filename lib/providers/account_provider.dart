import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../service_locator.dart';

class AccountProvider extends ChangeNotifier {
  Map<int, Account> _accounts = {};

  List<Account> get accounts => _accounts.values.toList();

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

  Future<void> removeAccount(int id) async {
    await serviceLocator.apiService.deleteAccount(id);
    _accounts.remove(id);
    await serviceLocator.hiveService.deleteAccount(id);
    notifyListeners();
  }
}
