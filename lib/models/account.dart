import 'money.dart';

// Модель счета (банковский счет, кошелек и т.д.)
class Account {
  final int id;
  final String name;
  Money balance; // Текущий баланс счета

  Account({required this.id, required this.name, required this.balance});

  // Создание объекта из JSON (из базы данных)
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      balance: Money.fromDatabase(json['balance'].toDouble()),
    );
  }

  // Преобразование объекта в JSON (для сохранения в БД)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'balance': balance.toDatabaseValue()};
  }
}
