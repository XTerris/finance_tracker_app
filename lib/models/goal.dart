import 'money.dart';

// Модель финансовой цели (накопление определенной суммы на счете)
class Goal {
  final int id;
  final int accountId; // Счет, к которому привязана цель
  final Money targetAmount; // Целевая сумма для достижения
  final DateTime deadline; // Срок достижения цели
  bool isCompleted; // Флаг завершенности цели

  Goal({
    required this.id,
    required this.accountId,
    required this.targetAmount,
    required this.deadline,
    required this.isCompleted,
  });

  // Создание объекта из JSON (из базы данных)
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      accountId: json['account_id'],
      targetAmount: Money.fromDatabase(json['target_amount'].toDouble()),
      deadline: DateTime.parse(json['deadline']),
      isCompleted: json['is_completed'],
    );
  }

  // Преобразование объекта в JSON (для сохранения в БД)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'target_amount': targetAmount.toDatabaseValue(),
      'deadline': deadline.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
    };
  }
}
