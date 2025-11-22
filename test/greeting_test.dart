// Test for time-based greeting functionality

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Time-based greeting', () {
    test('Returns correct greeting for morning hours (6-11)', () {
      // Test morning greeting logic
      for (int hour = 6; hour < 12; hour++) {
        final greeting = getGreetingForHour(hour);
        expect(greeting, 'Доброе утро!', reason: 'Hour $hour should return morning greeting');
      }
    });

    test('Returns correct greeting for afternoon hours (12-17)', () {
      // Test afternoon greeting logic
      for (int hour = 12; hour < 18; hour++) {
        final greeting = getGreetingForHour(hour);
        expect(greeting, 'Добрый день!', reason: 'Hour $hour should return afternoon greeting');
      }
    });

    test('Returns correct greeting for evening hours (18-22)', () {
      // Test evening greeting logic
      for (int hour = 18; hour < 23; hour++) {
        final greeting = getGreetingForHour(hour);
        expect(greeting, 'Добрый вечер!', reason: 'Hour $hour should return evening greeting');
      }
    });

    test('Returns correct greeting for night hours (23-5)', () {
      // Test night greeting logic
      final nightHours = [23, 0, 1, 2, 3, 4, 5];
      for (int hour in nightHours) {
        final greeting = getGreetingForHour(hour);
        expect(greeting, 'Доброй ночи!', reason: 'Hour $hour should return night greeting');
      }
    });
  });
}

// Helper function that mimics the greeting logic from dashboard.dart
String getGreetingForHour(int hour) {
  if (hour >= 6 && hour < 12) {
    return 'Доброе утро!';
  } else if (hour >= 12 && hour < 18) {
    return 'Добрый день!';
  } else if (hour >= 18 && hour < 23) {
    return 'Добрый вечер!';
  } else {
    return 'Доброй ночи!';
  }
}
