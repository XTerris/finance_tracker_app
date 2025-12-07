import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker_app/models/money.dart';

void main() {
  group('Money', () {
    test('создание Money с рублями через конструктор rub', () {
      final money = Money.rub(100.50);
      
      expect(money.amount, 100.50);
      expect(money.currency, 'RUB');
    });

    test('создание Money через обычный конструктор', () {
      final money = Money(amount: 200.0, currency: 'USD');
      
      expect(money.amount, 200.0);
      expect(money.currency, 'USD');
    });

    test('конвертация Money в значение для базы данных', () {
      final money = Money.rub(150.75);
      
      expect(money.toDatabaseValue(), 150.75);
    });

    test('создание Money из значения базы данных', () {
      final money = Money.fromDatabase(300.25);
      
      expect(money.amount, 300.25);
      expect(money.currency, 'RUB');
    });

    test('сериализация Money в JSON', () {
      final money = Money.rub(500.0);
      final json = money.toJson();
      
      expect(json['amount'], 500.0);
      expect(json['currency'], 'RUB');
    });

    test('десериализация Money из JSON', () {
      final json = {'amount': 750.5, 'currency': 'RUB'};
      final money = Money.fromJson(json);
      
      expect(money.amount, 750.5);
      expect(money.currency, 'RUB');
    });

    test('сравнение двух Money объектов', () {
      final money1 = Money.rub(100.0);
      final money2 = Money.rub(100.0);
      final money3 = Money.rub(200.0);
      
      expect(money1, equals(money2));
      expect(money1, isNot(equals(money3)));
    });

    test('toString возвращает строку с суммой и валютой', () {
      final money = Money.rub(1000.0);
      
      expect(money.toString(), '1000.0 RUB');
    });
  });
}
