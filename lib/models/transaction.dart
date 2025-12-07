import 'money.dart';

// Модель финансовой транзакции (расход, доход или перевод)
class Transaction {
  final int id;
  final String title; // Описание транзакции
  final Money amount; // Сумма транзакции
  final DateTime doneAt; // Дата и время совершения
  final int categoryId; // Категория транзакции
  final int? fromAccountId; // Счет списания (для расходов и переводов)
  final int? toAccountId; // Счет зачисления (для доходов и переводов)

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.doneAt,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
  });

  // Создание объекта из JSON (из базы данных)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: Money.fromDatabase(json['amount']),
      doneAt: DateTime.parse(json['done_at']),
      categoryId: json['category_id'],
      fromAccountId: json['from_account_id'],
      toAccountId: json['to_account_id'],
    );
  }

  // Преобразование объекта в JSON (для сохранения в БД)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount.toDatabaseValue(),
      'done_at': doneAt.toIso8601String(),
      'category_id': categoryId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
    };
  }
}
