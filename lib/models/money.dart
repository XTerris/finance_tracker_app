// Модель денежной суммы с поддержкой валюты
class Money {
  final double amount; // Сумма денег
  final String currency; // Код валюты (например, RUB, USD, EUR)

  const Money({
    required this.amount,
    required this.currency,
  });

  // Создание объекта Money с рублями по умолчанию
  const Money.rub(this.amount) : currency = 'RUB';

  // Создание объекта из JSON
  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: json['amount'].toDouble(),
      currency: json['currency'] as String,
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
    };
  }

  // Создание из значения amount в базе данных (всегда RUB)
  factory Money.fromDatabase(double amount) {
    return Money.rub(amount);
  }

  // Получение значения для сохранения в БД
  double toDatabaseValue() {
    return amount;
  }

  @override
  String toString() {
    return '$amount $currency';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money &&
        other.amount == amount &&
        other.currency == currency;
  }

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;
}
