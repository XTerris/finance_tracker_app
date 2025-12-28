import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/money.dart';
import '../service_locator.dart';

// Провайдер для управления состоянием счетов
class AccountProvider extends ChangeNotifier {
  Map<int, Account> _accounts = {};

  // Получение списка счетов, отсортированных по названию
  List<Account> get accounts {
    final sorted = _accounts.values.toList();
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  // Загрузка всех счетов из базы данных
  Future<void> init() async {
    final accounts = await serviceLocator.databaseService.getAllAccounts();
    _accounts = {for (var account in accounts) account.id: account};
    notifyListeners();
  }

  // Обновление списка счетов из БД
  Future<void> update() async {
    await init();
  }

  // Создание нового счета
  Future<void> addAccount(String accountName, Money initialBalance) async {
    final account = await serviceLocator.databaseService.createAccount(
      accountName,
      initialBalance,
    );
    _accounts[account.id] = account;
    notifyListeners();
  }

  // Обновление существующего счета
  Future<void> updateAccount({
    required int id,
    String? name,
    Money? balance,
  }) async {
    final updatedAccount = await serviceLocator.databaseService.updateAccount(
      id: id,
      name: name,
      balance: balance,
    );

    _accounts[id] = updatedAccount;
    notifyListeners();
  }

  // Удаление счета
  Future<void> removeAccount(int id) async {
    await serviceLocator.databaseService.deleteAccount(id);
    _accounts.remove(id);
    notifyListeners();
  }
}
